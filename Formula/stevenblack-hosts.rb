class StevenblackHosts < Formula
  desc "Updater for StevenBlack hosts with fakenews and gambling extensions"
  homepage "https://github.com/StevenBlack/hosts"
  url "https://github.com/StevenBlack/hosts/archive/9db3052ff028f5ee3e0d30c01d8dd8162395f575.tar.gz"
  version "2026.06.06-9db3052"
  sha256 "a52991840b3f6ca2d906ce8b91eba8e5f15a669e730d2a6a70b628955c009e1d"
  license "MIT"

  def install
    (bin/"stevenblack-hosts-update").write <<~ZSH
      #!/bin/zsh
      set -euo pipefail

      DEFAULT_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts"
      HOSTS_FILE="${STEVENBLACK_HOSTS_FILE:-/private/etc/hosts}"

      usage() {
        /bin/cat <<'USAGE'
      Usage:
        stevenblack-hosts-update
        stevenblack-hosts-update --dry-run
        stevenblack-hosts-update --print-url

      Updates /private/etc/hosts with StevenBlack base malware/adware blocking plus
      the fakenews and gambling extensions. Writing the system hosts file requires root.
      USAGE
      }

      dry_run=0
      case "${1:-}" in
        "")
          ;;
        --dry-run)
          dry_run=1
          ;;
        --print-url)
          print -r -- "${STEVENBLACK_HOSTS_URL:-$DEFAULT_URL}"
          exit 0
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        *)
          print -u2 -r -- "ERROR: unsupported argument: $1"
          usage >&2
          exit 64
          ;;
      esac

      URL="${STEVENBLACK_HOSTS_URL:-$DEFAULT_URL}"
      TMP="$(/usr/bin/mktemp /tmp/stevenblack-hosts.XXXXXX)"

      cleanup() {
        /bin/rm -f "$TMP"
      }
      trap cleanup EXIT

      print -r -- "Downloading StevenBlack hosts from $URL"
      /usr/bin/curl -fsSL "$URL" -o "$TMP"

      if ! /usr/bin/grep -q "StevenBlack/hosts" "$TMP"; then
        print -u2 -r -- "ERROR: downloaded file does not look like StevenBlack hosts"
        exit 65
      fi

      if ! /usr/bin/grep -q "Extensions added to this file: fakenews, gambling" "$TMP"; then
        print -u2 -r -- "ERROR: downloaded file is not the fakenews + gambling variant"
        exit 66
      fi

      if [[ "$dry_run" == "1" ]]; then
        /usr/bin/wc -l "$TMP"
        /usr/bin/shasum -a 256 "$TMP"
        print -r -- "Dry run OK; $HOSTS_FILE was not changed."
        exit 0
      fi

      if [[ "$(/usr/bin/id -u)" != "0" ]]; then
        print -u2 -r -- "ERROR: run with sudo to update $HOSTS_FILE"
        exit 77
      fi

      BACKUP="${HOSTS_FILE}.backup.$(/bin/date +%Y%m%d-%H%M%S)"
      print -r -- "Backing up $HOSTS_FILE to $BACKUP"
      /bin/cp "$HOSTS_FILE" "$BACKUP"

      print -r -- "Installing new $HOSTS_FILE"
      /bin/cp "$TMP" "$HOSTS_FILE"
      /usr/sbin/chown root:wheel "$HOSTS_FILE"
      /bin/chmod 644 "$HOSTS_FILE"

      print -r -- "Flushing DNS cache"
      /usr/bin/dscacheutil -flushcache || true
      /usr/bin/killall -HUP mDNSResponder || true

      print -r -- "OK: StevenBlack hosts updated with base malware/adware + fakenews + gambling."
    ZSH
    chmod 0755, bin/"stevenblack-hosts-update"

    (pkgshare/"com.local.stevenblackhosts.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.local.stevenblackhosts</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/stevenblack-hosts-update</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>StartCalendarInterval</key>
        <dict>
          <key>Weekday</key>
          <integer>1</integer>
          <key>Hour</key>
          <integer>9</integer>
          <key>Minute</key>
          <integer>0</integer>
        </dict>
        <key>StandardOutPath</key>
        <string>/var/log/stevenblackhosts.log</string>
        <key>StandardErrorPath</key>
        <string>/var/log/stevenblackhosts.err</string>
      </dict>
      </plist>
    XML
  end

  def caveats
    <<~EOS
      Manual update:
        sudo #{opt_bin}/stevenblack-hosts-update

      Dry-run check:
        #{opt_bin}/stevenblack-hosts-update --dry-run

      LaunchDaemon template:
        #{opt_pkgshare}/com.local.stevenblackhosts.plist

      The active system LaunchDaemon can be switched to the Homebrew-managed
      updater by copying that template to /Library/LaunchDaemons with sudo.
    EOS
  end

  test do
    assert_match "fakenews-gambling", shell_output("#{bin}/stevenblack-hosts-update --print-url")
    assert_match "Dry run OK", shell_output("#{bin}/stevenblack-hosts-update --dry-run")
  end
end
