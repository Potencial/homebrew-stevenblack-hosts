class StevenblackHosts < Formula
  desc "Configurable updater for StevenBlack hosts variants"
  homepage "https://github.com/StevenBlack/hosts"
  url "https://github.com/StevenBlack/hosts/archive/9db3052ff028f5ee3e0d30c01d8dd8162395f575.tar.gz"
  version "2026.06.06-9db3052.2"
  sha256 "a52991840b3f6ca2d906ce8b91eba8e5f15a669e730d2a6a70b628955c009e1d"
  license "MIT"

  depends_on :macos

  def install
    (bin/"stevenblack-hosts-update").write <<~ZSH
      #!/bin/zsh
      set -euo pipefail

      FORMULA_VERSION="#{version}"
      DEFAULT_VARIANT="fakenews-gambling"
      HOSTS_FILE="${STEVENBLACK_HOSTS_FILE:-/private/etc/hosts}"
      CONFIG_FILE="${STEVENBLACK_HOSTS_CONFIG:-#{etc}/stevenblack-hosts.conf}"
      ALLOW_UNKNOWN_VARIANT="${STEVENBLACK_HOSTS_ALLOW_UNKNOWN_VARIANT:-0}"

      KNOWN_VARIANTS=(
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
      )

      usage() {
        /bin/cat <<'USAGE'
      Usage:
        stevenblack-hosts-update [--variant VARIANT] [--dry-run]
        stevenblack-hosts-update --set-variant VARIANT
        stevenblack-hosts-update --list-variants
        stevenblack-hosts-update --print-config
        stevenblack-hosts-update --print-url
        stevenblack-hosts-update --version

      Options:
        --variant VARIANT          Use a variant for this run.
        --set-variant VARIANT      Persist a variant in the config file.
        --hosts-file FILE          Write or preview a different hosts file.
        --config FILE              Read or write a different config file.
        --allow-unknown-variant    Try a future upstream variant name.
        --dry-run                  Download and validate without writing.

      Variants:
        base      StevenBlack base hosts file.
        <name>    Any supported directory under StevenBlack/hosts alternates/.

      Configuration:
        --set-variant writes the selected variant to the config file used by the
        LaunchDaemon. Use --config FILE to override the config path.

      Environment:
        STEVENBLACK_HOSTS_VARIANT
        STEVENBLACK_HOSTS_FILE
        STEVENBLACK_HOSTS_CONFIG
        STEVENBLACK_HOSTS_ALLOW_UNKNOWN_VARIANT=1

      Writing the system hosts file requires root.
      USAGE
      }

      trim_value() {
        local value="$1"
        value="${value%%#*}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value%\\"}"
        value="${value#\\"}"
        value="${value%\\'}"
        value="${value#\\'}"
        print -r -- "$value"
      }

      load_config() {
        [[ -f "$CONFIG_FILE" ]] || return 0

        local line key value
        while IFS= read -r line || [[ -n "$line" ]]; do
          line="$(trim_value "$line")"
          [[ -z "$line" || "$line" == \\#* || "$line" != *=* ]] && continue
          key="$(trim_value "${line%%=*}")"
          value="$(trim_value "${line#*=}")"

          case "$key" in
            VARIANT|variant|STEVENBLACK_HOSTS_VARIANT)
              [[ -n "${STEVENBLACK_HOSTS_VARIANT:-}" ]] || VARIANT="$value"
              ;;
            HOSTS_FILE|hosts_file|STEVENBLACK_HOSTS_FILE)
              [[ -n "${STEVENBLACK_HOSTS_FILE:-}" ]] || HOSTS_FILE="$value"
              ;;
          esac
        done < "$CONFIG_FILE"
      }

      is_known_variant() {
        local candidate="$1"
        local known
        for known in "${KNOWN_VARIANTS[@]}"; do
          [[ "$candidate" == "$known" ]] && return 0
        done
        return 1
      }

      normalize_variant() {
        local candidate="$1"
        case "$candidate" in
          ""|default|none)
            candidate="base"
            ;;
        esac

        if [[ ! "$candidate" =~ '^[a-z0-9][a-z0-9-]*$' ]]; then
          print -u2 -r -- "ERROR: invalid variant name: $candidate"
          exit 64
        fi

        if ! is_known_variant "$candidate" && [[ "$ALLOW_UNKNOWN_VARIANT" != "1" ]]; then
          print -u2 -r -- "ERROR: unknown variant: $candidate"
          print -u2 -r -- "Run: stevenblack-hosts-update --list-variants"
          print -u2 -r -- "Set STEVENBLACK_HOSTS_ALLOW_UNKNOWN_VARIANT=1 to try a future upstream variant."
          exit 64
        fi

        print -r -- "$candidate"
      }

      variant_url() {
        local candidate="$1"
        if [[ "$candidate" == "base" ]]; then
          print -r -- "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        else
          print -r -- "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/$candidate/hosts"
        fi
      }

      write_config() {
        local candidate="$1"
        local tmp dir
        candidate="$(normalize_variant "$candidate")"
        dir="$(/usr/bin/dirname "$CONFIG_FILE")"
        /bin/mkdir -p "$dir"
        tmp="$(/usr/bin/mktemp /tmp/stevenblack-hosts-config.XXXXXX)"
        {
          print -r -- "# StevenBlack hosts updater configuration"
          print -r -- "# Generated by stevenblack-hosts-update --set-variant"
          print -r -- "VARIANT=$candidate"
          print -r -- "HOSTS_FILE=$HOSTS_FILE"
        } > "$tmp"
        /usr/bin/install -m 0644 "$tmp" "$CONFIG_FILE"
        /bin/rm -f "$tmp"
        print -r -- "Configured variant '$candidate' in $CONFIG_FILE"
        print -r -- "URL: $(variant_url "$candidate")"
      }

      for ((i = 1; i <= $#; i++)); do
        if [[ "${argv[$i]}" == "--config" ]]; then
          (( i++ ))
          if (( i > $# )); then
            print -u2 -r -- "ERROR: --config requires a file path"
            exit 64
          fi
          CONFIG_FILE="${argv[$i]}"
        fi
      done

      VARIANT="${STEVENBLACK_HOSTS_VARIANT:-}"
      load_config
      VARIANT="${VARIANT:-$DEFAULT_VARIANT}"

      dry_run=0
      print_url=0
      print_config=0
      list_variants=0
      set_variant=""

      while (( $# > 0 )); do
        case "$1" in
          --variant)
            shift
            [[ $# -gt 0 ]] || { print -u2 -r -- "ERROR: --variant requires a value"; exit 64; }
            VARIANT="$1"
            ;;
          --set-variant)
            shift
            [[ $# -gt 0 ]] || { print -u2 -r -- "ERROR: --set-variant requires a value"; exit 64; }
            set_variant="$1"
            VARIANT="$1"
            ;;
          --hosts-file)
            shift
            [[ $# -gt 0 ]] || { print -u2 -r -- "ERROR: --hosts-file requires a path"; exit 64; }
            HOSTS_FILE="$1"
            ;;
          --config)
            shift
            [[ $# -gt 0 ]] || { print -u2 -r -- "ERROR: --config requires a file path"; exit 64; }
            ;;
          --allow-unknown-variant)
            ALLOW_UNKNOWN_VARIANT=1
            ;;
          --dry-run)
            dry_run=1
            ;;
          --print-url)
            print_url=1
            ;;
          --print-config)
            print_config=1
            ;;
          --list-variants)
            list_variants=1
            ;;
          --version)
            print -r -- "$FORMULA_VERSION"
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
        shift
      done

      VARIANT="$(normalize_variant "$VARIANT")"
      URL="$(variant_url "$VARIANT")"

      if [[ "$list_variants" == "1" ]]; then
        known=""
        for known in "${KNOWN_VARIANTS[@]}"; do
          print -r -- "$known"
        done
        exit 0
      fi

      if [[ -n "$set_variant" ]]; then
        write_config "$set_variant"
        exit 0
      fi

      if [[ "$print_url" == "1" ]]; then
        print -r -- "$URL"
        exit 0
      fi

      if [[ "$print_config" == "1" ]]; then
        print -r -- "config_file=$CONFIG_FILE"
        print -r -- "variant=$VARIANT"
        print -r -- "url=$URL"
        print -r -- "hosts_file=$HOSTS_FILE"
        exit 0
      fi

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

      if [[ "$dry_run" == "1" ]]; then
        /usr/bin/wc -l "$TMP"
        /usr/bin/shasum -a 256 "$TMP"
        print -r -- "Variant: $VARIANT"
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

      print -r -- "OK: StevenBlack hosts updated with variant '$VARIANT'."
    ZSH
    chmod 0755, bin/"stevenblack-hosts-update"

    (pkgshare/"stevenblack-hosts.conf.example").write <<~CONF
      # StevenBlack hosts updater configuration.
      # Run `stevenblack-hosts-update --list-variants` for supported values.
      VARIANT=fakenews-gambling
      HOSTS_FILE=/private/etc/hosts
    CONF

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

      Configure variant used by the LaunchDaemon:
        #{opt_bin}/stevenblack-hosts-update --list-variants
        #{opt_bin}/stevenblack-hosts-update --set-variant fakenews-gambling

      Dry-run check:
        #{opt_bin}/stevenblack-hosts-update --dry-run

      Config example:
        #{opt_pkgshare}/stevenblack-hosts.conf.example

      LaunchDaemon template:
        #{opt_pkgshare}/com.local.stevenblackhosts.plist

      The active system LaunchDaemon can be switched to the Homebrew-managed
      updater by copying that template to /Library/LaunchDaemons with sudo.
    EOS
  end

  test do
    assert_match "fakenews-gambling", shell_output("#{bin}/stevenblack-hosts-update --print-url")
    assert_match "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
                 shell_output("#{bin}/stevenblack-hosts-update --variant base --print-url")
    assert_match "fakenews-gambling-porn-social-only",
                 shell_output("#{bin}/stevenblack-hosts-update --list-variants")
    assert_match "variant=fakenews-gambling", shell_output("#{bin}/stevenblack-hosts-update --print-config")
    assert_match version.to_s, shell_output("#{bin}/stevenblack-hosts-update --version")
    assert_match "Dry run OK", shell_output("#{bin}/stevenblack-hosts-update --dry-run")
  end
end
