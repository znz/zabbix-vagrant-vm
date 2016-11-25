#!/bin/bash
set -euxo pipefail
if [[ -d "/usr/share/doc/vim-editorconfig" ]]; then
  vim-addons install editorconfig
fi
