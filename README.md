# Homebrew StevenBlack Hosts

Homebrew tap for installing a small updater that applies the StevenBlack hosts
file with the `fakenews` and `gambling` extensions.

The selected upstream URL is:

```text
https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts
```

That variant includes the StevenBlack base list, which covers malware/adware
blocking, plus the `fakenews` and `gambling` extensions.

## Why Formula, Not Cask

This project is packaged as a Homebrew formula because it installs a command-line
updater. A cask is better suited to macOS application or binary artifacts
declared with cask artifact stanzas. This tap follows Homebrew's tap and formula
documentation instead.

## Install

```sh
brew tap Potencial/stevenblack-hosts
brew install stevenblack-hosts
```

Or install it directly:

```sh
brew install Potencial/stevenblack-hosts/stevenblack-hosts
```

## Use

Preview the upstream file without changing `/private/etc/hosts`:

```sh
stevenblack-hosts-update --dry-run
```

Apply it manually:

```sh
sudo stevenblack-hosts-update
```

The command backs up the current hosts file to:

```text
/private/etc/hosts.backup.YYYYMMDD-HHMMSS
```

## LaunchDaemon

The formula also installs a LaunchDaemon template:

```text
$(brew --prefix)/opt/stevenblack-hosts/share/stevenblack-hosts/com.local.stevenblackhosts.plist
```

To schedule weekly root updates on Mondays at 09:00, copy that template to
`/Library/LaunchDaemons` and load it with `launchctl`:

```sh
sudo cp "$(brew --prefix)/opt/stevenblack-hosts/share/stevenblack-hosts/com.local.stevenblackhosts.plist" /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo chown root:wheel /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo chmod 644 /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.stevenblackhosts.plist
sudo launchctl enable system/com.local.stevenblackhosts
```

## Maintenance

Run:

```sh
brew update
brew upgrade stevenblack-hosts
```

The installed updater fetches the current upstream hosts list each time it runs.
The formula version only tracks changes to the packaging/updater script.

## Validation

```sh
brew audit --new --formula stevenblack-hosts
brew test stevenblack-hosts
```

Useful Homebrew documentation:

- https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
- https://docs.brew.sh/Formula-Cookbook
- https://docs.brew.sh/Acceptable-Formulae
- https://docs.brew.sh/Cask-Cookbook
