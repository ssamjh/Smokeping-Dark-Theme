# SmokePing Dark Theme

A modern, sleek dark theme for [SmokePing](https://oss.oetiker.ch/smokeping/) 2.9+.

- Dark UI (sidebar, navbar, panels, footer) with a blue accent, rounded corners
  and subtle shadows — no changes to SmokePing itself, just a template + CSS.
- Graphs keep their original colors so the "smoke" stays fully readable; the
  graph background is only softened from white to a gentle off-white
  (`#e9edf3`) and the 3D borders are removed, so they sit like cards on the
  dark page.
- No data is touched — everything is presentation-only.

## Files

| File | Purpose |
| --- | --- |
| `basepage.html` | SmokePing page template (points at the dark CSS, dark favicon) |
| `css/smokeping-dark.css` | The stylesheet |
| `apache/theme-alias.conf` | Apache alias so the CSS is served from a persistent path |

## Install (linuxserver/smokeping docker image)

The container's webroot is not persisted, so the theme lives entirely in the
bind-mounted `/config` volume and survives container recreation.

1. Copy the theme into the config volume:

   ```sh
   mkdir -p /path/to/smokeping/config/theme
   cp basepage.html css/smokeping-dark.css /path/to/smokeping/config/theme/
   ```

2. Add the alias from `apache/theme-alias.conf` to
   `config/site-confs/smokeping.conf`, **above** the existing
   `Alias /smokeping ...` line:

   ```apache
   Alias /smokeping/theme /config/theme
   <Directory "/config/theme">
       Require all granted
   </Directory>
   ```

3. In `config/Presentation`, point at the new template and soften the graph
   background (SmokePing 2.9+):

   ```ini
   *** Presentation ***

   template = /config/theme/basepage.html
   charset  = utf-8
   graphborders = no
   colorbackground = e9edf3
   ```

4. Restart the container:

   ```sh
   docker restart smokeping
   ```

   Cached graph PNGs regenerate on their own; to see the new graph background
   immediately you can clear only the rendered images (this does **not** touch
   the RRD history):

   ```sh
   docker exec smokeping sh -c \
     'find /var/cache/smokeping -name "*.png" -not -name smokeping.png -not -name rrdtool.png -delete'
   ```

## Install (native SmokePing)

Drop `smokeping-dark.css` into your SmokePing `htdocs/css/` directory,
adjust the `<link rel="stylesheet" ...>` path in `basepage.html` accordingly,
set `template = /path/to/basepage.html` in the Presentation section, and add
the `graphborders` / `colorbackground` settings shown above.
