#!/usr/bin/env zsh

sudo pacman -S --noconfirm --needed zsh 
hash -r
sudo chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git clone "https://github.com/zsh-users/zsh-autosuggestions" "$HOME/zsh-autosuggestions"
rsync -a --delete $HOME/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/


source .zshrc

