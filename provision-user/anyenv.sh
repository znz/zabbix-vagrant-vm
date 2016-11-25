#!/bin/bash
set -euxo pipefail
if [[ ! -d "$HOME/.anyenv" ]]; then
  git clone https://github.com/riywo/anyenv "$HOME/.anyenv"
fi
if ! grep -q anyenv "$HOME/.bashrc"; then
  # shellcheck disable=SC2016
  echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> ~/.bashrc
  # shellcheck disable=SC2016
  echo 'eval "$(anyenv init - --no-rehash)"' >> ~/.bashrc
fi
export PATH="$HOME/.anyenv/bin:$PATH"
set +x
eval "$(anyenv init - --no-rehash)"
set -x
if [[ ! -d "$(anyenv root)/plugins/anyenv-update" ]]; then
  git clone https://github.com/znz/anyenv-update "$(anyenv root)/plugins/anyenv-update"
fi
if [[ ! -d "$(anyenv root)/plugins/anyenv-git" ]]; then
  git clone https://github.com/znz/anyenv-git "$(anyenv root)/plugins/anyenv-git"
fi
if [[ ! -d "$HOME/.anyenv/envs/rbenv" ]]; then
  anyenv install rbenv
fi
set +x
eval "$(anyenv init - --no-rehash)"
set -x
if [[ ! -d "$(rbenv root)/plugins/rbenv-plug" ]]; then
  git clone https://github.com/znz/rbenv-plug "$(rbenv root)/plugins/rbenv-plug"
fi
rbenv plug gem-src
rbenv plug each
