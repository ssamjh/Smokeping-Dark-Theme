# SmokePing Dark Theme

This repository is a presentation-only dark theme for SmokePing 2.9 and newer. It is designed primarily for the `linuxserver/smokeping` Docker image, with documented support for native SmokePing installs. It does not change probes, RRD files, retention, or collected latency data. SmokePing's stock graph renderer is retained; the theme changes the page UI, Presentation canvas, and optional graph typography.

## Model routing

- You own planning, architecture, and final verification. Don't write bulk code yourself.
- Break work into independent, clearly scoped tasks with success criteria and hand each to a subagent.
- Review subagent output before reporting done.

## Repository map

- `basepage.html` — SmokePing page template. It preserves SmokePing template tokens and loads the dark stylesheet and inline favicon.
- `css/smokeping-dark.css` — screen stylesheet for the sidebar, navbar, panels, graphs, footer, responsive layout, and dark colour variables. Its `--graph-bg` matches the Presentation canvas.
- `apache/theme-alias.conf` — Apache `Alias` and `<Directory>` block that exposes the persistent theme directory at `/smokeping/theme`.
- `custom-cont-init.d/10-dark-graphs.sh` — idempotent startup patch for DejaVu graph fonts and matching drag-to-zoom margins.
- `uninstall-dark-graphs.sh` — safe reverse helper for the optional font and zoom-margin patch.
- `README.md` — installation, configuration, update, and removal instructions. Keep it synchronized with implementation changes.
- `docs/images/` — README screenshots showing the current theme and graph presentation.

## Runtime and installation assumptions

- The target runtime is Linux with SmokePing 2.9+; the shell scripts require Bash and standard `grep`, `sed`, and Perl tooling, and normally need root permissions to edit SmokePing installation files.
- The Docker workflow expects the theme files under `/config/theme` and the startup script mounted at `/custom-cont-init.d`. The Apache alias must appear before the broader `Alias /smokeping ...` rule.
- The documented Presentation settings are `graphborders = no` and `colorbackground = c9c3b6`; `colortext` is intentionally omitted, and overview/detail dimensions remain at SmokePing's defaults. CSS `--graph-bg` must remain in step with `colorbackground`.
- `basepage.html` expects the alias-backed `theme/smokeping-dark.css` path and SmokePing's existing `js/` assets. Do not replace its `<##...##>` tokens or script imports without checking SmokePing template compatibility.
- Native installs must adjust the stylesheet link and the `GR` and `JS` paths at the top of `custom-cont-init.d/10-dark-graphs.sh` as described in `README.md`.

The startup patch carries the `dark-font-patch` marker in the graph font and zoom-margin changes. The reverse helper uses the same marker and is safe on unpatched files.

## Invariants and safety

- Never modify RRD files, probe configuration, or collected data. Clearing rendered PNGs is safe only when following the README's exclusions for `smokeping.png` and `rrdtool.png`.
- Keep `10-dark-graphs.sh` limited to the DejaVu font and matching zoom-margin changes. It must be idempotent and must never change smoke, loss, grid, axis, connector, or canvas rendering colours.
- Keep `uninstall-dark-graphs.sh` symmetric with the startup patch and safe on unpatched files. It must never be part of the startup path.
- The patch regexes are coupled to SmokePing's installed source layout and current 2.9-era text. Treat upstream image/package upgrades as compatibility risks; do not broaden replacements casually.
- Do not silently overwrite a user's unrelated SmokePing customizations. Inspect target files and use the documented clean-container workflow when a pristine baseline is required.
- Preserve the stock-plus graph contract: stock graph colours and rendering, `colorbackground = c9c3b6`, CSS `--graph-bg: #c9c3b6`, plus only the documented DejaVu graph fonts and corresponding zoom margins. Screenshot and documentation examples should agree.
- Avoid adding dependencies, generated files, or a build system unless the project requirements explicitly change.

## Editing guidance

- When editing `basepage.html`, preserve valid SmokePing placeholders, accessible links, the print stylesheet, and all stock JavaScript dependencies. Keep the dark CSS URL consistent with the Apache alias and native-install instructions.
- When editing `css/smokeping-dark.css`, use the existing custom properties for shared colours and dimensions. Check desktop, sidebar-hidden, and narrow-screen states; keep graph panels readable and avoid changing print behaviour unintentionally.
- When editing `apache/theme-alias.conf`, keep the specific `/smokeping/theme` alias ahead of the general SmokePing alias and retain access permissions for `/config/theme`.
- When editing `custom-cont-init.d/10-dark-graphs.sh`, keep paths, markers, comments, and replacement expressions explicit. Do not add graph colour, smoke, grid, axis, connector, or canvas changes.
- When editing `uninstall-dark-graphs.sh`, limit replacements to values introduced by the startup patch and retain safe “not patched, skipping” behaviour. Do not turn container removal into a destructive host operation.
- When changing installation steps, required values, supported SmokePing versions, or removal behaviour, update `README.md` in the same change. If a rendered result changes materially, refresh the relevant file in `docs/images/`.

## Validation workflow

There is no automated build, test suite, package manifest, or CI workflow in this repository. Use proportionate manual checks:

1. Run `git diff --check` and inspect `git diff` for unintended whitespace, generated files, or unrelated changes.
2. On Linux or WSL, run `bash -n custom-cont-init.d/10-dark-graphs.sh uninstall-dark-graphs.sh`.
3. Check that the template tokens, stylesheet path, alias path, Presentation settings, patch markers, reverse replacements, and screenshot references agree across affected files.
4. For runtime changes, test in a disposable SmokePing 2.9+ container or native install: apply the documented Presentation settings, mount the theme and optional font patch, verify the stock graph colours and font marker, clear only rendered graph PNGs, and verify the page, overview/detail graphs, responsive menu, and drag-to-zoom behaviour.
5. Run the startup script twice to confirm idempotence, then exercise the documented removal helper. Confirm RRD history is unchanged.

Do not claim runtime validation when only static inspection was performed.

## Definition of done

A change is complete when the requested behaviour is implemented in the smallest appropriate set of files; the stock graph renderer, template, CSS, Apache configuration, README, and screenshots are synchronized as needed; static checks pass; any runtime check is reported accurately; and `git diff` contains no unrelated changes.
