# SmokePing Dark Theme

A modern, sleek dark theme for [SmokePing](https://oss.oetiker.ch/smokeping/) 2.9+ — including fully dark graphs with white "smoke".

- Dark UI (sidebar, navbar, panels, footer) with a blue accent, rounded corners
  and subtle shadows.
- Dark graphs: the smoke is drawn as translucent, accent-tinted bands that
  ramp from near-invisible at the edges to a soft core at the median, so the
  latency distribution reads as smoke rather than flat grey blocks and the
  median line stays the brightest thing on the plot. The median / loss
  palette is re-tuned so every loss level stays visible on a dark canvas, loss
  backgrounds become subtle tints of the canvas colour instead of bright
  pastels, the grid is a faint solid white, and the fonts are larger and
  anti-aliased.
- No data is touched — everything is presentation-only. The RRD files are
  never modified.

## How it works

SmokePing 2.9 exposes `graphborders`, `colorbackground` and `colortext` in the
Presentation config, but the smoke shading, loss palette, median base line,
zero-rule, grid colors and fonts are hardcoded for a light canvas. A small init
script (`custom-cont-init.d/10-dark-graphs.sh`) patches those at container
start:

| Patch | Effect |
| --- | --- |
| `smokecol` in `Smokeping.pm` draws one translucent accent-tinted colour per band | the nested bands stack into a gradient from 6% coverage at the edges to 60% at the median, for any ping count, so 5-ping and 20-ping probes both look right |
| Loss palette (`#26ff00`, `#00b8ff`, `#0059ff`, …) → bright evenly spaced hues | median line and loss legend stay readable; the stock blues and purples vanish on dark |
| Loss background tints blend the loss colour into `colorbackground` | subtle tinted loss columns instead of bright pastels |
| `LINE1:median#202020` → `#dfe5ee`, `HRULE:0#000000` → `#8b96a5` | base line and zero-rule visible on dark |
| Add `GRID`/`MGRID`/`AXIS`/`ARROW` colors, `--grid-dash 1:0` and `--font` sizes in `Graphs.pm` | faint solid grid, muted axes, larger anti-aliased title / axis / legend text |
| `RRDLeft` / `RRDRight` in `smokeping.js` | drag-to-zoom still maps pixels to time with the larger axis font |

The script is idempotent and re-applies automatically after image updates or
container recreation. `uninstall-dark-graphs.sh` reverses every patch on a
running container or native install.

## Files

| File | Purpose |
| --- | --- |
| `basepage.html` | SmokePing page template (dark CSS link, dark favicon) |
| `css/smokeping-dark.css` | The stylesheet |
| `apache/theme-alias.conf` | Apache alias so the CSS is served from a persistent path |
| `custom-cont-init.d/10-dark-graphs.sh` | Container init script that patches SmokePing for dark graphs |
| `uninstall-dark-graphs.sh` | Reverses the graph patches (running container or native install) |

## Install (linuxserver/smokeping docker image)

The container's webroot and perl libs are not persisted, so the theme lives in
bind-mounted volumes and a startup script — it survives container recreation
and image updates.

1. Copy the theme into the config volume and the init script next to it:

   ```sh
   mkdir -p /path/to/smokeping/config/theme /path/to/smokeping/custom-cont-init.d
   cp basepage.html css/smokeping-dark.css /path/to/smokeping/config/theme/
   cp custom-cont-init.d/10-dark-graphs.sh /path/to/smokeping/custom-cont-init.d/
   chown root:root /path/to/smokeping/custom-cont-init.d/10-dark-graphs.sh
   chmod 755 /path/to/smokeping/custom-cont-init.d/10-dark-graphs.sh
   ```

2. Mount the init script directory in your compose file:

   ```yaml
   volumes:
     - ./config:/config
     - ./data:/data
     - ./custom-cont-init.d:/custom-cont-init.d:ro
   ```

3. Add the alias from `apache/theme-alias.conf` to
   `config/site-confs/smokeping.conf`, **above** the existing
   `Alias /smokeping ...` line:

   ```apache
   Alias /smokeping/theme /config/theme
   <Directory "/config/theme">
       Require all granted
   </Directory>
   ```

4. In `config/Presentation`, point at the new template and set the dark graph
   colors (SmokePing 2.9+). The background matches the panel surface so the
   graph sits flush inside its card:

   ```ini
   *** Presentation ***

   template = /config/theme/basepage.html
   charset  = utf-8
   graphborders = no
   colorbackground = 1a212b
   colortext = dfe5ee
   ```

   Optionally give the overview graphs an accent median line, in the
   `+ overview` section:

   ```ini
   median_color = 58b7ff
   ```

5. Recreate the container and clear only the rendered graph images (this does
   **not** touch the RRD history):

   ```sh
   docker compose up -d
   docker exec smokeping sh -c \
     'find /var/cache/smokeping -name "*.png" -not -name smokeping.png -not -name rrdtool.png -delete'
   ```

   When upgrading the theme to a newer `10-dark-graphs.sh`, force a fresh
   container so the script patches pristine files rather than skipping ones it
   already marked as patched:

   ```sh
   docker compose up -d --force-recreate
   ```

## Light-graph variant

Prefer to keep the stock light graphs on the dark page? Skip the init script
and the `colortext` line, and use a soft off-white background instead:

```ini
graphborders = no
colorbackground = e9edf3
```

Then set `--graph-bg: #e9edf3;` in `css/smokeping-dark.css` so the panel hover
states still match.

## Install (native SmokePing)

Drop `smokeping-dark.css` into your SmokePing `htdocs/css/` directory, adjust
the `<link rel="stylesheet" ...>` path in `basepage.html` accordingly, set
`template = /path/to/basepage.html` in the Presentation section, add the
Presentation settings shown above, and apply `10-dark-graphs.sh` once against
your installed `Smokeping.pm` / `Graphs.pm` / `smokeping.js` (adjust the paths
at the top of the script if they differ; re-run after upgrades).
