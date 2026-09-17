#!/bin/bash
# Dark-graph patches for SmokePing (linuxserver/smokeping image).
#
# SmokePing hardcodes a handful of colors that only work on a light
# canvas. This script patches them at container start so the graphs can
# render dark with white "smoke". It runs from /custom-cont-init.d before
# apache/smokeping start and is idempotent (safe across plain restarts);
# because the image files are patched in the container layer, it re-applies
# automatically after image updates or container recreation.
#
# Pair this with these Presentation settings:
#   graphborders = no
#   colorbackground = 28313f
#   colortext = dfe5ee

SP=/usr/share/smokeping/Smokeping.pm
GR=/usr/share/smokeping/Smokeping/Graphs.pm

if ! grep -q 'dark-theme-patch' "$SP"; then
    sed -i \
        -e 's|int(190/$half \* ($half-$ibot))+50|245 - int(155/$half * ($half-$ibot))|' \
        -e 's|LINE1:median#202020|LINE1:median#e6e9ef|' \
        -e 's|HRULE:0#000000|HRULE:0#aab4c0|' \
        -e 's|$hsl\[2\] = (1 - $hsl\[2\]) \* (2/3) + $hsl\[2\];|$hsl[2] = $hsl[2] * (1/3);|' \
        "$SP"
    echo '# dark-theme-patch applied' >> "$SP"
    echo "[10-dark-graphs] patched $SP"
fi

if ! grep -q 'GRID#ffffff22' "$GR"; then
    sed -i 's|"CANVAS#${colorBackground}");|"CANVAS#${colorBackground}");\n        push(@colorList, "--color", "GRID#ffffff22", "--color", "MGRID#ffffff3c", "--color", "AXIS#aab4c0", "--color", "ARROW#aab4c0");|' "$GR"
    echo "[10-dark-graphs] patched $GR"
fi
