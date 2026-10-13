#!/bin/sh
if wl-paste --list-types | grep -qi "x-kde-passwordManagerHint"; then
    exit 0
fi
exec cliphist -max-items 150 store
