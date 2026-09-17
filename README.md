# SmokePing Dark Theme

A modern, sleek dark theme for [SmokePing](https://oss.oetiker.ch/smokeping/) 2.9+ — including fully dark graphs with white "smoke".

- Dark UI (sidebar, navbar, panels, footer) with a blue accent, rounded corners
  and subtle shadows.
- Dark graphs: the smoke grayscale is inverted so the dense center of the
  latency distribution renders near-white on a dark slate canvas, one step
  lighter than the surrounding panel so the plot area stays distinct and the
  smoke keeps its contrast. Loss backgrounds become dark tints instead of
  bright pastels, and the grid is a subtle translucent white.
- No data is touched — everything is presentation-only. The RRD files are
  never modified.

## How it works

SmokePing 2.9 exposes `graphborders`, `colorbackground` and `colortext` in the
Presentation config, but the smoke shading, median base line, zero-rule and
grid colors are hardcoded for a light canvas. A small init script
(`custom-cont-init.d/10-dark-graphs.sh`) patches those at container start:

| Patch | Effect |
| --- | --- |
| Invert `smokecol` grayscale in `Smokeping.pm` | smoke is bright at the median, dark at the edges |
| `LINE1:median#202020` → `#e6e9ef` | median base line visible on dark |
| `HRULE:0#000000` → `#aab4c0` | baseline visible on dark |
| Darken (not brighten) loss/uptime background tints | subtle dark loss bands instead of bright pastels |
| Add `GRID`/`MGRID`/`AXIS`/`ARROW` colors in `Graphs.pm` | subtle light grid and axes |

The script is idempotent and re-applies automatically after image updates or
container recreation.

## Files

| File | Purpose |
| --- | --- |
| `basepage.html` | SmokePing page template (dark CSS link, dark favicon) |
| `css/smokeping-dark.css` | The stylesheet |
| `apache/theme-alias.conf` | Apache alias so the CSS is served from a persistent path |
| `custom-cont-init.d/10-dark-graphs.sh` | Container init script that patches SmokePing for dark graphs |

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
   colors (SmokePing 2.9+):

   ```ini
   *** Presentation ***

   template = /config/theme/basepage.html
   charset  = utf-8
   graphborders = no
   colorbackground = 28313f
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
your installed `Smokeping.pm` / `Graphs.pm` (re-run after upgrades).
