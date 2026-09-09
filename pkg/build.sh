#!/bin/sh
# Builds pfSense-theme-lightdark.
# Run ON a pfSense host (or matching FreeBSD box): sh pkg/build.sh
# Output: /tmp/pfsense-theme-lightdark-repo-out/{All/*.pkg}
# NOTE: this package is published into the pfsense-abuseipdb gh-pages pkg
# repo (repo/ dir) — repo metadata there is regenerated with `pkg repo .`
# over the FULL set of packages, not from this output dir alone.
set -eu

PKGDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO=$(dirname "$PKGDIR")
WORK=$(mktemp -d /tmp/pfsense-theme-lightdark-build.XXXXXX)
STAGE="$WORK/stage"
META="$WORK/meta"
OUT="/tmp/pfsense-theme-lightdark-repo-out"
rm -rf "$OUT"
mkdir -p "$STAGE" "$META" "$OUT"

SBASE="usr/local/share/pfsense_theme_lightdark"
mkdir -p "$STAGE/$SBASE" "$STAGE/usr/local/www/css"

install -m 0644 "$REPO/pfSense-light-dark.css" "$STAGE/usr/local/www/css/pfSense-light-dark.css"
install -m 0644 "$PKGDIR/files/usr-local-share-pfsense_theme_lightdark/login.css" "$STAGE/$SBASE/login.css"
install -m 0644 "$PKGDIR/files/usr-local-share-pfsense_theme_lightdark/login.css.stock" "$STAGE/$SBASE/login.css.stock"

VERSION="0.2.3"
ABI=$(pkg config abi)
NAME="pfSense-theme-lightdark"
ORIGIN="www/pfSense-theme-lightdark"

# Patch login.css only when the on-disk file matches the known stock or
# already-patched content — never clobber a modified/upgraded file.
cat > "$META/+POST_INSTALL" <<EOF
#!/bin/sh
SHARE="/usr/local/share/pfsense_theme_lightdark"
TARGET="/usr/local/www/css/login.css"
cur=\$(sha256 -q "\$TARGET" 2>/dev/null || true)
stock=\$(sha256 -q "\$SHARE/login.css.stock")
patched=\$(sha256 -q "\$SHARE/login.css")
if [ "\$cur" = "\$stock" ] || [ "\$cur" = "\$patched" ]; then
	cp -f "\$SHARE/login.css" "\$TARGET"
	echo "pfSense-theme-lightdark: login.css dark mode applied."
else
	echo "pfSense-theme-lightdark: login.css differs from known stock; leaving it untouched." >&2
fi
exit 0
EOF

# Restore stock login.css on removal (before pkg deletes our files).
cat > "$META/+PRE_DEINSTALL" <<'EOF'
#!/bin/sh
SHARE="/usr/local/share/pfsense_theme_lightdark"
TARGET="/usr/local/www/css/login.css"
[ -f "$SHARE/login.css.stock" ] || exit 0
cur=$(sha256 -q "$TARGET" 2>/dev/null || true)
patched=$(sha256 -q "$SHARE/login.css")
if [ "$cur" = "$patched" ]; then
	cp -f "$SHARE/login.css.stock" "$TARGET"
fi
exit 0
EOF

chmod 0755 "$META/+POST_INSTALL" "$META/+PRE_DEINSTALL"

MANIFEST=$(php -r '
$stage = $argv[1]; $meta = $argv[2]; $abi = $argv[3];
$version = $argv[4]; $name = $argv[5]; $origin = $argv[6];
$files = array(); $flatsize = 0;
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($stage, FilesystemIterator::SKIP_DOTS));
foreach ($it as $f) {
    $rel = ltrim(str_replace($stage, "", $f->getPathname()), "/");
    $files["/" . $rel] = hash_file("sha256", $f->getPathname());
    $flatsize += $f->getSize();
}
$dirs = array("/usr/local/share/pfsense_theme_lightdark" => "y");
$manifest = array(
    "name" => $name,
    "origin" => $origin,
    "version" => $version,
    "comment" => "Light/dark system-switching theme for pfSense",
    "desc" => "Adds pfSense-light-dark.css (light theme + pfSense-dark.css behind prefers-color-scheme: dark, with dark-mode fixes) and applies dark mode to the login page.",
    "maintainer" => "kontakt@tmiland.com",
    "www" => "https://github.com/tmiland-lab/pfsense-theme-lightdark",
    "abi" => $abi,
    "arch" => $abi,
    "prefix" => "/",
    "categories" => array("pfSense"),
    "licenses" => array("Apache-2.0"),
    "flatsize" => $flatsize,
    "deps" => (object) array(),
    "files" => (object) $files,
    "directories" => (object) $dirs,
    "scripts" => array(
        "post-install" => "+POST_INSTALL",
        "pre-deinstall" => "+PRE_DEINSTALL"
    )
);
echo json_encode($manifest, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
' "$STAGE" "$META" "$ABI" "$VERSION" "$NAME" "$ORIGIN")

echo "$MANIFEST" > "$META/+MANIFEST"

pkg create -m "$META" -r "$STAGE" -o "$OUT" >/dev/null

echo "=== Build complete: $OUT"
find "$OUT" -type f | sort
rm -rf "$WORK"
