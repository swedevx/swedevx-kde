# dotfiles/zsh-autosuggestions/.zshrc.d/50-autosuggestions.zsh
for f in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
         /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    [[ -r $f ]] && { source "$f"; break; }
done
unset f
