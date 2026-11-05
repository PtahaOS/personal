#!/usr/bin/env bash
# setup.sh — установка и настройка свежего Arch (Hyprland) под конфиги PtahaOS.
#
#   chmod +x setup.sh && ./setup.sh
#
# Режимы:
#   ./setup.sh              всё: пакеты, репозитории, конфиги, сервисы
#   ./setup.sh packages     только пакеты (paru, pacman, AUR, rust)
#   ./setup.sh dotfiles     только клон реп и раскладка конфигов
#   ./setup.sh wallpaper    поставить wallpaper2.jpg через awww
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
INSTALL_BATTLENET=1  # Lutris + Wine/Proton: WoW и Warcraft III Reforged
INSTALL_GROK=1       # Grok CLI в терминале: ~/.grok/bin + /usr/local/bin

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
    zsh eza atuin keyd
    pciutils
    plymouth
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
    gsettings-desktop-schemas
    qt5-wayland qt6-wayland qt5ct qt6ct
    kvantum
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
    gimp
    imv
)

# AUR. Новое — в AUR_EXTRA.
AUR_PKGS=(
    awww
    rose-pine-gtk-theme-full
    rose-pine-cursor
    helium-browser-bin
    protonup-qt-bin
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
    # nvidia-utils без карты не ставим: пакет тянет драйвер в userspace зря.
    local has=0
    if pacman -Q nvidia-open-dkms &>/dev/null \
        || pacman -Q nvidia-open &>/dev/null \
        || pacman -Q nvidia-open-lts &>/dev/null; then
        has=1
        log "Модуль NVIDIA уже установлен, добираю только userspace"
    elif lspci -d ::03xx 2>/dev/null | grep -qi nvidia; then
        has=1
        log "Ставлю nvidia-open"
        sudo pacman -S --noconfirm --needed nvidia-open
    else
        warn "NVIDIA не видна в lspci, драйвер не ставлю"
    fi
    if [[ "${has}" == "1" ]]; then
        sudo pacman -S --noconfirm --needed nvidia-utils lib32-nvidia-utils libva-nvidia-driver
        setup_nvidia_primary
    fi
}

setup_nvidia_primary() {
    # NVIDIA основная, iGPU не выключается. card0/card1 меняются между загрузками.
    log "Симлинки /dev/dri/nvidia-dgpu и /dev/dri/amd-igpu"
    sudo tee /etc/modprobe.d/nvidia.conf >/dev/null << 'EOF'
options nvidia_drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

    local nvidia_id amd_id body=""
    nvidia_id="$(lspci -nn -d 10de: | awk '/VGA|3D|Display/ { print $1; exit }')"
    amd_id="$(lspci -nn -d 1002: | awk '/VGA|3D|Display/ { print $1; exit }')"
    if [[ -n "${nvidia_id}" ]]; then
        body+="KERNEL==\"card*\", KERNELS==\"0000:${nvidia_id}\", SUBSYSTEM==\"drm\", SUBSYSTEMS==\"pci\", SYMLINK+=\"dri/nvidia-dgpu\"
"
    else
        warn "Не нашёл PCI-адрес NVIDIA, симлинк nvidia-dgpu не создал"
    fi
    if [[ -n "${amd_id}" ]]; then
        body+="KERNEL==\"card*\", KERNELS==\"0000:${amd_id}\", SUBSYSTEM==\"drm\", SUBSYSTEMS==\"pci\", SYMLINK+=\"dri/amd-igpu\"
"
    else
        warn "Не нашёл встроенную AMD. Если её нет, убери :/dev/dri/amd-igpu из environment.lua"
    fi
    printf '%s' "${body}" | sudo tee /etc/udev/rules.d/99-nvidia-dgpu.rules >/dev/null
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=drm || true

    if [[ ! -f /etc/mkinitcpio.conf ]]; then
        return 0
    fi
    local mod
    for mod in amdgpu nvidia nvidia_modeset nvidia_uvm nvidia_drm; do
        if grep -Eq "^MODULES=\\(.*\\b${mod}\\b" /etc/mkinitcpio.conf; then
            continue
        fi
        sudo sed -i "0,/^MODULES=(/{s/^MODULES=(\\(.*\\))/MODULES=(\\1 ${mod})/}" /etc/mkinitcpio.conf
    done
    sudo sed -i 's/MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
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
    # rustup из пакетов не выбирает тулчейн сам. Без этого makepkg paru
    # падает: "rustup could not choose a version of rustc to run".
    command -v rustup >/dev/null || die "Нет rustup. Он нужен, чтобы собрать paru."
    log "Rust stable, иначе сборка paru не стартует"
    rustup default stable
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
    sync_dir "${PERSONAL_DIR}/.config/zsh"     "${HOME}/.config/zsh"
    sync_dir "${PERSONAL_DIR}/.config/eza"     "${HOME}/.config/eza"
    sync_dir "${PERSONAL_DIR}/.config/gtk-3.0" "${HOME}/.config/gtk-3.0"
    sync_dir "${PERSONAL_DIR}/.config/gtk-4.0" "${HOME}/.config/gtk-4.0"
    sync_dir "${PERSONAL_DIR}/.config/fsh"     "${HOME}/.config/fsh"
    sync_dir "${PERSONAL_DIR}/.config/Kvantum" "${HOME}/.config/Kvantum"
    sync_dir "${PERSONAL_DIR}/.config/qt6ct"   "${HOME}/.config/qt6ct"
    sync_dir "${PERSONAL_DIR}/.config/MangoHud" "${HOME}/.config/MangoHud"
    sync_dir "${PERSONAL_DIR}/.config/xdg-desktop-portal" "${HOME}/.config/xdg-desktop-portal"
    if [[ -f "${PERSONAL_DIR}/.config/mimeapps.list" ]]; then
        mkdir -p "${HOME}/.config"
        rsync -a "${PERSONAL_DIR}/.config/mimeapps.list" "${HOME}/.config/mimeapps.list"
    fi
    mkdir -p "${HOME}/.config/tmux"
    rsync -a "${PERSONAL_DIR}/.config/tmux/tmux.conf" "${HOME}/.config/tmux/tmux.conf"
    if [[ -d "${PERSONAL_DIR}/.config/tmux/cheat-sheet" ]]; then
        sync_dir "${PERSONAL_DIR}/.config/tmux/cheat-sheet" "${HOME}/.config/tmux/cheat-sheet"
    fi

    # zsh читает этот файл только из $HOME, до ZDOTDIR. Содержимое не меняется.
    if [[ -f "${PERSONAL_DIR}/.config/zsh/zshenv" ]]; then
        cp -a "${PERSONAL_DIR}/.config/zsh/zshenv" "${HOME}/.zshenv"
    fi

    if [[ -d "${PERSONAL_DIR}/.local/share/applications" ]]; then
        mkdir -p "${HOME}/.local/share/applications"
        rsync -a "${PERSONAL_DIR}/.local/share/applications/" "${HOME}/.local/share/applications/"
        command -v update-desktop-database >/dev/null \
            && update-desktop-database "${HOME}/.local/share/applications" || true
    fi

    chmod +x "${HOME}/.config/hypr/scripts/"*.sh "${HOME}/.config/waybar/launch.sh" 2>/dev/null || true
}

setup_zsh() {
    log "zsh + zinit"
    if ! command -v zsh >/dev/null; then
        die "Нет zsh. Сначала ./setup.sh packages"
    fi
    local zsh_bin
    zsh_bin="$(command -v zsh)"
    # chsh без имени пользователя меняет оболочку root. Всегда указываем ${USER}.
    if [[ "${SHELL}" != "${zsh_bin}" ]]; then
        sudo chsh -s "${zsh_bin}" "${USER}"
        log "Оболочка входа сменена на zsh. Заработает после выхода из сессии."
    fi

    local zinit="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
    if [[ ! -d "${zinit}/.git" ]]; then
        mkdir -p "$(dirname "${zinit}")"
        git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "${zinit}"
    fi

    # Раньше скрипт дописывал оболочку поверх репы. Эти файлы больше не нужны.
    rm -f "${HOME}/.oh-my-zsh/custom/rose-pine-moon.zsh" \
          "${HOME}/.oh-my-zsh/custom/aliases.zsh"

    # Плагины zinit качаются при первом интерактивном запуске нового .zshrc.
    if [[ -f "${HOME}/.config/zsh/.zshrc" ]]; then
        zsh -ic 'exit' || warn "Первый запуск zsh не докачал плагины. Открой новый терминал."
    fi
}

setup_gtk4_theme() {
    # Libadwaita не смотрит gtk-theme-name. Ей нужен css рядом с settings.ini.
    local css=/usr/share/themes/rose-pine-moon-gtk/gtk-4.0/gtk.css
    [[ -f "${css}" ]] || return 0
    mkdir -p "${HOME}/.config/gtk-4.0"
    ln -sfn "${css}" "${HOME}/.config/gtk-4.0/gtk.css"
    if [[ -d /usr/share/themes/rose-pine-moon-gtk/gtk-4.0/assets ]]; then
        ln -sfn /usr/share/themes/rose-pine-moon-gtk/gtk-4.0/assets "${HOME}/.config/gtk-4.0/assets"
    fi
}

restore_igpu() {
    # Старый скрипт мог записать AsusMuxDgpu и выключить встроенную карту.
    [[ -f /etc/supergfxd.conf ]] || return 0
    if grep -q 'AsusMuxDgpu' /etc/supergfxd.conf; then
        log "Возвращаю Hybrid: встроенная графика больше не выключается"
        sudo sed -i 's/AsusMuxDgpu/Hybrid/g' /etc/supergfxd.conf
        warn "Перезагрузись, чтобы iGPU снова появилась. Сервис сейчас не перезапускаю."
    fi
}

apply_grub_keys() {
    local snippet="$1" file=/etc/default/grub
    [[ -f "${file}" ]] || { warn "Нет ${file}, ключи GRUB не пишу"; return 0; }
    local line key value
    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" =~ ^[[:space:]]*(#|$) ]] && continue
        [[ "${line}" == *=* ]] || continue
        key="${line%%=*}"
        value="${line#*=}"
        [[ -n "${key}" ]] || continue
        if grep -qE "^[[:space:]]*#?[[:space:]]*${key}=" "${file}"; then
            sudo sed -i -E "s|^[[:space:]]*#?[[:space:]]*${key}=.*|${key}=${value}|" "${file}"
        else
            printf '%s=%s\n' "${key}" "${value}" | sudo tee -a "${file}" >/dev/null
        fi
    done < "${snippet}"
    if grep -qE '^[[:space:]]*GRUB_TERMINAL_OUTPUT=.*console' "${file}"; then
        sudo sed -i -E 's|^([[:space:]]*GRUB_TERMINAL_OUTPUT=.*)|#\1|' "${file}"
    fi
}

cleanup_stale() {
    # Только то, что раньше написал этот сетап и что теперь мешает.
    # ~/.zprofile не трогаем: туда же пишется автозапуск Hyprland.
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        log "Удаляю ~/.oh-my-zsh: оболочка на zinit, каталог больше не нужен"
        rm -rf "${HOME}/.oh-my-zsh"
    fi
}

setup_grub_theme() {
    # Инсталлятор темы всегда спрашивает стиль в stdin, поэтому копируем сами:
    # Arch, 1080p, цветные иконки. /etc/default/grub целиком не заменяется.
    if ! pacman -Q grub &>/dev/null; then
        warn "Пакет grub не установлен, тему меню ставить некуда."
        if [[ -f /boot/loader/loader.conf ]] || pacman -Q systemd-boot &>/dev/null; then
            warn "Загрузчик похож на systemd-boot, не GRUB."
        fi
        warn "Проверка: pacman -Q grub; ls -d /boot/grub /boot/loader 2>/dev/null; efibootmgr"
        return 0
    fi
    if ! sudo test -d /boot/grub; then
        warn "Пакет grub есть, но каталога /boot/grub нет. Тему не копирую."
        warn "Посмотри: sudo ls /boot /efi /boot/efi; bootctl status"
        return 0
    fi
    local snippet="${PERSONAL_DIR}/system/grub/dark-matter.conf"
    [[ -f "${snippet}" ]] || { warn "Нет ${snippet}"; return 0; }

    local src="${PERSONAL_DIR}/system/grub/rose-pine-moon"
    [[ -f "${src}/theme.txt" && -f "${src}/background.png" ]] || { warn "Нет темы ${src}"; return 0; }

    local theme=/boot/grub/themes/rose-pine-moon
    log "GRUB Rose Pine Moon → ${theme}"
    sudo install -d -m 755 "${theme}"
    # /boot — FAT32, владельца не сохраняем.
    sudo cp -r "${src}/." "${theme}/"

    local font="" candidate
    for candidate in \
        /usr/share/fonts/TTF/DejaVuSans.ttf \
        /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf \
        /usr/share/fonts/dejavu/DejaVuSans.ttf
    do
        if [[ -f "${candidate}" ]]; then
            font="${candidate}"
            break
        fi
    done
    if [[ -z "${font}" ]]; then
        sudo pacman -S --noconfirm --needed ttf-dejavu || true
        [[ -f /usr/share/fonts/TTF/DejaVuSans.ttf ]] && font=/usr/share/fonts/TTF/DejaVuSans.ttf
    fi
    if [[ -n "${font}" && -x /usr/bin/grub-mkfont ]]; then
        sudo grub-mkfont -s 22 -o "${theme}/dejavu-22.pf2" "${font}"
        sudo grub-mkfont -s 16 -o "${theme}/dejavu-16.pf2" "${font}"
    else
        warn "Нет grub-mkfont или DejaVu. Меню будет, но шрифт системный."
    fi
    sudo chmod -R a+rX "${theme}" || true

    apply_grub_keys "${snippet}"
    if [[ -x /usr/bin/grub-mkconfig ]]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig не прошёл, тема на диске есть, меню могло не обновиться"
    else
        warn "Нет grub-mkconfig"
    fi
    if sudo test -f /boot/grub/grub.cfg && sudo grep -q 'rose-pine-moon/theme.txt' /boot/grub/grub.cfg; then
        log "В /boot/grub/grub.cfg тема rose-pine-moon есть."
    else
        warn "В grub.cfg темы нет. Пришли: grep GRUB_THEME /etc/default/grub"
    fi
    setup_luks_before_grub
}

setup_luks_before_grub() {
    # Меню до пароля значит: ядро и grub.cfg лежат вне LUKS.
    # Поменять порядок можно только если /boot уже внутри зашифрованного корня.
    local root_src boot_src boot_fstype
    root_src="$(findmnt -no SOURCE / 2>/dev/null || true)"
    boot_src="$(findmnt -no SOURCE /boot 2>/dev/null || true)"
    boot_fstype="$(findmnt -no FSTYPE /boot 2>/dev/null || true)"
    root_src="${root_src%%\[*}"
    boot_src="${boot_src%%\[*}"
    [[ -n "${boot_src}" ]] || boot_src="${root_src}"

    if [[ "${root_src}" != /dev/mapper/* && "${root_src}" != /dev/dm-* ]]; then
        warn "Корень не на LUKS (${root_src:-не найден}). Порядок GRUB и пароля не меняю."
        return 0
    fi
    if [[ "${boot_fstype}" == "vfat" || ( -n "${boot_src}" && "${boot_src}" != "${root_src}" && "${boot_src}" != /dev/mapper/* && "${boot_src}" != /dev/dm-* ) ]]; then
        warn "/boot (${boot_src}, ${boot_fstype}) не зашифрован, ядро лежит там."
        warn "Пока так, GRUB всегда раньше LUKS. Перенос /boot внутрь диска из скрипта не делаю: ошибка оставит ноутбук без загрузки."
        return 0
    fi

    log "Пароль LUKS будет до меню GRUB"
    if grep -qE '^[[:space:]]*#?[[:space:]]*GRUB_ENABLE_CRYPTODISK=' /etc/default/grub; then
        sudo sed -i -E 's|^[[:space:]]*#?[[:space:]]*GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|' /etc/default/grub
    else
        echo 'GRUB_ENABLE_CRYPTODISK=y' | sudo tee -a /etc/default/grub >/dev/null
    fi

    local efi="" candidate
    for candidate in /efi /boot/efi /boot; do
        if sudo test -d "${candidate}/EFI"; then
            efi="${candidate}"
            break
        fi
    done
    if [[ -z "${efi}" ]]; then
        warn "Не нашёл EFI-раздел (/efi, /boot/efi или /boot/EFI). grub-install не запускаю."
        return 0
    fi
    sudo grub-install --target=x86_64-efi --efi-directory="${efi}" --bootloader-id=GRUB --recheck \
        || { warn "grub-install не прошёл. Пароль до меню мог не включиться."; return 0; }

    add_luks_keyfile "${root_src}" || warn "Второй пароль LUKS (уже в системе) может остаться"

    if [[ -x /usr/bin/grub-mkconfig ]]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig после cryptodisk не прошёл"
    fi
}

add_luks_keyfile() {
    # Ключ кладём в initramfs, чтобы после меню пароль не спрашивали ещё раз.
    # Вызывать только когда /boot внутри LUKS: иначе ключ лежал бы открытым.
    local root_src="$1" mapper dev uuid key
    mapper="${root_src#/dev/mapper/}"
    dev="$(sudo cryptsetup status "${mapper}" 2>/dev/null | awk '/device:/ {print $2; exit}')"
    [[ -n "${dev}" ]] || { warn "cryptsetup status ${mapper} не дал диск"; return 0; }
    uuid="$(sudo cryptsetup luksUUID "${dev}" 2>/dev/null || true)"
    [[ -n "${uuid}" ]] || { warn "Нет UUID у ${dev}"; return 0; }

    if grep -q 'sd-encrypt' /etc/mkinitcpio.conf 2>/dev/null; then
        key="/etc/cryptsetup-keys.d/${uuid}.key"
        sudo install -d -m 700 /etc/cryptsetup-keys.d
    else
        key="/crypto_keyfile.bin"
    fi

    if [[ ! -f "${key}" ]]; then
        sudo dd if=/dev/urandom of="${key}" bs=512 count=8 iflag=fullblock status=none
        sudo chmod 000 "${key}"
        log "Один раз введи текущий пароль LUKS, чтобы добавить ключ для initramfs"
        sudo cryptsetup luksAddKey "${dev}" "${key}" || { sudo rm -f "${key}"; warn "Слот ключа не добавлен"; return 0; }
    fi

    if ! grep -qF "${key}" /etc/mkinitcpio.conf; then
        sudo sed -i -E "s|^FILES=\\((.*)\\)|FILES=(\\1 ${key})|" /etc/mkinitcpio.conf
        sudo sed -i -E 's|^FILES=\( |FILES=(|' /etc/mkinitcpio.conf
    fi
    if ! grep -q 'sd-encrypt' /etc/mkinitcpio.conf && ! grep -q 'cryptkey=rootfs:' /etc/default/grub; then
        sudo sed -i -E "s|^(GRUB_CMDLINE_LINUX=\")|\\1cryptkey=rootfs:${key} |" /etc/default/grub
    fi
    if [[ -x /usr/bin/mkinitcpio ]]; then
        sudo mkinitcpio -P || warn "mkinitcpio -P не прошёл, второй пароль может остаться"
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

setup_color_scheme() {
    # GTK-тема в settings.ini браузеру мало. Helium и остальные Chromium
    # спрашивают у портала color-scheme. Без prefer-dark он отвечает «светлая».
    log "Тёмная схема: приложения и браузер"
    if command -v gsettings >/dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' \
            || warn "gsettings color-scheme не записался"
        gsettings set org.gnome.desktop.interface gtk-theme 'rose-pine-moon-gtk' || true
        gsettings set org.gnome.desktop.interface icon-theme 'rose-pine-moon-icons' || true
        gsettings set org.gnome.desktop.interface cursor-theme 'BreezeX-RosePine-Linux' || true
        gsettings set org.gnome.desktop.interface cursor-size 24 || true
    else
        warn "Нет gsettings. Поставь glib2 и gsettings-desktop-schemas, потом ./setup.sh dotfiles"
    fi
    systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gtk.service 2>/dev/null || true
}

setup_autologin() {
    [[ "${AUTOLOGIN}" == "1" ]] || return 0
    log "Hyprland на tty1 без оболочки между паролем и рабочим столом"
    local dm
    for dm in sddm gdm lightdm greetd ly lxdm; do
        if systemctl is-enabled "${dm}.service" &>/dev/null; then
            log "Выключаю ${dm}: он показывает свой экран входа вместо tty1"
            sudo systemctl disable "${dm}.service" || true
        fi
    done

    # Старый путь: agetty --autologin запускал zsh, и консоль успевала
    # нарисоваться. retain-splash это не перекрывает: текстовый tty
    # сбрасывает картинку. Теперь Hyprland берёт tty1 сам, без оболочки.
    sudo rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf \
        /etc/systemd/system/plymouth-quit.service.d/retain.conf
    sudo systemctl disable getty@tty1.service || true
    sudo systemctl enable getty@tty2.service || true

    if ! command -v start-hyprland >/dev/null; then
        warn "Нет start-hyprland. Автовход не включил, tty1 останется обычным."
        sudo systemctl enable getty@tty1.service || true
        return 0
    fi

    sudo tee /etc/systemd/system/hyprland-tty-fallback.service >/dev/null << 'EOF'
[Unit]
Description=Show tty1 login if Hyprland failed

[Service]
Type=oneshot
ExecStart=-/usr/bin/plymouth quit
ExecStart=/usr/bin/systemctl start getty@tty1.service
EOF
    sudo tee /etc/systemd/system/hyprland-tty.service >/dev/null << EOF
[Unit]
Description=Hyprland on tty1
After=systemd-user-sessions.service plymouth-quit.service
Conflicts=getty@tty1.service
OnFailure=hyprland-tty-fallback.service

[Service]
User=${USER}
PAMName=login
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty
StandardOutput=journal
StandardError=journal
WorkingDirectory=${HOME}
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_CURRENT_DESKTOP=Hyprland
Environment=XDG_SESSION_DESKTOP=Hyprland
ExecStartPre=-/usr/bin/plymouth quit
ExecStart=/usr/bin/start-hyprland
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable hyprland-tty.service

    if command -v zsh >/dev/null; then
        local zsh_bin
        zsh_bin="$(command -v zsh)"
        if [[ "${SHELL}" != "${zsh_bin}" ]]; then
            sudo chsh -s "${zsh_bin}" "${USER}" || warn "Не сменил оболочку на zsh"
        fi
    fi

    # Убираем старый exec start-hyprland из профиля. Иначе запасной вход
    # на tty1 сразу снова уйдёт в Hyprland и оболочки не будет.
    local marker="# ptaha-autologin"
    local profile
    for profile in "${HOME}/.config/zsh/.zprofile" "${HOME}/.zprofile" "${HOME}/.bash_profile"; do
        [[ -f "${profile}" ]] || continue
        grep -q "${marker}" "${profile}" || continue
        awk -v marker="${marker}" '
            $0 == marker { skip = 1; next }
            skip && $0 == "fi" { skip = 0; next }
            skip { next }
            { print }
        ' "${profile}" > "${profile}.tmp"
        mv "${profile}.tmp" "${profile}"
    done
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

setup_grok() {
    [[ "${INSTALL_GROK}" == "1" ]] || return 0
    command -v curl >/dev/null || { warn "Нет curl, Grok CLI не поставлю"; return 0; }
    log "Grok CLI"
    # Бинарник в ~/.grok/bin. Установщик дописывает ~/.zshrc, но zsh читает
    # ~/.config/zsh/.zshrc (ZDOTDIR). PATH для grok лежит в том файле в репозитории.
    curl -fsSL https://x.ai/cli/install.sh | bash || { warn "Установщик Grok не прошёл"; return 0; }
    if [[ ! -x "${HOME}/.grok/bin/grok" ]]; then
        warn "Бинарник ~/.grok/bin/grok не появился"
        return 0
    fi
    sudo ln -sfn "${HOME}/.grok/bin/grok" /usr/local/bin/grok
    if [[ -e "${HOME}/.grok/bin/agent" ]]; then
        sudo ln -sfn "${HOME}/.grok/bin/agent" /usr/local/bin/agent
    fi
}

setup_ge_proton() {
    # Warcraft III Reforged на старом Proton пишет «Please check your VPN».
    # Это не VPN: чинится GE-Proton 11-7 и новее. Ставим последний релиз.
    [[ "${INSTALL_BATTLENET}" == "1" ]] || return 0
    command -v curl >/dev/null || { warn "Нет curl, GE-Proton не скачаю"; return 0; }
    command -v python3 >/dev/null || { warn "Нет python3, GE-Proton не скачаю"; return 0; }

    local lutris_dir="${HOME}/.local/share/lutris/runners/wine"
    local steam_dir="${HOME}/.local/share/Steam/compatibilitytools.d"
    mkdir -p "${lutris_dir}" "${steam_dir}"

    local tag
    tag="$(curl -fsSL --retry 3 https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')" || true
    if [[ -z "${tag}" ]]; then
        warn "Не узнал последнюю версию GE-Proton. Поставь её в ProtonUp-Qt, цель Lutris."
        return 0
    fi
    if [[ ! -x "${lutris_dir}/${tag}/bin/wine" ]]; then
        log "Качаю ${tag} для Lutris"
        local tmp archive
        tmp="$(mktemp -d)"
        archive="${tmp}/${tag}.tar.gz"
        if curl -fL --retry 3 -o "${archive}" \
            "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${tag}/${tag}.tar.gz"; then
            tar -C "${lutris_dir}" -xzf "${archive}"
        else
            warn "GE-Proton не скачался. Поставь ${tag} или новее через ProtonUp-Qt для Lutris."
            rm -rf "${tmp}"
            return 0
        fi
        rm -rf "${tmp}"
    else
        log "GE-Proton ${tag} уже стоит"
    fi
    [[ -x "${lutris_dir}/${tag}/bin/wine" ]] || { warn "В архиве нет bin/wine"; return 0; }
    ln -sfn "${lutris_dir}/${tag}" "${steam_dir}/${tag}"
    if [[ -d "${HOME}/.steam/root" && "${HOME}/.steam/root/compatibilitytools.d" != "${steam_dir}" ]]; then
        mkdir -p "${HOME}/.steam/root/compatibilitytools.d"
        ln -sfn "${lutris_dir}/${tag}" "${HOME}/.steam/root/compatibilitytools.d/${tag}"
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
    if [[ "${INSTALL_BATTLENET}" == "1" ]]; then
        # Лаунчер 32-битный, раннер — GE-Proton: свои библиотеки уже внутри.
        # Эти lib32 Arch убрал из multilib, pacman из-за них валит всю установку:
        # giflib, mpg123, openal, v4l-utils, libxslt, gst-plugins-base-libs.
        pkgs+=(
            lutris
            umu-launcher
            wine wine-mono wine-gecko winetricks
            python-protobuf python-pefile
            vkd3d lib32-vkd3d
            vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools
            gnutls lib32-gnutls
            giflib
            libpng lib32-libpng
            libldap lib32-libldap
            mpg123
            openal
            v4l-utils
            libpulse lib32-libpulse
            alsa-plugins lib32-alsa-plugins
            alsa-lib lib32-alsa-lib
            libjpeg-turbo lib32-libjpeg-turbo
            sqlite lib32-sqlite
            libxcomposite lib32-libxcomposite
            libxinerama lib32-libxinerama
            ncurses lib32-ncurses
            libxslt
            libva lib32-libva
            gtk3 lib32-gtk3
            gst-plugins-base-libs
            cabextract
        )
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
    setup_grok
    setup_ge_proton
    rebuild_initramfs_if_ucode
}

setup_plymouth() {
    # Пароль LUKS спрашивается уже в initramfs, после меню GRUB.
    # Plymouth рисует его. cryptdevice и хук encrypt не трогаем, только
    # вставляем plymouth перед encrypt и слово splash в командную строку.
    log "Экран пароля LUKS: Plymouth, Rose Pine Moon"
    sudo pacman -S --noconfirm --needed plymouth ttf-dejavu \
        || { warn "plymouth не поставился"; return 0; }

    local src="${PERSONAL_DIR}/system/plymouth/rose-pine-moon"
    [[ -f "${src}/rose-pine-moon.script" ]] || { warn "Нет ${src}"; return 0; }
    sudo install -d /usr/share/plymouth/themes/rose-pine-moon
    sudo cp -r "${src}/." /usr/share/plymouth/themes/rose-pine-moon/
    sudo plymouth-set-default-theme rose-pine-moon \
        || warn "Не переключил тему Plymouth"
    printf '%s\n' '[Daemon]' 'Theme=rose-pine-moon' 'ShowDelay=0' 'DeviceTimeout=8' \
        | sudo tee /etc/plymouth/plymouthd.conf >/dev/null

    # UKI не читает GRUB_CMDLINE. splash должен лежать в /etc/kernel/cmdline,
    # иначе plymouthd не забирает экран и пароль остаётся белым текстом.
    local cmdline_file=/etc/kernel/cmdline cmdline="" flag
    if [[ -f "${cmdline_file}" ]]; then
        cmdline="$(tr '\n' ' ' < "${cmdline_file}")"
    elif [[ -r /proc/cmdline ]]; then
        cmdline="$(cat /proc/cmdline)"
    fi
    for flag in quiet splash nvidia-drm.modeset=1 systemd.show_status=false rd.systemd.show_status=false vt.global_cursor_default=0; do
        if [[ " ${cmdline} " != *" ${flag} "* ]]; then
            cmdline="${cmdline} ${flag}"
        fi
    done
    cmdline="${cmdline#"${cmdline%%[![:space:]]*}"}"
    cmdline="${cmdline%"${cmdline##*[![:space:]]}"}"
    if [[ "${cmdline}" != *cryptdevice* && "${cmdline}" != *rd.luks* ]]; then
        warn "В командной строке ядра нет cryptdevice. Файл ${cmdline_file} не трогаю, иначе диск не откроется."
    else
        printf '%s\n' "${cmdline}" | sudo tee "${cmdline_file}" >/dev/null
        log "Командная строка UKI: ${cmdline}"
    fi

    if [[ -f /etc/mkinitcpio.conf ]]; then
        local hooks inner
        hooks="$(grep -E '^HOOKS=' /etc/mkinitcpio.conf | head -1 || true)"
        inner="${hooks#HOOKS=(}"
        inner="${inner%)}"
        inner="${inner//plymouth/}"
        if [[ "${inner}" == *kms* ]]; then
            inner="${inner/kms/kms plymouth}"
        elif [[ "${inner}" == *encrypt* ]]; then
            inner="${inner/encrypt/plymouth encrypt}"
        fi
        inner="$(echo "${inner}" | tr -s ' ')"
        inner="${inner#"${inner%%[![:space:]]*}"}"
        inner="${inner%"${inner##*[![:space:]]}"}"
        sudo sed -i -E "s|^HOOKS=.*|HOOKS=(${inner})|" /etc/mkinitcpio.conf
    fi

    local grub=/etc/default/grub key=GRUB_CMDLINE_LINUX_DEFAULT line value flag
    if [[ -f "${grub}" ]]; then
        for flag in quiet splash nvidia-drm.modeset=1 systemd.show_status=false rd.systemd.show_status=false vt.global_cursor_default=0; do
            line="$(grep -E "^${key}=" "${grub}" || true)"
            if [[ -z "${line}" ]]; then
                echo "${key}=\"${flag}\"" | sudo tee -a "${grub}" >/dev/null
                continue
            fi
            value="${line#*=}"
            value="${value#\"}"
            value="${value%\"}"
            if [[ " ${value} " == *" ${flag} "* ]]; then
                continue
            fi
            value="${value} ${flag}"
            value="${value#"${value%%[![:space:]]*}"}"
            sudo sed -i -E "s|^${key}=.*|${key}=\"${value}\"|" "${grub}"
        done
        if [[ -x /usr/bin/grub-mkconfig ]] && sudo test -d /boot/grub; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg \
                || warn "grub-mkconfig для splash не прошёл"
        fi
    fi

    if [[ -x /usr/bin/mkinitcpio ]]; then
        log "Пересобираю UKI: /boot/EFI/Linux/arch-linux.efi. Это несколько минут."
        sudo mkinitcpio -P || warn "mkinitcpio -P не прошёл. Пароль останется текстом."
    fi
    local uki="/boot/EFI/Linux/arch-linux.efi"
    if [[ -f /etc/mkinitcpio.d/linux.preset ]]; then
        local preset_uki
        preset_uki="$(sed -nE 's/^default_uki="([^"]+)".*/\1/p' /etc/mkinitcpio.d/linux.preset | head -1)"
        [[ -n "${preset_uki}" ]] && uki="${preset_uki}"
    fi
    if sudo test -f "${uki}" && sudo lsinitcpio "${uki}" | grep -q plymouth; then
        log "Plymouth есть в ${uki}. После перезагрузки пароль будет на тёмном экране."
    else
        warn "В ${uki} нет Plymouth. Пароль останется белым текстом."
    fi
}

setup_wallpaper() {
    local img="${HOME}/.config/hypr/wallpapers/wallpaper2.jpg"
    [[ -f "${img}" ]] || { warn "Нет ${img}"; return 0; }
    command -v awww >/dev/null || { warn "Нет awww. Сначала ./setup.sh packages"; return 0; }
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        warn "Не Wayland-сессия. Обои встанут при входе в Hyprland."
        return 0
    fi
    log "Ставлю обои ${img}"
    if ! awww query >/dev/null 2>&1; then
        awww-daemon &
        sleep 0.4
    fi
    awww img "${img}" || warn "awww не смог поставить обои"
}

cmd_dotfiles() {
    need_user
    clone_or_pull "${PERSONAL_URL}" "${PERSONAL_DIR}"
    clone_or_pull "${NVIM_URL}" "${NVIM_DIR}"
    deploy_dotfiles
    cleanup_stale
    setup_wallpaper
    setup_gtk4_theme
    setup_color_scheme
    setup_zsh
    setup_keyd
    setup_tmux_plugins
    setup_autologin
    restore_igpu
    setup_services
}

cmd_boot() {
    need_user
    clone_or_pull "${PERSONAL_URL}" "${PERSONAL_DIR}"
    setup_grub_theme
    setup_plymouth
}

main() {
    local mode="${1:-all}"
    case "${mode}" in
        packages) cmd_packages ;;
        dotfiles) cmd_dotfiles ;;
        wallpaper) setup_wallpaper ;;
        boot) cmd_boot ;;
        all|"")
            cmd_packages
            cmd_dotfiles
            cmd_boot
            ;;
        *)
            die "Неизвестный режим: ${mode}. Используй: packages | dotfiles | wallpaper | boot | all"
            ;;
    esac

    cat << EOF

Готово.

Дальше:
  1. Перезагрузись. Сначала меню GRUB, потом тёмный экран пароля LUKS,
     затем сразу Hyprland (если AUTOLOGIN=1).
     Пароль пользователя на tty1 не спрашивается. Запуск Hyprland лежит
     в ~/.config/zsh/.zprofile, не в ~/.zprofile.
     Тёмная схема для браузера включается здесь же. Helium после этого
     закрой полностью и открой снова.
  2. sudo по-прежнему спрашивает пароль.
  3. Открой nvim один раз и дождись, пока lazy.nvim скачает плагины,
     потом :Mason чтобы докачались lua_ls, rust_analyzer, clangd.
  4. В tmux нажми Ctrl-b затем I, если тема rose-pine не встала сама.
  5. Оболочка: zinit, atuin, fzf-tab, fast-syntax-highlighting.
     Новый терминал подхватит их. Ctrl-R — история atuin.
  6. Grok в терминале: зайди в папку проекта и набери grok.
     Первый запуск откроет браузер для входа. Обновление: grok update.
  7. Новые программы: допиши в PACMAN_EXTRA или AUR_EXTRA в этом файле
     и запусти ./setup.sh packages
  8. NVIDIA основная, встроенная на месте. ls -l /dev/dri/nvidia-dgpu /dev/dri/amd-igpu
     Steam не берёт 780M: DXVK_FILTER_DEVICE_NAME и VKD3D_FILTER_DEVICE_NAME.
     cat /sys/module/nvidia_drm/parameters/modeset должно быть Y.
  9. GRUB: меню Rose Pine Moon со знаком Arch, режим 1920x1200.
     Строка загрузки LUKS в /etc/default/grub не переписывается.
  10. Тема Rosé Pine Moon: GTK (rose-pine-moon-gtk + иконки), Qt через Kvantum,
     MangoHud, fzf. nvim не трогал. Подсветка zsh уже была Moon.
  11. Battle.net: открой Lutris и поставь скрипт battlenet-standard
      (или в терминале: lutris lutris:install/battlenet-standard).
      На первом установщике не логинься, пока он сам не закроется.
      Потом из лаунчера ставь WoW и Warcraft III Reforged.
      Раннер в Lutris: последний GE-Proton, не системный wine.
      Для Reforged нужен GE-Proton 11-7 или новее, иначе «Please check your VPN».
      NVIDIA та же, что у Steam: фильтры DXVK/VKD3D уже в сессии.

Не ставил vulkan-intel: у тебя AMD CPU + NVIDIA, этот пакет был в старом init.sh по ошибке.
wezterm берётся из Extra, а не wezterm-git: не надо компилировать Rust-терминал полчаса.
oh-my-zsh больше не ставится. chsh всегда с именем пользователя (старый zsh.sh менял root).
nvidia-utils ставится только если карта или модуль уже есть.
keyd входит в пакеты, раньше скрипт включал сервис и не ставил пакет.
iGPU не отключается. Если прошлый запуск записал AsusMuxDgpu, скрипт возвращает Hybrid.
Скрипт сам собирает только то, чего нет в репе: симлинки /dev/dri/*,
ссылку gtk-4.0/gtk.css на тему из пакета, копию темы GRUB в /boot
и ключи из system/grub/dark-matter.conf.
EOF
}

main "$@"
