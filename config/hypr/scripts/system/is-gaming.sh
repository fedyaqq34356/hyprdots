#!/bin/sh

hyprctl -j clients 2>/dev/null | jq -e '
    any(.[]; (.fullscreen // 0) != 0 and (.hidden | not) and
        (((.contentType // "") == "game") or
         ((.class // "") | test("^(steam_app_[0-9]+|arma3(_x64)?(\\.exe)?|gamescope|hoi4|cities2(\\.exe)?|.+\\.exe)$"; "i"))))
' >/dev/null
