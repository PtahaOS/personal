#!/usr/bin/env bash
# setup.sh — установка и настройка свежего Arch (Hyprland) под конфиги PtahaOS.
#
#   chmod +x setup.sh && ./setup.sh
#
# Режимы:
#   ./setup.sh              всё: пакеты, репозитории, конфиги, сервисы
#   ./setup.sh packages     только пакеты (paru, pacman, AUR, rust)
#   ./setup.sh dotfiles     только клон реп и раскладка конфигов
#
# Добавить программу потом:
#   допиши имя пакета в PACMAN_EXTRA или AUR_EXTRA ниже и запусти ./setup.sh packages
#
# Повторный запуск безопасен: уже стоящие пакеты пропускаются (--needed).

set -euo pipefail

# ---------------------------------------------------------------------------
# Что включить
# ---------------------------------------------------------------------------
AUTOLOGIN=1          # 1 = после пароля LUKS сразу Hyprland, без второго логина
INSTALL_LIBREOFFICE=1
INSTALL_STEAM=1

# ---------------------------------------------------------------------------
# Куда класть репозитории
# ---------------------------------------------------------------------------
PERSONAL_URL="https://github.com/PtahaOS/personal.git"
NVIM_URL="https://github.com/PtahaOS/nvim-config.git"
PERSONAL_DIR="${HOME}/personal"
NVIM_DIR="${HOME}/.config/nvim"

# ---------------------------------------------------------------------------
# Пакеты из официальных репозиториев.
# Новое — в PACMAN_EXTRA, не размазывай по скрипту.
# ---------------------------------------------------------------------------
PACMAN_BASE=(
    base-devel git curl wget rsync unzip zip
    pacman-contrib man-db man-pages
    fzf
)

PACMAN_DEV=(
    python npm go
    clang gcc make cmake
    neovim lua luarocks
    wl-clipboard ripgrep fd
    tree-sitter tree-sitter-cli
    rustup
)

PACMAN_DESKTOP=(
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland qt5ct qt6ct
    waybar rofi swaync
    network-manager-applet
    hyprpolkitagent
    brightnessctl
    wezterm
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    ttf-iosevka-nerd
    ttf-nerd-fonts-symbols-mono
    nwg-look
    thunar
    pavucontrol
    pipewire pipewire-pulse wireplumber
    bluez bluez-utils blueman
    power-profiles-daemon
    ufw
    archlinux-xdg-menu
    okular
)

PACMAN_EXTRA=(
    # сюда свои пакеты из pacman, по одному на строку:
    # fastfetch
)

# AUR. Новое — в AUR_EXTRA.
AUR_PKGS=(
    awww
    rose-pine-gtk-theme-full
    rose-pine-cursor
    helium-bin
    protonup-qt
)

AUR_EXTRA=(
    # сюда свои AUR-пакеты:
    # wezterm-git
)

# ---------------------------------------------------------------------------
log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m!! \033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31mxx \033[0m %s\n' "$*" >&2; exit 1; }

need_user() {
    [[ "$(id -u)" -eq 0 ]] && die "Запускай от своего пользователя, не от root. sudo спросит пароль сам."
    command -v sudo >/dev/null || die "Нет sudo."
    sudo -v
}

enable_multilib() {
    if grep -q '^\[multilib\]' /etc/pacman.conf; then
        return 0
    fi
    log "Включаю multilib (нужен для Steam и 32-битных библиотек NVIDIA)"
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    grep -q '^\[multilib\]' /etc/pacman.conf || die "Не смог включить [multilib] в /etc/pacman.conf"
}

install_microcode() {
    if grep -q AuthenticAMD /proc/cpuinfo; then
        echo amd-ucode
    elif grep -q GenuineIntel /proc/cpuinfo; then
        echo intel-ucode
    fi
}

install_nvidia() {
    # RTX 50 (Blackwell) работает только с open-модулями.
    # Не ставим второй вариант поверх того, что уже выбрал archinstall.
    if pacman -Q nvidia-open-dkms &>/dev/null \
        || pacman -Q nvidia-open &>/dev/null \
        || pacman -Q nvidia-open-lts &>/dev/null; then
        log "Модуль NVIDIA уже установлен, добираю только userspace"
    elif lspci -d ::03xx 2>/dev/null | grep -qi nvidia; then
        log "Ставлю nvidia-open"
        sudo pacman -S --noconfirm --needed nvidia-open
    else
        warn "NVIDIA не видна в lspci, драйвер не ставлю"
    fi
    sudo pacman -S --noconfirm --needed nvidia-utils lib32-nvidia-utils
}

pacman_install() {
    local pkgs=("$@")
    [[ ${#pkgs[@]} -eq 0 ]] && return 0
    sudo pacman -S --noconfirm --needed "${pkgs[@]}"
}

install_paru() {
    if command -v paru >/dev/null; then
        return 0
    fi
    log "Собираю paru (не от root)"
    local tmp
    tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/paru.git "${tmp}/paru"
    ( cd "${tmp}/paru" && makepkg -si --noconfirm )
    rm -rf "${tmp}"
    command -v paru >/dev/null || die "paru не появился в PATH. Перелогинься или проверь /usr/bin"
}

aur_install() {
    local pkg failed=()
    command -v paru >/dev/null || die "paru не установлен"
    for pkg in "$@"; do
        [[ -z "${pkg}" ]] && continue
        log "AUR: ${pkg}"
        if paru -S --noconfirm --needed --skipreview "${pkg}"; then
            :
        else
            warn "Не поставился: ${pkg}"
            failed+=("${pkg}")
        fi
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        warn "Упали AUR-пакеты: ${failed[*]}"
        warn "Остальное поставлено. Поправь имя пакета и запусти ./setup.sh packages ещё раз."
    fi
}

clone_or_pull() {
    local url="$1" dest="$2"
    if [[ -d "${dest}/.git" ]]; then
        log "Обновляю ${dest}"
        git -C "${dest}" pull --ff-only || warn "git pull не прошёл для ${dest}, оставляю как есть"
    else
        if [[ -e "${dest}" ]]; then
            local bak="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
            warn "${dest} существует и это не git-репозиторий, переименовываю в ${bak}"
            mv "${dest}" "${bak}"
        fi
        mkdir -p "$(dirname "${dest}")"
        log "Клонирую ${url}"
        git clone --depth 1 "${url}" "${dest}"
    fi
}

sync_dir() {
    local src="$1" dest="$2"
    [[ -d "${src}" ]] || { warn "Нет ${src}, пропускаю"; return 0; }
    mkdir -p "${dest}"
    # без --delete: не сносим локальные файлы, которых нет в репе (tpm, кэш)
    rsync -a "${src}/" "${dest}/"
}

deploy_dotfiles() {
    [[ -d "${PERSONAL_DIR}/.config" ]] || die "Нет ${PERSONAL_DIR}/.config. Сначала клон personal."

    log "Раскладываю конфиги"
    sync_dir "${PERSONAL_DIR}/.config/hypr"    "${HOME}/.config/hypr"
    sync_dir "${PERSONAL_DIR}/.config/waybar"  "${HOME}/.config/waybar"
    sync_dir "${PERSONAL_DIR}/.config/rofi"    "${HOME}/.config/rofi"
    sync_dir "${PERSONAL_DIR}/.config/wezterm" "${HOME}/.config/wezterm"
    sync_dir "${PERSONAL_DIR}/.config/swaync"  "${HOME}/.config/swaync"
    mkdir -p "${HOME}/.config/tmux"
    rsync -a "${PERSONAL_DIR}/.config/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
    if [[ -d "${PERSONAL_DIR}/.config/tmux/cheat-sheet" ]]; then
        sync_dir "${PERSONAL_DIR}/.config/tmux/cheat-sheet" "${HOME}/.config/tmux/cheat-sheet"
    fi

    if [[ -f "${PERSONAL_DIR}/.config/zsh/.zshrc" ]]; then
        cp -a "${PERSONAL_DIR}/.config/zsh/.zshrc" "${HOME}/.zshrc"
    fi
    if [[ -f "${PERSONAL_DIR}/.config/zsh/aliases.zsh" ]] && [[ -d "${HOME}/.oh-my-zsh" ]]; then
        mkdir -p "${HOME}/.oh-my-zsh/custom"
        cp -a "${PERSONAL_DIR}/.config/zsh/aliases.zsh" "${HOME}/.oh-my-zsh/custom/aliases.zsh"
    fi

    chmod +x "${HOME}/.config/hypr/scripts/"*.sh "${HOME}/.config/waybar/launch.sh" 2>/dev/null || true

    mkdir -p "${HOME}/.local/share/applications"
    cat > "${HOME}/.local/share/applications/xgps.desktop" << 'EOF'
[Desktop Entry]
Name=xgps
NoDisplay=true
EOF
    cat > "${HOME}/.local/share/applications/xgpsspeed.desktop" << 'EOF'
[Desktop Entry]
Name=xgpsspeed
NoDisplay=true
EOF
    command -v update-desktop-database >/dev/null && update-desktop-database "${HOME}/.local/share/applications" || true
}

setup_zsh() {
    log "zsh + oh-my-zsh + autosuggestions"
    local zsh_bin
    zsh_bin="$(command -v zsh)"
    if [[ "${SHELL}" != "${zsh_bin}" ]]; then
        sudo chsh -s "${zsh_bin}" "${USER}"
        log "Оболочка входа сменена на zsh. Заработает после выхода из сессии."
    fi

    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    local plugin="${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [[ ! -d "${plugin}/.git" ]]; then
        mkdir -p "${HOME}/.oh-my-zsh/custom/plugins"
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "${plugin}"
    fi

    if [[ -f "${PERSONAL_DIR}/.config/zsh/.zshrc" ]]; then
        cp -a "${PERSONAL_DIR}/.config/zsh/.zshrc" "${HOME}/.zshrc"
    fi
    if [[ -f "${PERSONAL_DIR}/.config/zsh/aliases.zsh" ]]; then
        mkdir -p "${HOME}/.oh-my-zsh/custom"
        cp -a "${PERSONAL_DIR}/.config/zsh/aliases.zsh" "${HOME}/.oh-my-zsh/custom/aliases.zsh"
    fi
}

setup_keyd() {
    [[ -f "${PERSONAL_DIR}/.config/keyd/default.conf" ]] || return 0
    log "keyd: capslock = ctrl/esc"
    sudo install -d -m 755 /etc/keyd
    sudo install -m 644 "${PERSONAL_DIR}/.config/keyd/default.conf" /etc/keyd/default.conf
    sudo systemctl enable --now keyd
    sudo keyd reload || true
}

setup_tmux_plugins() {
    local tpm="${HOME}/.config/tmux/plugins/tpm"
    if [[ ! -d "${tpm}/.git" ]]; then
        log "Ставлю tmux plugin manager"
        git clone --depth 1 https://github.com/tmux-plugins/tpm "${tpm}"
    fi
    if [[ -x "${tpm}/bin/install_plugins" ]]; then
        "${tpm}/bin/install_plugins" || warn "Плагины tmux не поставились. В tmux нажми prefix+I"
    fi
}

setup_rust() {
    log "Rust (stable + clippy + rustfmt). rust-analyzer поставит Mason внутри nvim."
    rustup default stable
    rustup component add clippy rustfmt
}

setup_autologin() {
    [[ "${AUTOLOGIN}" == "1" ]] || return 0
    log "Автологин на tty1 и запуск Hyprland"
    sudo install -d /etc/systemd/system/getty@tty1.service.d
    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${USER} --noclear %I \$TERM
EOF

    local marker="# ptaha-autologin"
    local profile="${HOME}/.zprofile"
    if [[ -f "${profile}" ]] && grep -q "${marker}" "${profile}"; then
        :
    else
        cat >> "${profile}" << EOF

${marker}
if [ -z "\${WAYLAND_DISPLAY}" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
EOF
    fi
}

setup_services() {
    log "Сервисы"
    sudo systemctl enable --now bluetooth.service || warn "bluetooth не включился"
    sudo systemctl enable --now power-profiles-daemon.service || true
    sudo systemctl enable --now fstrim.timer || true

    systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service \
        || warn "PipeWire не включился (нужна живая пользовательская сессия)"
    systemctl --user enable --now hyprpolkitagent.service \
        || warn "hyprpolkitagent не включился. После входа в Hyprland: systemctl --user enable --now hyprpolkitagent"

    if command -v ufw >/dev/null && ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw --force enable || true
    fi
}

rebuild_initramfs_if_ucode() {
    if pacman -Q amd-ucode &>/dev/null || pacman -Q intel-ucode &>/dev/null; then
        if [[ -x /usr/bin/mkinitcpio ]]; then
            log "Пересобираю initramfs (микрокод)"
            sudo mkinitcpio -P || warn "mkinitcpio -P не прошёл"
        fi
    fi
}

cmd_packages() {
    need_user
    enable_multilib
    log "Обновляю систему"
    sudo pacman -Syu --noconfirm

    local ucode pkgs=()
    ucode="$(install_microcode || true)"
    pkgs+=("${PACMAN_BASE[@]}" "${PACMAN_DEV[@]}" "${PACMAN_DESKTOP[@]}" "${PACMAN_EXTRA[@]}")
    [[ -n "${ucode}" ]] && pkgs+=("${ucode}")
    if [[ "${INSTALL_LIBREOFFICE}" == "1" ]]; then
        pkgs+=(libreoffice-fresh)
    fi
    if [[ "${INSTALL_STEAM}" == "1" ]]; then
        pkgs+=(steam gamemode lib32-gamemode gamescope mangohud lib32-mangohud)
    fi

    log "Официальные пакеты"
    pacman_install "${pkgs[@]}"
    install_nvidia
    install_paru

    local aur=("${AUR_PKGS[@]}" "${AUR_EXTRA[@]}")
    if [[ ${#aur[@]} -gt 0 ]]; then
        aur_install "${aur[@]}"
    fi
    setup_rust
    rebuild_initramfs_if_ucode
}

cmd_dotfiles() {
    need_user
    clone_or_pull "${PERSONAL_URL}" "${PERSONAL_DIR}"
    clone_or_pull "${NVIM_URL}" "${NVIM_DIR}"
    setup_zsh
    deploy_dotfiles
    setup_keyd
    setup_tmux_plugins
    setup_autologin
    setup_services
}

main() {
    local mode="${1:-all}"
    case "${mode}" in
        packages) cmd_packages ;;
        dotfiles) cmd_dotfiles ;;
        all|"")
            cmd_packages
            cmd_dotfiles
            ;;
        *)
            die "Неизвестный режим: ${mode}. Используй: packages | dotfiles | all"
            ;;
    esac

    cat << EOF

Готово.

Дальше:
  1. Перезагрузись. Пароль LUKS, затем сразу Hyprland (если AUTOLOGIN=1).
  2. sudo по-прежнему спрашивает пароль.
  3. Открой nvim один раз и дождись, пока lazy.nvim скачает плагины,
     потом :Mason чтобы докачались lua_ls, rust_analyzer, clangd.
  4. В tmux нажми Ctrl-b затем I, если тема rose-pine не встала сама.
  5. Файл-менеджер на SUPER+E пустой: в ~/personal/.config/hypr/lua/remap.lua
     поставь local fileManager = "thunar" и запусти ./setup.sh dotfiles
  6. Новые программы: допиши в PACMAN_EXTRA или AUR_EXTRA в этом файле
     и запусти ./setup.sh packages

Не ставил vulkan-intel: у тебя AMD CPU + NVIDIA, этот пакет был в старом init.sh по ошибке.
wezterm берётся из Extra, а не wezterm-git: не надо компилировать Rust-терминал полчаса.
oh-my-zsh больше не меняет оболочку root (старый zsh.sh делал chsh без имени пользователя).
EOF
}

main "$@"
