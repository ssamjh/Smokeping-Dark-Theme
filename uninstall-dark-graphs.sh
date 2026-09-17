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
JS=/usr/share/webapps/smokeping/js/smokeping.js

if grep -q 'dark-theme-patch' "$SP"; then
    perl -0pi -e '
        # smoke: translucent bands -> stock grayscale rings
        s{my \$n = int\(\$count / 2\);\n\s*my \$cnow  = .*\n\s*my \$cprev = .*\n\s*my \$alpha = sprintf\("%02x", 255 \* \(1 - \(1 - \$cnow\) / \(1 - \$cprev\)\)\);}{my \$color = int(190/\$half * (\$half-\$ibot))+50;};
        s{"STACK:smoke\$\{ibot\}#9ecbff\$alpha"}{"STACK:smoke\${ibot}#".(sprintf("%02x",\$color) x 3)};

        # loss palette -> stock colours
        s{\x27#4ade80\x27}{\x27#26ff00\x27};
        s{\x27#38bdf8\x27}{\x27#00b8ff\x27};
        s{\x27#60a5fa\x27}{\x27#0059ff\x27};
        s{\x27#a78bfa\x27}{\x27#7e00ff\x27};
        s{\x27#e879f9\x27}{\x27#ff00ff\x27};
        s{\x27#fb923c\x27}{\x27#ff5500\x27};
        s{\x27#f87171\x27}{\x27#ff0000\x27};
        s{\x27#ff3b3b\x27}{\x27#a00000\x27};

        # loss background: canvas blend -> stock lighten-towards-white
        s{my \@bg = Smokeping::Colorspace::web_to_rgb\(\$cfg->\{Presentation\}\{colorbackground\} \|\| "000000"\);\n(\s*)\@rgb = map \{ \$rgb\[\$_\] \* 0\.18 \+ \$bg\[\$_\] \* 0\.82 \} 0\.\.2;\n}{my \@hsl = Smokeping::Colorspace::rgb_to_hsl(\@rgb);\n$1\$hsl[2] = (1 - \$hsl[2]) * (2/3) + \$hsl[2];\n$1\@rgb = Smokeping::Colorspace::hsl_to_rgb(\@hsl);\n};

        # lines
        s{LINE1:median#dfe5ee}{LINE1:median#202020};
        s{HRULE:0#8b96a5}{HRULE:0#000000};

        s{# dark-theme-patch applied\n}{};
    ' "$SP"
    echo "[uninstall-dark-graphs] reverted $SP"
else
    echo "[uninstall-dark-graphs] $SP not patched, skipping"
fi

if grep -q 'dark-theme-patch' "$GR"; then
    perl -0pi -e '
        s{[ \t]*# dark-theme-patch: grid, axis and fonts\n[ \t]*push\(\@colorList,\n(?:[ \t]+.*\n)*?[ \t]*\);\n}{};
        s{# dark-theme-patch applied\n}{};
    ' "$GR"
    echo "[uninstall-dark-graphs] reverted $GR"
else
    echo "[uninstall-dark-graphs] $GR not patched, skipping"
fi

if [ -f "$JS" ] && grep -q 'dark-theme-patch' "$JS"; then
    sed -i \
        -e 's|var RRDLeft  = 75; // dark-theme-patch|var RRDLeft  = 67;|' \
        -e 's|var RRDRight = 30;|var RRDRight = 26;|' \
        "$JS"
    echo "[uninstall-dark-graphs] reverted $JS"
else
    echo "[uninstall-dark-graphs] $JS not patched, skipping"
fi
