#!/bin/bash
set -euxo pipefail
if [[ ! -d "$HOME/s/github.com/znz/dot-shell" ]]; then
  git clone https://github.com/znz/dot-shell "$HOME/s/github.com/znz/dot-shell"
fi
if [[ ! -e "$HOME/.gemrc" ]]; then
  pushd "$HOME/s/github.com/znz/dot-shell"
  make
  popd
fi
if [[ ! -e "$HOME/.zshrc" ]]; then
  echo ". $HOME/s/github.com/znz/dot-shell/zshrc.zsh" >"$HOME/.zshrc"
fi
if [[ ! -e "$HOME/.ssh/config" ]]; then
  echo "HashKnownHosts no" >"$HOME/.ssh/config"
fi
if [[ ! -e "$HOME/.gitconfig" ]]; then
  git config --global user.name "Kazuhiro NISHIYAMA"
  LOCAL="zn"; DOMAIN="mbf.nifty.com"
  git config --global user.email "$LOCAL@$DOMAIN"
  "$HOME/s/github.com/znz/dot-shell/git-config.sh"
fi
if [[ ! -d "$HOME/.byobu" ]]; then
  "$HOME/s/github.com/znz/dot-shell/init-byobu.sh"
fi
