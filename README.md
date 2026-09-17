# SmokePing Dark Theme

A modern, easy-on-the-eyes dark theme for [SmokePing](https://oss.oetiker.ch/smokeping/) 2.9 and newer. It darkens the whole UI and, more importantly, the graphs themselves, so the "smoke" finally looks like smoke instead of grey blocks.

![Detail page with four dark graphs](docs/images/detail-page.png)

## What you get

- **A dark UI.** Sidebar, navbar, panels and footer all go dark, with a blue accent, rounded corners and soft shadows.
- **Dark graphs.** The smoke is drawn as translucent, accent-tinted bands that fade from nearly invisible at the edges to a soft core at the median. The latency spread reads as a cloud, and the median line stays the brightest thing on the plot.
- **A loss palette that works on dark.** The median and loss colours are re-tuned so every loss level is visible. Loss backgrounds become subtle tints of the canvas instead of bright pastels. The grid is a faint solid white, and the fonts are larger and anti-aliased.
- **Your data is safe.** Everything here is presentation only. The RRD files are never touched.

Here is what a target with a bit of packet loss looks like over ten days. The vertical tints are loss, the pale cloud around the line is the smoke:

![Ten day graph with smoke and loss](docs/images/graph-10-days.png)

And the same target over the last 30 hours:

![Thirty hour graph](docs/images/graph-30-hours.png)

The overview pages get the same treatment:

![Overview page](docs/images/overview-page.png)

## How it works

SmokePing 2.9 lets you set `graphborders`, `colorbackground` and `colortext` in the Presentation config, but the smoke shading, loss palette, median base line, zero rule, grid colours and fonts are all hardcoded for a light canvas. A small init script (`custom-cont-init.d/10-dark-graphs.sh`) patches those at container start:

| Patch | Effect |
| --- | --- |
| `smokecol` in `Smokeping.pm` draws one translucent accent-tinted colour per band | The nested bands stack into a gradient from 6% coverage at the edges to 60% at the median. This works for any ping count, so 5-ping and 20-ping probes both look right. |
| Loss palette (`#26ff00`, `#00b8ff`, `#0059ff`, and so on) becomes bright, evenly spaced hues | The median line and loss legend stay readable. The stock blues and purples vanish on dark. |
| Loss background tints blend the loss colour into `colorbackground` | Subtle tinted loss columns instead of bright pastels. |
| `LINE1:median#202020` becomes `#dfe5ee`, `HRULE:0#000000` becomes `#8b96a5` | The base line and zero rule are visible on dark. |
| `GRID`, `MGRID`, `AXIS` and `ARROW` colours, `--grid-dash 1:0` and `--font` sizes added in `Graphs.pm` | Faint solid grid, muted axes, larger anti-aliased title, axis and legend text. |
| `RRDLeft` and `RRDRight` in `smokeping.js` | Drag-to-zoom still maps pixels to time correctly with the larger axis font. |

The script is idempotent and re-applies itself after image updates or container recreation. If you ever want to go back, `uninstall-dark-graphs.sh` reverses every patch on a running container or a native install.

## What's in the box

| File | Purpose |
| --- | --- |
| `basepage.html` | SmokePing page template with the dark CSS link and a dark favicon |
| `css/smokeping-dark.css` | The stylesheet |
| `apache/theme-alias.conf` | Apache alias so the CSS is served from a persistent path |
| `custom-cont-init.d/10-dark-graphs.sh` | Container init script that patches SmokePing for dark graphs |
| `uninstall-dark-graphs.sh` | Reverses the graph patches on a running container or native install |

## Install on the linuxserver/smokeping Docker image

The container's webroot and Perl libs are not persisted, so the theme lives in bind-mounted volumes plus a startup script. That way it survives container recreation and image updates.

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

3. Add the alias from `apache/theme-alias.conf` to `config/site-confs/smokeping.conf`, **above** the existing `Alias /smokeping ...` line:

   ```apache
   Alias /smokeping/theme /config/theme
   <Directory "/config/theme">
       Require all granted
   </Directory>
   ```

4. In `config/Presentation`, point at the new template and set the dark graph colours. The background matches the panel surface so each graph sits flush inside its card:

   ```ini
   *** Presentation ***

   template = /config/theme/basepage.html
   charset  = utf-8
   graphborders = no
   colorbackground = 1a212b
   colortext = dfe5ee
   ```

   If you would like the overview graphs to have an accent-coloured median line, add this to the `+ overview` section:

   ```ini
   median_color = 58b7ff
   ```

5. Recreate the container and clear the rendered graph images. This does **not** touch your RRD history, it just forces SmokePing to draw fresh PNGs:

   ```sh
   docker compose up -d
   docker exec smokeping sh -c \
     'find /var/cache/smokeping -name "*.png" -not -name smokeping.png -not -name rrdtool.png -delete'
   ```

That's it. Reload the page and enjoy.

### Upgrading the theme

When you pull a newer `10-dark-graphs.sh`, force a fresh container so the script patches pristine files instead of skipping ones it already marked as patched:

```sh
docker compose up -d --force-recreate
```

## Prefer light graphs on the dark page?

No problem. Skip the init script and the `colortext` line, and use a soft off-white background instead:

```ini
graphborders = no
colorbackground = e9edf3
```

Then set `--graph-bg: #e9edf3;` in `css/smokeping-dark.css` so the panel hover states still match.

## Install on a native SmokePing

1. Drop `smokeping-dark.css` into your SmokePing `htdocs/css/` directory.
2. Adjust the `<link rel="stylesheet" ...>` path in `basepage.html` to match.
3. Set `template = /path/to/basepage.html` in the Presentation section and add the Presentation settings shown above.
4. Run `10-dark-graphs.sh` once against your installed `Smokeping.pm`, `Graphs.pm` and `smokeping.js`. Adjust the paths at the top of the script if yours differ, and re-run it after upgrades.

## Credits

SmokePing is by Tobi Oetiker and Niko Tyni. The screenshots above are from a live instance running the linuxserver/smokeping image.
