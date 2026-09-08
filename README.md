# pfSense-theme-lightdark

Light/dark theme for pfSense that follows your operating system's appearance
setting — no manual theme switching. Ships as a pfSense package and also
patches the login page, which pfSense always renders in light mode.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
![pfSense](https://img.shields.io/badge/pfSense-2.8.x-B71C1C)

## What it does

- **`pfSense-light-dark.css`** — a theme you select per user under
  *System → User Manager → (user) → Settings*. It loads the standard
  `pfSense.css` by default and switches to `pfSense-dark.css` behind
  `@media (prefers-color-scheme: dark)`, so the webConfigurator follows the
  system theme of the machine you browse from. Light desktop → light UI,
  dark desktop → dark UI, switching live without reloading settings.
- **Dark-mode fixes** missing from upstream `pfSense-dark.css`:
  - `.text-danger` / `.text-success` / `.text-warning` legibility on dark
    backgrounds (values follow upstream `pfSense-dark-BETA.css`)
  - `pre` / `code` / `kbd` no longer render with light Bootstrap backgrounds
  - `color-scheme: dark` so native widgets (dropdowns, scrollbars, checkboxes)
    render dark too
- **Dark login page** — the login page (`/etc/inc/authgui.inc`) hardcodes
  `login.css` and never loads the per-user theme. The package installs a
  patched `login.css` with a matching `prefers-color-scheme: dark` block.

## Install

Third-party packages install from the CLI (the GUI *Available Packages* tab
only lists the official repo):

```sh
cat > /usr/local/etc/pkg/repos/pfsense-theme-lightdark.conf <<'EOF'
pfsense-theme-lightdark: {
    url: "https://tmiland-labs.github.io/pfsense-theme-lightdark/repo",
    mirror_type: "NONE",
    signature_type: "none",
    enabled: yes
}
EOF
pkg update
pkg install -y -r pfsense-theme-lightdark pfSense-theme-lightdark
```

Then select **pfSense-light-dark** (*System → User Manager → user →
Settings → Theme*). That's it — the login page is patched automatically.

Survives pfSense upgrades: the package is reinstalled by pfSense after an
upgrade and re-applies both the theme file and the login patch.

### Updating login.css after a pfSense upgrade

The login patch only applies when the on-disk `login.css` matches the known
stock content (or is already patched). If a pfSense release changes
`login.css`, the patcher refuses to touch it and says so — copy the new
stock file into `pkg/files/.../login.css.stock`, re-apply the dark block,
and ship a new package version.

## Uninstall

```sh
pkg remove -r pfsense-theme-lightdark pfSense-theme-lightdark
```

The pre-deinstall script restores the stock `login.css`; switch any user
back to `pfSense.css` / `pfSense-dark.css` afterwards.

## Files

| Path | Purpose |
| --- | --- |
| `/usr/local/www/css/pfSense-light-dark.css` | the theme (select it per user) |
| `/usr/local/share/pfsense_theme_lightdark/login.css` | patched login stylesheet |
| `/usr/local/share/pfsense_theme_lightdark/login.css.stock` | stock copy for safe restore |

## Building

```sh
# on a pfSense host (or matching FreeBSD box):
sh pkg/build.sh
```

Output: `/tmp/pfsense-theme-lightdark-repo-out/`. The pkg is published to the
`gh-pages` branch (`repo/` flat layout, `pkg repo .`).

## Credits

- [Netgate / pfSense](https://github.com/pfsense/pfsense) — `pfSense.css`,
  `pfSense-dark.css` and the experimental BETA stylesheets this theme builds
  on (Apache-2.0)
- Built with [opencode](https://opencode.ai)

## License

Apache-2.0 — see [LICENSE](LICENSE). Derived from pfSense's Apache-2.0
stylesheets.
