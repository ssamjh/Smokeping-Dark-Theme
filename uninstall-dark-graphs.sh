#!/bin/bash
# Remove the optional graph typography enhancement from SmokePing.
#
# Docker example:
#   docker exec smokeping bash < uninstall-dark-graphs.sh
#
# Native installs: adjust the paths below and run this script as root. It
# safely skips unpatched files and never touches RRD data.

GR=/usr/share/smokeping/Smokeping/Graphs.pm
JS=/usr/share/webapps/smokeping/js/smokeping.js

if [ -f "$GR" ] && grep -q 'dark-font-patch' "$GR"; then
    perl -0pi -e '
        s{[ \t]*# dark-font-patch: DejaVu graph fonts\n[ \t]*push\(\@colorList,\n(?:[ \t]+.*\n)*?[ \t]*\);\n}{};
        s{# dark-font-patch applied\n}{};
    ' "$GR"
    echo "[uninstall-dark-graphs] reverted $GR"
elif [ -f "$GR" ]; then
    echo "[uninstall-dark-graphs] $GR not patched, skipping"
else
    echo "[uninstall-dark-graphs] $GR not found, skipping"
fi

if [ -f "$JS" ] && grep -q 'dark-font-patch' "$JS"; then
    sed -i \
        -e 's|var RRDLeft  = 75; // dark-font-patch|var RRDLeft  = 67;|' \
        -e 's|var RRDRight = 30;|var RRDRight = 26;|' \
        "$JS"
    echo "[uninstall-dark-graphs] reverted $JS"
elif [ -f "$JS" ]; then
    echo "[uninstall-dark-graphs] $JS not patched, skipping"
else
    echo "[uninstall-dark-graphs] $JS not found, skipping"
fi
