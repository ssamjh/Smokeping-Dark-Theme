# SmokePing Dark Theme

This repository is a presentation-only dark theme and graph-rendering integration for SmokePing 2.9 and newer. It is designed primarily for the `linuxserver/smokeping` Docker image, with documented support for native SmokePing installs. It does not change probes, RRD files, retention, or collected latency data.

## Model routing

- You own planning, architecture, and final verification. Don't write bulk code yourself.
- Break work into independent, clearly scoped tasks with success criteria and hand each to a subagent.
- Review subagent output before reporting done.

## Repository map

- `basepage.html` — SmokePing page template. It preserves SmokePing template tokens and loads the dark stylesheet and inline favicon.
- `css/smokeping-dark.css` — screen stylesheet for the sidebar, navbar, panels, graphs, footer, responsive layout, and dark colour variables.
- `apache/theme-alias.conf` — Apache `Alias` and `<Directory>` block that exposes the persistent theme directory at `/smokeping/theme`.
- `custom-cont-init.d/10-dark-graphs.sh` — startup-time, idempotent patches for SmokePing's Perl graph code and JavaScript zoom margins. It adds the `dark-theme-patch` marker.
- `uninstall-dark-graphs.sh` — reverses the graph and zoom patches on a running container or native install; it is not normally needed when a Docker container is recreated from a clean image.
- `README.md` — installation, configuration, upgrade, light-graph, and uninstall instructions. Keep it synchronized with implementation changes.
- `docs/images/` — README screenshots; update only when a visual change makes the existing examples inaccurate.

## Runtime and installation assumptions

- The target runtime is Linux with SmokePing 2.9+; the shell scripts require Bash and standard `grep`, `sed`, and Perl tooling, and normally need root permissions to edit SmokePing installation files.
- The Docker workflow expects the theme files under `/config/theme` and the init script mounted at `/custom-cont-init.d`. The Apache alias must appear before the broader `Alias /smokeping ...` rule.
- The documented dark Presentation settings are `graphborders = no`, `colorbackground = 1a212b`, and `colortext = dfe5ee`; the CSS `--graph-bg` must remain in step with `colorbackground`.
- `basepage.html` expects the alias-backed `theme/smokeping-dark.css` path and SmokePing's existing `js/` assets. Do not replace its `<##...##>` tokens or script imports without checking SmokePing template compatibility.
- Native installs must adjust the paths at the top of both shell scripts and the stylesheet link as described in `README.md`.

## Invariants and safety

- Never modify RRD files, probe configuration, or collected data. Clearing rendered PNGs is safe only when following the README's exclusions for `smokeping.png` and `rrdtool.png`.
- Keep the init script idempotent: it must skip an already marked file, and every inserted block must have a reliable `dark-theme-patch` marker.
- Keep `uninstall-dark-graphs.sh` symmetric with the init script. If a patch, colour, path, or margin changes, update the reverse operation in the same change.
- The patch regexes are coupled to SmokePing's installed source layout and current 2.9-era text. Treat upstream image/package upgrades as compatibility risks; do not broaden replacements casually.
- Do not silently overwrite a user's unrelated SmokePing customizations. Inspect target files and use the documented pristine-image/recreate workflow when a clean baseline is required.
- Preserve the dark graph contract: graph colours, CSS surfaces, Presentation background, and screenshot/documentation examples should agree.
- Avoid adding dependencies, generated files, or a build system unless the project requirements explicitly change.

## Editing guidance

- When editing `basepage.html`, preserve valid SmokePing placeholders, accessible links, the print stylesheet, and all stock JavaScript dependencies. Keep the dark CSS URL consistent with the Apache alias and native-install instructions.
- When editing `css/smokeping-dark.css`, use the existing custom properties for shared colours and dimensions. Check desktop, sidebar-hidden, and narrow-screen states; keep graph panels readable and avoid changing print behaviour unintentionally.
- When editing `apache/theme-alias.conf`, keep the specific `/smokeping/theme` alias ahead of the general SmokePing alias and retain access permissions for `/config/theme`.
- When editing `custom-cont-init.d/10-dark-graphs.sh`, keep paths, markers, comments, and replacement expressions explicit. Changes to SmokePing graph colours, fonts, grid settings, or smoke-band math must be reflected in the uninstall script and README.
- When editing `uninstall-dark-graphs.sh`, limit replacements to values introduced by the dark patch and retain the safe “not patched, skipping” behaviour. Do not turn Docker rollback into a destructive host operation.
- When changing installation steps, required values, supported SmokePing versions, or rollback behaviour, update `README.md` in the same change. If a rendered result changes materially, refresh the relevant file in `docs/images/`.

## Validation workflow

There is no automated build, test suite, package manifest, or CI workflow in this repository. Use proportionate manual checks:

1. Run `git diff --check` and inspect `git diff` for unintended whitespace, generated files, or unrelated changes.
2. On Linux or WSL, run `bash -n custom-cont-init.d/10-dark-graphs.sh uninstall-dark-graphs.sh`.
3. Check that the template tokens, stylesheet path, alias path, patch markers, and reverse replacements still agree across affected files.
4. For runtime changes, test in a disposable SmokePing 2.9+ container or native install: apply the documented Presentation settings, recreate/patch as appropriate, clear only rendered graph PNGs, and verify the page, overview/detail graphs, loss colours, grid/fonts, responsive menu, and drag-to-zoom behaviour.
5. Re-run the init script to confirm it is idempotent, then exercise the documented uninstall or clean-container rollback path. Confirm RRD history is unchanged.

Do not claim runtime validation when only static inspection was performed.

## Definition of done

A change is complete when the requested behaviour is implemented in the smallest appropriate set of files; the init/uninstall pair remains safe and symmetric; template, CSS, Apache, README, and screenshots are synchronized as needed; static checks pass; any runtime check is reported accurately; and `git diff` contains no unrelated changes.
