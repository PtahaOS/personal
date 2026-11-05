# eza. Тот же набор пишет setup.sh в rose-pine-moon.zsh, он грузится позже и побеждает.
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -lh --icons=auto --git --group-directories-first --time-style=long-iso'
alias la='eza -lah --icons=auto --git --group-directories-first'
alias lt='eza -T --icons=auto --git-ignore --group-directories-first'
alias lta='eza -Ta --icons=auto --group-directories-first'
alias vim='nvim .'
alias update_my_conf="zsh ~/personal/update-my-conf"
alias shutdown="killall helium && shutdown"
