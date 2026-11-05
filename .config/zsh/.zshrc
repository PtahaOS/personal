# Конфиг целиком здесь. setup.sh его только копирует и ничего в нём не дописывает.
export ZSH="$HOME/.oh-my-zsh"

# Промпт задан ниже, тема Oh My Zsh не нужна. Starship нет.
ZSH_THEME=""

plugins=(
    git
    zsh-autosuggestions
)

source "$ZSH/oh-my-zsh.sh"

# Oh My Zsh ставит LS_COLORS, а он важнее ~/.config/eza/theme.yml.
unset LS_COLORS
unset EZA_COLORS

HISTSIZE=100000
SAVEHIST=100000
HISTFILE="${HOME}/.zsh_history"
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

source "${HOME}/.config/zsh/aliases.zsh"

# Rosé Pine Moon
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6e6a86'
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#e0def4'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#eb6f92,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c4a7e7'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ccfd8'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#9ccfd8'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#3e8fb0'
ZSH_HIGHLIGHT_STYLES[function]='fg=#3e8fb0'
ZSH_HIGHLIGHT_STYLES[command]='fg=#9ccfd8'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#c4a7e7'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#908caa'
ZSH_HIGHLIGHT_STYLES[path]='fg=#f6c177'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ea9a97'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f6c177'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f6c177'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6e6a86'

PROMPT='%F{#9ccfd8}%~%f $(git_prompt_info)%F{#c4a7e7}❯%f '
ZSH_THEME_GIT_PROMPT_PREFIX="%F{#6e6a86}(%F{#c4a7e7}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{#6e6a86}) "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{#eb6f92}*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Подсветка синтаксиса должна быть последней, иначе ломаются виджеты zsh.
if [[ -r "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
