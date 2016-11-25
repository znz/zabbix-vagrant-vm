#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
NADOKA_HOME="$(pwd)"
if [ ! -d wc ]; then
    mkdir wc
fi
if [ ! -d wc/nadoka ]; then
    git clone https://github.com/nadoka/nadoka.git wc/nadoka
else
    (cd wc/nadoka && git pull)
fi
if [ ! -d wc/fprog-nadoka-plugins-trunk ]; then
    svn co http://www.fprog.org/svn/nadoka-plugins/trunk wc/fprog-nadoka-plugins-trunk
else
    (cd wc/fprog-nadoka-plugins-trunk && svn up) || :
fi

NADOKA_PROGRAM="$NADOKA_HOME/wc/nadoka/nadoka.rb"
NADOKA_RC="$NADOKA_HOME/fprog.rc"
if [ -d "$HOME/.anyenv" ]; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init - --no-rehash)"
fi
if [ -d "$HOME/.rbenv" ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init - --no-rehash)"
fi

OOM_ADJ=oom_adj
if [ -f /proc/$$/oom_score_adj ]; then
    OOM_ADJ=oom_score_adj
fi
echo 11 > "/proc/$$/$OOM_ADJ"

cd "/tmp"
exec ruby -vd "$NADOKA_PROGRAM" --rc "$NADOKA_RC"
