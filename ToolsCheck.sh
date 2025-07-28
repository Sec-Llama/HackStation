#!/usr/bin/env bash
#
# ToolsCheck.sh
#
# This script checks the presence and version of a number of security tools
# grouped by function (Essentials, Recon & OSINT, Web Hacking, Password
# Cracking & Bruteforce, Network Analysis & Post‑Exploitation, Utilities
# & Scripting, Advanced Tools and Optional Extras).  It prints a tidy
# overview indicating whether each tool is installed on the system and,
# when possible, displays the version.  Tools that are not available
# simply report "not installed".

set -euo pipefail

# ----------------------------------------------------------------------
# Group definitions
# ----------------------------------------------------------------------

# Array of group names in the order they should be displayed
GROUP_NAMES=(
  "Essentials"
  "Recon_OSINT"
  "Web_Hacking"
  "Password_Cracking"
  "Network_Analysis"
  "Utilities"
  "Advanced_Tools"
  "Optional_Extras"
)

# Associative array mapping group names to a space‑separated list of
# tools.  Tools are specified by their package or command name; some
# advanced tools are represented by the command they provide.
declare -A GROUP_TOOLS
GROUP_TOOLS[Essentials]="openssh-server tmux screen htop curl wget git unzip p7zip-full python3 python3-pip"
GROUP_TOOLS[Recon_OSINT]="nmap masscan whois dnsutils amass theharvester sublist3r"
GROUP_TOOLS[Web_Hacking]="ffuf dirsearch nikto sqlmap wpscan whatweb"
GROUP_TOOLS[Password_Cracking]="hydra medusa john hashcat"
GROUP_TOOLS[Network_Analysis]="tcpdump tshark bettercap netcat-traditional socat"
GROUP_TOOLS[Utilities]="jq xxd base64 tr sed awk"
GROUP_TOOLS[Advanced_Tools]="pipx crackmapexec impacket httpx sublist3r"
GROUP_TOOLS[Optional_Extras]="autossh sshuttle ngrok SecLists PayloadsAllTheThings"

# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------

# Try to determine whether a binary exists in the PATH.  For some tools
# the package name differs from the actual command; an optional second
# argument allows you to override the command name.
command_exists() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1
}

# Attempt to extract a version string for a given command.  Different
# tools expose version information in different ways, so this helper
# cycles through a set of common flags ("--version", "-V", "-v", "version").
# If none succeed, it falls back to an empty string.  Output is
# trimmed to the first line.
get_command_version() {
  local cmd="$1"
  local ver=""
  # Try common version flags in order
  for flag in "--version" "-V" "-v" "version"; do
    if "$cmd" "$flag" >/dev/null 2>&1; then
      ver=$("$cmd" "$flag" 2>&1 | head -n 1)
      break
    fi
  done
  printf "%s" "$ver"
}

# Check if a Debian package is installed.  Returns 0 if installed, 1
# otherwise.  Uses dpkg-query which is present on all Debian‑based
# systems.  Version information is fetched separately.
package_installed() {
  local pkg="$1"
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

# Fetch the version of an installed Debian package.  If not
# installed, prints an empty string.
get_package_version() {
  local pkg="$1"
  if package_installed "$pkg"; then
    dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null
  else
    printf ""
  fi
}

# Determine the default command associated with a given tool name.
# For most packages the command is the same as the package name, but
# several tools provide differently named executables.  This mapping
# allows us to check the correct command when verifying installation.
get_tool_command() {
  local tool="$1"
  case "$tool" in
    openssh-server) echo "sshd" ;;
    p7zip-full) echo "7z" ;;
    python3-pip) echo "pip3" ;;
    dnsutils) echo "dig" ;;
    theharvester) echo "theHarvester" ;;
    netcat-traditional) echo "nc" ;;
    crackmapexec) echo "cme" ;;
    sublist3r) echo "sublist3r" ;;
    impacket)
      # Impacket is a Python library; check for impacket‑version tool or fall back to pip show
      if command_exists "impacket-smbclient"; then
        echo "impacket-smbclient"
      else
        echo "python3" # fallback check performed separately
      fi
      ;;
    httpx) echo "httpx" ;;
    ngrok) echo "ngrok" ;;
    SecLists) echo "SecLists" ;;
    PayloadsAllTheThings) echo "PayloadsAllTheThings" ;;
    *) echo "$tool" ;;
  esac
}

# Print the installation status for a single tool.  Attempts to use
# dpkg-query for package names and command checks for everything else.
print_tool_status() {
  local tool="$1"
  local cmd
  cmd=$(get_tool_command "$tool")
  local status="not installed"
  local version=""

  # Handle optional extras that are directories (SecLists and PayloadsAllTheThings)
  if [[ "$tool" == "SecLists" ]]; then
    if [[ -d "/opt/SecLists" || -d "/usr/share/seclists" ]]; then
      status="installed"
      version="(directory present)"
    else
      status="not installed"
    fi
    printf "  %-22s %s %s\n" "$tool" "$status" "$version"
    return
  fi
  if [[ "$tool" == "PayloadsAllTheThings" ]]; then
    if [[ -d "/opt/PayloadsAllTheThings" || -d "/usr/share/PayloadsAllTheThings" ]]; then
      status="installed"
      version="(directory present)"
    else
      status="not installed"
    fi
    printf "  %-22s %s %s\n" "$tool" "$status" "$version"
    return
  fi

  # Check for package installation via dpkg for known packages
  if package_installed "$tool"; then
    status="installed"
    version=$(get_package_version "$tool")
  elif command_exists "$cmd"; then
    status="installed"
    # Special case for impacket: version via pip show
    if [[ "$tool" == "impacket" ]]; then
      version=$(python3 - <<'PY'
import pkg_resources, sys
try:
    ver = pkg_resources.get_distribution('impacket').version
    print(ver)
except Exception:
    pass
PY
)
    elif [[ "$tool" == "sublist3r" ]]; then
      # Sublist3r prints version via __version__ variable
      version=$(python3 - <<'PY'
try:
    import sublist3r
    print(getattr(sublist3r, '__version__', ''))
except Exception:
    pass
PY
)
    else
      version=$(get_command_version "$cmd")
    fi
  else
    status="not installed"
  fi

  # If version is empty but installed, annotate as unknown
  if [[ -n "$version" ]]; then
    printf "  %-22s installed (%s)\n" "$tool" "$version"
  else
    printf "  %-22s %s\n" "$tool" "$status"
  fi
}

# ----------------------------------------------------------------------
# Main logic
# ----------------------------------------------------------------------

echo "\nTool Installation Status Report\n--------------------------------"
for group in "${GROUP_NAMES[@]}"; do
  printf "\n%s:\n" "$group"
  # Split the list of tools into an array
  read -ra tools <<< "${GROUP_TOOLS[$group]}"
  for tool in "${tools[@]}"; do
    print_tool_status "$tool"
  done
done
