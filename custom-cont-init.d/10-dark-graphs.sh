#!/bin/bash
# Dark-graph patches for SmokePing (linuxserver/smokeping image).
#
# SmokePing hardcodes a handful of colours that only work on a light
# canvas. This script patches them at container start so the graphs render
# dark: translucent "smoke" that fades out from the median, a loss palette
# that stays visible on a dark background, subtle solid grid lines and
# larger anti-aliased fonts. It runs from /custom-cont-init.d before
# apache/smokeping start and is idempotent (safe across plain restarts);
# because the image files are patched in the container layer, it re-applies
# automatically after image updates or container recreation.
#
# Pair this with these Presentation settings:
#   graphborders = no
#   colorbackground = 1a212b
#   colortext = dfe5ee

SP=/usr/share/smokeping/Smokeping.pm
GR=/usr/share/smokeping/Smokeping/Graphs.pm
JS=/usr/share/webapps/smokeping/js/smokeping.js

if ! grep -q 'dark-theme-patch' "$SP"; then
    perl -0pi -e '
        # Smoke: one translucent, accent-tinted colour per band. The bands are
        # nested, so stacking them builds a gradient that is densest next to
        # the median. Coverage ramps from 6% at the outermost band to 60% at
        # the median (like the stock grey ramp, inverted) for any ping count;
        # each band alpha is whatever gets the stack from the previous
        # coverage to the next.
        s{my \$color = int\(190/\$half \* \(\$half-\$ibot\)\)\+50;}{my \$n = int(\$count / 2);\n        my \$cnow  = \$n > 1 ? 0.06 + 0.54 * (\$ibot - 1) / (\$n - 1) : 0.60;\n        my \$cprev = \$ibot > 1 ? 0.06 + 0.54 * (\$ibot - 2) / (\$n - 1) : 0;\n        my \$alpha = sprintf("%02x", 255 * (1 - (1 - \$cnow) / (1 - \$cprev)));};
        s{"STACK:smoke\$\{ibot\}#"\.\(sprintf\("%02x",\$color\) x 3\)}{"STACK:smoke\${ibot}#9ecbff\$alpha"};

        # Median / loss palette: bright, evenly spaced hues that keep their
        # contrast on a dark canvas (the stock blues and purples vanish).
        s{\x27#26ff00\x27}{\x27#4ade80\x27};   # 0 lost
        s{\x27#00b8ff\x27}{\x27#38bdf8\x27};   # ~1%
        s{\x27#0059ff\x27}{\x27#60a5fa\x27};   # ~5%
        s{\x27#7e00ff\x27}{\x27#a78bfa\x27};   # ~10%
        s{\x27#ff00ff\x27}{\x27#e879f9\x27};   # ~25%
        s{\x27#ff5500\x27}{\x27#fb923c\x27};   # ~50%
        s{\x27#ff0000\x27}{\x27#f87171\x27};   # < all
        s{\x27#a00000\x27}{\x27#ff3b3b\x27};   # all lost

        # Loss background: blend the loss colour into the canvas colour
        # instead of lightening it towards white.
        s{(my \$web = \$lc\{\$key\}\[1\];\n\s*my \@rgb = Smokeping::Colorspace::web_to_rgb\(\$web\);\n)(\s*)my \@hsl = Smokeping::Colorspace::rgb_to_hsl\(\@rgb\);\n\s*\$hsl\[2\] = \(1 - \$hsl\[2\]\) \* \(2/3\) \+ \$hsl\[2\];\n\s*\@rgb = Smokeping::Colorspace::hsl_to_rgb\(\@hsl\);\n}{$1$2my \@bg = Smokeping::Colorspace::web_to_rgb(\$cfg->{Presentation}{colorbackground} || "000000");\n$2\@rgb = map { \$rgb[\$_] * 0.18 + \$bg[\$_] * 0.82 } 0..2;\n};

        # Lines that were black for a white canvas.
        s{LINE1:median#202020}{LINE1:median#dfe5ee};
        s{HRULE:0#000000}{HRULE:0#8b96a5};
    ' "$SP"
    echo '# dark-theme-patch applied' >> "$SP"
    echo "[10-dark-graphs] patched $SP"
fi

if ! grep -q 'dark-theme-patch' "$GR"; then
    perl -0pi -e '
        s{(push\(\@colorList, \x27--color\x27, "CANVAS#\$\{colorBackground\}"\);\n)}{$1        # dark-theme-patch: grid, axis and fonts\n        push(\@colorList,\n            \x27--color\x27, \x27GRID#ffffff14\x27,\n            \x27--color\x27, \x27MGRID#ffffff38\x27,\n            \x27--color\x27, \x27AXIS#8b96a5\x27,\n            \x27--color\x27, \x27ARROW#8b96a5\x27,\n            \x27--grid-dash\x27, \x271:0\x27,\n            \x27--font\x27, \x27DEFAULT:9:DejaVu Sans Mono\x27,\n            \x27--font\x27, \x27TITLE:10:DejaVu Sans Bold\x27,\n            \x27--font\x27, \x27AXIS:8:DejaVu Sans\x27,\n            \x27--font\x27, \x27UNIT:9:DejaVu Sans\x27,\n            \x27--font\x27, \x27LEGEND:8.5:DejaVu Sans Mono\x27,\n            \x27--font\x27, \x27WATERMARK:6:DejaVu Sans\x27,\n        );\n};
    ' "$GR"
    echo '# dark-theme-patch applied' >> "$GR"
    echo "[10-dark-graphs] patched $GR"
fi

# The zoom selector maps pixels to time using hardcoded graph margins that
# match the stock fonts. Keep them in sync with the larger fonts above.
if [ -f "$JS" ] && ! grep -q 'dark-theme-patch' "$JS"; then
    sed -i \
        -e 's|var RRDLeft  = 67;|var RRDLeft  = 75; // dark-theme-patch|' \
        -e 's|var RRDRight = 26;|var RRDRight = 30;|' \
        "$JS"
    echo "[10-dark-graphs] patched $JS"
fi
