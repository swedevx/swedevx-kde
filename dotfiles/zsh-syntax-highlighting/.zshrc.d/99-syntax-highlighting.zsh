# dotfiles/zsh-syntax-highlighting/.zshrc.d/99-syntax-highlighting.zsh
for f in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
    [[ -r $f ]] && { source "$f"; break; }
done
unset f
