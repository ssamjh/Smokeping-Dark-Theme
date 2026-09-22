#!/bin/bash
# Apply the optional graph typography enhancement for SmokePing.
#
# This idempotent startup patch changes only graph font declarations and the
# matching drag-to-zoom margins. SmokePing's stock graph colours, smoke, grid,
# axes, connector, canvas, and renderer remain unchanged. It does not touch
# RRD data.

GR=/usr/share/smokeping/Smokeping/Graphs.pm
JS=/usr/share/webapps/smokeping/js/smokeping.js

if [ -f "$GR" ] && ! grep -q 'dark-font-patch' "$GR"; then
    perl -0pi -e '
        my $replaced = s{(push\(\@colorList, \x27--color\x27, "CANVAS#\$\{colorBackground\}"\);\n)}{$1        # dark-font-patch: DejaVu graph fonts\n        push(\@colorList,\n            \x27--font\x27, \x27DEFAULT:9:DejaVu Sans Mono\x27,\n            \x27--font\x27, \x27TITLE:10:DejaVu Sans Bold\x27,\n            \x27--font\x27, \x27AXIS:8:DejaVu Sans\x27,\n            \x27--font\x27, \x27UNIT:9:DejaVu Sans\x27,\n            \x27--font\x27, \x27LEGEND:8.5:DejaVu Sans Mono\x27,\n            \x27--font\x27, \x27WATERMARK:6:DejaVu Sans\x27,\n        );\n};
        die "[10-dark-graphs] could not find the stock graph colour list\n" unless $replaced;
    ' "$GR"
    if grep -q 'dark-font-patch: DejaVu graph fonts' "$GR"; then
        echo '# dark-font-patch applied' >> "$GR"
        echo "[10-dark-graphs] patched $GR"
    else
        echo "[10-dark-graphs] patch failed for $GR" >&2
        exit 1
    fi
elif [ -f "$GR" ]; then
    echo "[10-dark-graphs] $GR already patched, skipping"
else
    echo "[10-dark-graphs] $GR not found, skipping"
fi

# Keep drag-to-zoom's pixel-to-time mapping aligned with the larger fonts.
if [ -f "$JS" ] && ! grep -q 'dark-font-patch' "$JS"; then
    sed -i \
        -e 's|var RRDLeft  = 67;|var RRDLeft  = 75; // dark-font-patch|' \
        -e 's|var RRDRight = 26;|var RRDRight = 30;|' \
        "$JS"
    if grep -q 'dark-font-patch' "$JS"; then
        echo "[10-dark-graphs] patched $JS"
    else
        echo "[10-dark-graphs] stock zoom margins not found in $JS" >&2
        exit 1
    fi
elif [ -f "$JS" ]; then
    echo "[10-dark-graphs] $JS already patched, skipping"
else
    echo "[10-dark-graphs] $JS not found, skipping"
fi
