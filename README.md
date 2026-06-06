# Homebrew StevenBlack Hosts

Homebrew tap for a macOS updater that applies configurable
[StevenBlack/hosts](https://github.com/StevenBlack/hosts) variants to
`/private/etc/hosts`.

The default variant is `fakenews-gambling`. That preserves the original purpose
of this tap: StevenBlack base blocking, which includes malware/adware blocking,
plus the `fakenews` and `gambling` extensions.

## Install

```sh
brew tap Potencial/stevenblack-hosts
brew install stevenblack-hosts
```

Direct install also works:

```sh
brew install Potencial/stevenblack-hosts/stevenblack-hosts
```

## Quick Start

Preview the configured upstream file without changing `/private/etc/hosts`:

```sh
stevenblack-hosts-update --dry-run
```

Apply the configured variant:

```sh
sudo stevenblack-hosts-update
```

The updater backs up the current hosts file before replacing it:

```text
/private/etc/hosts.backup.YYYYMMDD-HHMMSS
```

## Configure Variants

List every supported StevenBlack variant:

```sh
stevenblack-hosts-update --list-variants
```

Run a variant one time:

```sh
stevenblack-hosts-update --variant fakenews-gambling-porn-social --dry-run
sudo stevenblack-hosts-update --variant fakenews-gambling-porn-social
```

Persist a variant for manual runs and the LaunchDaemon:

```sh
stevenblack-hosts-update --set-variant fakenews-gambling-porn-social
```

Restore this tap's default:

```sh
stevenblack-hosts-update --set-variant fakenews-gambling
```

Inspect the active configuration:

```sh
stevenblack-hosts-update --print-config
stevenblack-hosts-update --print-url
stevenblack-hosts-update --version
```

The default config file is:

```text
$(brew --prefix)/etc/stevenblack-hosts.conf
```

Configuration precedence is:

1. command-line options
2. environment variables
3. config file
4. built-in default `fakenews-gambling`

Environment variables:

```sh
STEVENBLACK_HOSTS_VARIANT=social stevenblack-hosts-update --dry-run
STEVENBLACK_HOSTS_FILE=/tmp/hosts stevenblack-hosts-update --dry-run
STEVENBLACK_HOSTS_CONFIG=/path/to/config stevenblack-hosts-update --print-config
STEVENBLACK_HOSTS_ALLOW_UNKNOWN_VARIANT=1 stevenblack-hosts-update --variant future-variant --dry-run
```

## Variant Names

`base` maps to the default StevenBlack hosts file:

```text
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

All other variants map to:

```text
https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/<variant>/hosts
```

Current StevenBlack extensions are `fakenews`, `gambling`, `porn`, and `social`.
Variants without `-only` include the StevenBlack base list. Variants ending in
`-only` contain only the selected extension categories.

Supported variants:

```text
base
fakenews
fakenews-gambling
fakenews-gambling-only
fakenews-gambling-porn
fakenews-gambling-porn-only
fakenews-gambling-porn-social
fakenews-gambling-porn-social-only
fakenews-gambling-social
fakenews-gambling-social-only
fakenews-only
fakenews-porn
fakenews-porn-only
fakenews-porn-social
fakenews-porn-social-only
fakenews-social
fakenews-social-only
gambling
gambling-only
gambling-porn
gambling-porn-only
gambling-porn-social
gambling-porn-social-only
gambling-social
gambling-social-only
porn
porn-only
porn-social
porn-social-only
social
social-only
```

## LaunchDaemon

The formula installs a LaunchDaemon template:

```text
$(brew --prefix)/opt/stevenblack-hosts/share/stevenblack-hosts/com.local.stevenblackhosts.plist
```

Install it as a root LaunchDaemon for weekly updates on Mondays at 09:00:

```sh
sudo cp "$(brew --prefix)/opt/stevenblack-hosts/share/stevenblack-hosts/com.local.stevenblackhosts.plist" /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo chown root:wheel /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo chmod 644 /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo launchctl enable system/com.local.stevenblackhosts
```

After changing the persisted variant, trigger a run immediately:

```sh
sudo launchctl kickstart -k system/com.local.stevenblackhosts
```

Logs are written to:

```text
/var/log/stevenblackhosts.log
/var/log/stevenblackhosts.err
```

## Migrate From hblock

If `hblock` is installed and you want this tap to own `/private/etc/hosts`:

```sh
brew uninstall hblock
brew install Potencial/stevenblack-hosts/stevenblack-hosts
stevenblack-hosts-update --set-variant fakenews-gambling
sudo stevenblack-hosts-update
```

Then install or refresh the LaunchDaemon template from the previous section.

## Maintenance

Upgrade the tap formula:

```sh
brew update
brew upgrade stevenblack-hosts
```

The formula version tracks packaging and updater-script changes. The installed
updater downloads the current StevenBlack hosts file each time it runs, so your
hosts data stays current even when the formula version has not changed.

Persisted config in `$(brew --prefix)/etc/stevenblack-hosts.conf` is preserved
across upgrades.

## Homebrew/Core

This tap is intentionally different from a formula suitable for
`Homebrew/homebrew-core`.

This tap:

- downloads the selected variant at runtime
- writes `/private/etc/hosts` when run with `sudo`
- includes a root LaunchDaemon template for scheduled updates
- is macOS-only

A formula for `homebrew/core` should be more conservative: it should install
versioned upstream data and helper commands, and should not write `/etc/hosts`,
install a background updater, or fetch from `master` at runtime.

## Development

Validate local changes:

```sh
brew audit --new --formula stevenblack-hosts
brew style Formula/stevenblack-hosts.rb
brew test stevenblack-hosts
```

Useful Homebrew documentation:

- https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
- https://docs.brew.sh/Formula-Cookbook
- https://docs.brew.sh/Acceptable-Formulae
- https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request
