#!/bin/bash
# Reverses the patches applied by custom-cont-init.d/10-dark-graphs.sh,
# restoring SmokePing's stock light-graph rendering.
#
# Docker (linuxserver/smokeping): you normally don't need this script —
# the patches only exist in the container layer. Instead:
#   1. remove custom-cont-init.d/10-dark-graphs.sh (or the compose mount)
#   2. docker compose up -d --force-recreate
# ...and the image's pristine files are back. Use this script only if you
# want to revert a *running* container without recreating it, e.g.:
#   docker exec smokeping bash < uninstall-dark-graphs.sh
#
# Native installs: run once against your SmokePing installation (adjust the
# paths below if your Smokeping.pm lives elsewhere).
#
# Afterwards, revert the Presentation config for a light look:
#   graphborders = no
#   colorbackground = e9edf3   (or remove both lines for stock rendering)
# and remove the colortext line. Then clear the rendered PNG cache so the
# graphs regenerate (this does NOT touch the RRD history).

SP=/usr/share/smokeping/Smokeping.pm
GR=/usr/share/smokeping/Smokeping/Graphs.pm

if grep -q 'dark-theme-patch' "$SP"; then
    sed -i \
        -e 's|245 - int(155/$half \* ($half-$ibot))|int(190/$half * ($half-$ibot))+50|' \
        -e 's|LINE1:median#e6e9ef|LINE1:median#202020|' \
        -e 's|HRULE:0#aab4c0|HRULE:0#000000|' \
        -e 's|$hsl\[2\] = $hsl\[2\] \* (1/3);|$hsl[2] = (1 - $hsl[2]) * (2/3) + $hsl[2];|' \
        -e '/# dark-theme-patch applied/d' \
        "$SP"
    echo "[uninstall-dark-graphs] reverted $SP"
else
    echo "[uninstall-dark-graphs] $SP not patched, skipping"
fi

if grep -q 'GRID#ffffff22' "$GR"; then
    sed -i '/GRID#ffffff22/d' "$GR"
    echo "[uninstall-dark-graphs] reverted $GR"
else
    echo "[uninstall-dark-graphs] $GR not patched, skipping"
fi
