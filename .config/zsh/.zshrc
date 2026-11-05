# Конфиг целиком здесь. setup.sh его только копирует и ничего в нём не дописывает.
# Плагины: zinit, atuin, fzf-tab, fast-syntax-highlighting. Oh My Zsh нет. Starship нет.

# --- zinit -----------------------------------------------------------------
typeset -g ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f "${ZINIT_HOME}/zinit.zsh" ]]; then
    command mkdir -p "${ZINIT_HOME:h}"
    command git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
fi
source "${ZINIT_HOME}/zinit.zsh"

# eza читает ~/.config/eza/theme.yml. LS_COLORS его перекрывает.
unset LS_COLORS
unset EZA_COLORS

# fzf вне меню tab. Цвета fzf-tab заданы ниже отдельно и эту переменную не читают.
export FZF_DEFAULT_OPTS='--color=fg:#e0def4,bg:#232136,hl:#c4a7e7,fg+:#e0def4,bg+:#393552,hl+:#9ccfd8,info:#908caa,prompt:#c4a7e7,pointer:#eb6f92,marker:#f6c177,spinner:#9ccfd8,header:#6e6a86,border:#6e6a86'

HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${HOME}/.zsh_history"
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

[[ -r "${HOME}/.config/zsh/aliases.zsh" ]] && source "${HOME}/.config/zsh/aliases.zsh"

# --- промпт Rosé Pine Moon, без git_prompt_info из Oh My Zsh ---------------
autoload -Uz vcs_info
setopt PROMPT_SUBST
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr ''
zstyle ':vcs_info:git:*' formats '%F{#6e6a86}(%F{#c4a7e7}%b%F{#eb6f92}%u%F{#6e6a86}) '
zstyle ':vcs_info:git:*' actionformats '%F{#6e6a86}(%F{#c4a7e7}%b|%a%F{#eb6f92}%u%F{#6e6a86}) '
_ptaha_vcs_precmd() { vcs_info }
precmd_functions+=(_ptaha_vcs_precmd)
PROMPT='%F{#9ccfd8}%~%f ${vcs_info_msg_0_}%F{#c4a7e7}❯%f '

# --- completion, затем fzf-tab, затем atuin --------------------------------
# fzf-tab обязан стоять после compinit и до fast-syntax-highlighting.
# Grok CLI. fpath до compinit, иначе дополнения grok не подхватятся.
# Официальный установщик пишет PATH в ~/.zshrc, zsh его не читает: ZDOTDIR другой.
if [[ -d "${HOME}/.grok/bin" ]]; then
    export PATH="${HOME}/.grok/bin:${PATH}"
fi
if [[ -d "${HOME}/.grok/completions/zsh" ]]; then
    fpath=("${HOME}/.grok/completions/zsh" ${fpath})
fi
mkdir -p "${HOME}/.cache/zsh"
autoload -Uz compinit
compinit -u -d "${HOME}/.cache/zsh/zcompdump"

zstyle ':fzf-tab:*' fzf-flags '--color=fg:#e0def4,bg:#232136,hl:#c4a7e7,fg+:#e0def4,bg+:#393552,hl+:#9ccfd8,info:#908caa,prompt:#c4a7e7,pointer:#eb6f92,marker:#f6c177,spinner:#9ccfd8,header:#6e6a86'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=auto --color=always $realpath'
zinit light Aloxaf/fzf-tab

if (( $+commands[atuin] )); then
    eval "$(atuin init zsh)"
fi

# Подсветка последней: она оборачивает виджеты строки.
export FAST_WORK_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/fsh"
zinit light zdharma-continuum/fast-syntax-highlighting
if [[ -r "${FAST_WORK_DIR}/rose-pine-moon.ini" ]]; then
    # fast-theme каждый раз пишет "Switched to theme". Тема и так запоминается.
    fast-theme "${FAST_WORK_DIR}/rose-pine-moon.ini" >/dev/null
fi

unset LS_COLORS
unset EZA_COLORS
