[[ $- != *i* ]] && return

if ! locale -a 2>/dev/null | grep -q "en_US.utf8"; then
    export LANG=C.utf8 LC_ALL=C.utf8
fi

export PATH="$HOME/bin:$PATH"
