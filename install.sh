#!/usr/bin/env bash
# ================================================================
#  BugHunter Pro v4.0 — One-Shot Tool Installer
#  Made By KJI
#
#  Single command install:
#    curl -fsSL https://raw.githubusercontent.com/YOUR/REPO/main/install.sh | sudo bash
#  Or local:
#    chmod +x install.sh && sudo bash install.sh
#
#  Supports: Kali Linux 2023+, Ubuntu 20.04/22.04/24.04,
#            Debian 11/12, Parrot OS, BlackArch
# ================================================================

set -uo pipefail

# ── Colors ──────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; W='\033[1;37m'; DIM='\033[2m'; NC='\033[0m'

ok()    { echo -e "${G}[✓]${NC} $1"; }
info()  { echo -e "${C}[~]${NC} $1"; }
warn()  { echo -e "${Y}[!]${NC} $1"; }
err()   { echo -e "${R}[✗]${NC} $1"; }
die()   { echo -e "${R}[FATAL]${NC} $1"; exit 1; }
header(){ echo -e "\n${C}${W}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; \
          echo -e "${W}  $1${NC}"; \
          echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ── Counters ─────────────────────────────────────────────────────
PASS=0; FAIL=0; SKIP=0; TOTAL=0
FAILED_TOOLS=()

_track()  { TOTAL=$((TOTAL+1)); }
_pass()   { PASS=$((PASS+1));  ok   "$1"; }
_skip()   { SKIP=$((SKIP+1));  ok   "$1 ${DIM}(already installed)${NC}"; }
_fail()   { FAIL=$((FAIL+1));  warn "FAILED: $1"; FAILED_TOOLS+=("$1"); }

# ── Helpers ──────────────────────────────────────────────────────

# Run a command with a visible spinner
spin() {
    local pid=$! chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${C}%s${NC} " "${chars:$((i++ % ${#chars})):1}"
        sleep 0.1
    done
    printf "\r   \r"
}

# Portable apt-get wrapper (works with or without sudo)
APT() {
    if [ "$EUID" -eq 0 ]; then
        DEBIAN_FRONTEND=noninteractive apt-get "$@" -qq 2>/dev/null
    else
        DEBIAN_FRONTEND=noninteractive sudo apt-get "$@" -qq 2>/dev/null
    fi
}

# Detect package manager
detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null;    then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    else echo "unknown"; fi
}
PKG_MGR=$(detect_pkg_manager)

# Install a system package cross-distro
pkg_install() {
    local pkg="$1"
    case "$PKG_MGR" in
        apt)    APT install -y "$pkg" ;;
        dnf)    sudo dnf install -y -q "$pkg" 2>/dev/null ;;
        pacman) sudo pacman -S --noconfirm --quiet "$pkg" 2>/dev/null ;;
        *)      warn "Unknown package manager — install $pkg manually" ;;
    esac
}

# Install a Go binary tool
go_install() {
    local name="$1" pkg="$2"
    _track
    if command -v "$name" &>/dev/null; then
        _skip "$name"
        return 0
    fi
    info "Installing ${W}$name${NC}..."
    (
        go install "$pkg" 2>&1
    ) &>/tmp/bh_go_install.log &
    spin
    wait $!
    local rc=$?
    if [ $rc -eq 0 ] && (command -v "$name" &>/dev/null \
        || [ -f "${GOPATH:-$HOME/go}/bin/$name" ] \
        || [ -f "$HOME/go/bin/$name" ]); then
        _pass "$name"
    else
        _fail "$name"
        [[ -f /tmp/bh_go_install.log ]] && cat /tmp/bh_go_install.log | tail -3 | \
            sed "s/^/  ${DIM}/" | sed "s/$/${NC}/"
    fi
}

# ── Banner ───────────────────────────────────────────────────────
clear
echo -e "${C}"
cat << 'EOF'
 ██████╗ ██╗   ██╗ ██████╗ ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗
 ██╔══██╗██║   ██║██╔════╝ ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
 ██████╔╝██║   ██║██║  ███╗███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
 ██╔══██╗██║   ██║██║   ██║██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
 ██████╔╝╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
 ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
EOF
echo -e "${NC}${DIM}  Pro v4.0 · Tool Installer · Made By KJI${NC}"
echo -e "${C}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 0. Environment checks ────────────────────────────────────────
header "0 / 10  ENVIRONMENT CHECKS"

# OS detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="${NAME:-Unknown}"
    OS_ID="${ID:-unknown}"
else
    OS_NAME="Unknown"
    OS_ID="unknown"
fi
info "OS: ${W}$OS_NAME${NC}"

# Root / sudo check
if [ "$EUID" -eq 0 ]; then
    ok "Running as root"
    SUDO=""
else
    if sudo -n true 2>/dev/null; then
        ok "sudo available"
    else
        warn "Not root and sudo requires password — some installs may prompt"
    fi
    SUDO="sudo"
fi

# Architecture
ARCH=$(uname -m)
info "Architecture: ${W}$ARCH${NC}"
case "$ARCH" in
    x86_64)  GO_ARCH="amd64"; AQUA_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64"; AQUA_ARCH="arm64" ;;
    armv6l)  GO_ARCH="armv6l"; AQUA_ARCH="amd64" ;;
    *)       GO_ARCH="amd64"; AQUA_ARCH="amd64" ;;
esac

# Internet connectivity
if curl -fsSL --max-time 5 https://google.com &>/dev/null; then
    ok "Internet connectivity confirmed"
else
    die "No internet connection. Cannot continue."
fi

# Disk space check (need at least 3GB free)
FREE_KB=$(df / | awk 'NR==2{print $4}')
FREE_GB=$(echo "scale=1; $FREE_KB/1048576" | bc 2>/dev/null || echo "?")
if [ "$FREE_KB" -lt 3145728 ] 2>/dev/null; then
    warn "Low disk space: ${FREE_GB}GB free. Recommend 3GB+ for SecLists & tools."
else
    ok "Disk space: ${W}${FREE_GB}GB${NC} available"
fi

# ── 1. System prerequisites ──────────────────────────────────────
header "1 / 10  SYSTEM PREREQUISITES"

info "Updating package lists..."
case "$PKG_MGR" in
    apt)    APT update -y 2>/dev/null && ok "apt updated" || warn "apt update failed (continuing)" ;;
    dnf)    sudo dnf check-update -q 2>/dev/null; true ;;
    pacman) sudo pacman -Sy --noconfirm &>/dev/null && ok "pacman synced" || true ;;
esac

BASE_PKGS=(
    git curl wget unzip python3 python3-pip
    libpcap-dev build-essential dnsutils whois
    jq nmap masscan wafw00f sqlmap
    chromium-browser bc tar
)

# Distro-specific name fixes
declare -A PKG_ALIASES=(
    [chromium-browser]="chromium"          # Kali/Arch use 'chromium'
    [libpcap-dev]="libpcap-devel"          # RHEL/Fedora
)

for pkg in "${BASE_PKGS[@]}"; do
    _track
    # Check if already present
    if command -v "$pkg" &>/dev/null || dpkg -s "$pkg" &>/dev/null 2>/dev/null; then
        _skip "$pkg"
        continue
    fi
    info "Installing ${W}$pkg${NC}..."
    if pkg_install "$pkg" 2>/dev/null; then
        # Try alternate name if primary failed
        if ! command -v "$pkg" &>/dev/null && ! dpkg -s "$pkg" &>/dev/null 2>/dev/null; then
            alt="${PKG_ALIASES[$pkg]:-}"
            if [ -n "$alt" ] && pkg_install "$alt" 2>/dev/null; then
                _pass "$pkg (as $alt)"
            else
                _fail "$pkg"
            fi
        else
            _pass "$pkg"
        fi
    else
        _fail "$pkg"
    fi
done

# Ensure Python3 pip is available
if ! python3 -m pip --version &>/dev/null 2>&1; then
    info "Bootstrapping pip..."
    python3 -m ensurepip --upgrade 2>/dev/null || \
    curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3 2>/dev/null || \
    warn "pip bootstrap failed — Python packages may not install"
fi

# ── 2. Go installation ───────────────────────────────────────────
header "2 / 10  GO LANGUAGE RUNTIME"

GO_VERSION="1.23.4"  # Latest stable as of this script

install_go() {
    info "Installing Go ${GO_VERSION} (${GO_ARCH})..."
    local GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    local GO_URL="https://go.dev/dl/${GO_TAR}"
    local TMPFILE="/tmp/${GO_TAR}"

    # Download with retry
    local attempt=0
    while [ $attempt -lt 3 ]; do
        if curl -fsSL --progress-bar "$GO_URL" -o "$TMPFILE"; then
            break
        fi
        attempt=$((attempt+1))
        warn "Download attempt $attempt failed, retrying..."
        sleep 2
    done
    [ ! -f "$TMPFILE" ] && die "Failed to download Go after 3 attempts."

    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$TMPFILE" || die "Failed to extract Go tarball."
    rm -f "$TMPFILE"
    ok "Go ${GO_VERSION} installed to /usr/local/go"
}

if command -v go &>/dev/null; then
    CURRENT_GO=$(go version | grep -oP '\d+\.\d+(\.\d+)?' | head -1)
    CURRENT_MAJOR=$(echo "$CURRENT_GO" | cut -d. -f1)
    CURRENT_MINOR=$(echo "$CURRENT_GO" | cut -d. -f2)
    if [ "$CURRENT_MAJOR" -ge 1 ] && [ "$CURRENT_MINOR" -ge 21 ]; then
        ok "Go ${CURRENT_GO} already installed (meets requirement ≥1.21)"
    else
        warn "Go ${CURRENT_GO} is outdated. Upgrading to ${GO_VERSION}..."
        install_go
    fi
else
    install_go
fi

# Configure Go environment
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$PATH:/usr/local/go/bin:${GOPATH}/bin:$HOME/go/bin"

# Write to all shell RCs
for RC in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" /root/.bashrc /root/.zshrc; do
    [ -f "$RC" ] || continue
    if ! grep -q 'GOPATH' "$RC" 2>/dev/null; then
        cat >> "$RC" << 'GOBLOCK'

# ── BugHunter Pro — Go PATH ──────────────────
export GOPATH="${GOPATH:-$HOME/go}"
export PATH="$PATH:/usr/local/go/bin:${GOPATH}/bin"
# ─────────────────────────────────────────────
GOBLOCK
        ok "Go PATH written to $RC"
    fi
done

# Verify
go version &>/dev/null || die "Go installation verification failed."
ok "Go ready: $(go version)"

# ── 3. Go-based recon tools ──────────────────────────────────────
header "3 / 10  GO RECON TOOLS"
echo -e "${DIM}  This step takes 5-15 minutes on first install${NC}"
echo ""

# ── ProjectDiscovery suite ──
info "${Y}[ProjectDiscovery Suite]${NC}"
go_install subfinder          "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install httpx              "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install nuclei             "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
go_install naabu              "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
go_install dnsx               "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
go_install katana             "github.com/projectdiscovery/katana/cmd/katana@latest"
go_install asnmap             "github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
go_install interactsh-client  "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"

echo ""
# ── Tomnomnom suite ──
info "${Y}[Tomnomnom Suite]${NC}"
go_install assetfinder        "github.com/tomnomnom/assetfinder@latest"
go_install waybackurls        "github.com/tomnomnom/waybackurls@latest"
go_install unfurl             "github.com/tomnomnom/unfurl@latest"
go_install httprobe           "github.com/tomnomnom/httprobe@latest"
go_install gf                 "github.com/tomnomnom/gf@latest"
go_install anew               "github.com/tomnomnom/anew@latest"

echo ""
# ── Crawling & Fuzzing ──
info "${Y}[Crawling & Fuzzing]${NC}"
go_install ffuf               "github.com/ffuf/ffuf/v2@latest"
go_install hakrawler          "github.com/hakluke/hakrawler@latest"
go_install gau                "github.com/lc/gau/v2/cmd/gau@latest"
go_install gauplus            "github.com/bp0lr/gauplus@latest"
go_install kxss               "github.com/Emoe/kxss@latest"

echo ""
# ── Scanners ──
info "${Y}[Vulnerability Scanners]${NC}"
go_install dalfox             "github.com/hahwul/dalfox/v2@latest"
go_install subzy              "github.com/PentestPad/subzy@latest"
go_install jsluice            "github.com/BishopFox/jsluice/cmd/jsluice@latest"

echo ""
# ── Recon Misc ──
info "${Y}[Recon & Discovery]${NC}"
go_install getJS              "github.com/003random/getJS@latest"
go_install puredns            "github.com/d3mondev/puredns/v2@latest"
go_install gotator            "github.com/Josue87/gotator@latest"
go_install github-subdomains  "github.com/gwen001/github-subdomains@latest"
go_install gowitness          "github.com/sensepost/gowitness@latest"
go_install gitleaks           "github.com/zricethezav/gitleaks/v8@latest"

echo ""
# ── Amass (largest, installed last) ──
info "${Y}[Amass — large install, may take a few minutes]${NC}"
go_install amass              "github.com/owasp-amass/amass/v4/...@master"

# ── 4. Kiterunner ────────────────────────────────────────────────
header "4 / 10  KITERUNNER (API ROUTE DISCOVERY)"

_track
if command -v kr &>/dev/null; then
    _skip "kr (kiterunner)"
else
    info "Building kiterunner from source..."
    TMPKR=$(mktemp -d)
    (
        git clone --depth 1 https://github.com/assetnote/kiterunner.git "$TMPKR" 2>&1 && \
        cd "$TMPKR" && make build 2>&1 && \
        cp dist/kr "${GOPATH}/bin/kr"
    ) &>/tmp/bh_kr.log &
    spin
    wait $!
    if command -v kr &>/dev/null || [ -f "${GOPATH}/bin/kr" ]; then
        _pass "kr (kiterunner)"
    else
        warn "Source build failed — trying go install fallback..."
        if go install github.com/assetnote/kiterunner/cmd/kr@latest 2>/dev/null; then
            _pass "kr (kiterunner via go install)"
        else
            _fail "kr (kiterunner)"
            info "Manual: https://github.com/assetnote/kiterunner/releases"
        fi
    fi
    rm -rf "$TMPKR" 2>/dev/null
fi

# Download kiterunner wordlists
mkdir -p /opt/kiterunner 2>/dev/null || true
if [ ! -f /opt/kiterunner/routes-large.kite ]; then
    info "Downloading kiterunner routes wordlist (~50MB)..."
    (curl -fsSL "https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite" \
        -o /opt/kiterunner/routes-large.kite) &
    spin
    wait $!
    [ -f /opt/kiterunner/routes-large.kite ] && ok "Kiterunner routes wordlist downloaded" \
                                              || warn "Kiterunner wordlist download failed (non-critical)"
fi

# ── 5. Python tools ──────────────────────────────────────────────
header "5 / 10  PYTHON TOOLS"

# Try pip with --break-system-packages (needed on Ubuntu 23+/Kali)
pip_install() {
    local pkg="$1" name="${2:-$1}"
    _track
    if command -v "$name" &>/dev/null; then
        _skip "$name"
        return 0
    fi
    info "pip install ${W}$pkg${NC}..."
    if python3 -m pip install "$pkg" --break-system-packages -q 2>/dev/null || \
       python3 -m pip install "$pkg" -q 2>/dev/null || \
       pip3 install "$pkg" --break-system-packages -q 2>/dev/null || \
       pip3 install "$pkg" -q 2>/dev/null; then
        command -v "$name" &>/dev/null && _pass "$name" || _pass "$pkg (check PATH)"
    else
        _fail "$pkg"
    fi
}

pip_install arjun       arjun
pip_install py-altdns   altdns

# ── 6. TruffleHog ───────────────────────────────────────────────
header "6 / 10  TRUFFLEHOG (SECRET SCANNER)"

_track
if command -v trufflehog &>/dev/null; then
    _skip "trufflehog"
else
    info "Installing TruffleHog..."
    (
        curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh \
            | sh -s -- -b /usr/local/bin
    ) &>/tmp/bh_trufflehog.log &
    spin
    wait $!
    if command -v trufflehog &>/dev/null; then
        _pass "trufflehog"
    else
        # Fallback: snap
        if command -v snap &>/dev/null && snap install trufflehog 2>/dev/null; then
            _pass "trufflehog (via snap)"
        else
            _fail "trufflehog"
        fi
    fi
fi

# ── 7. Feroxbuster ──────────────────────────────────────────────
header "7 / 10  FEROXBUSTER (DIRECTORY FUZZER)"

_track
if command -v feroxbuster &>/dev/null; then
    _skip "feroxbuster"
else
    info "Installing feroxbuster..."
    FEROX_OK=false

    # Method 1: Official installer script (drops into /usr/local/bin)
    (curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
        | bash -s -- -b /usr/local/bin) &>/tmp/bh_ferox.log &
    spin
    wait $!
    command -v feroxbuster &>/dev/null && FEROX_OK=true

    # Method 2: apt (Kali)
    if [ "$FEROX_OK" = false ]; then
        pkg_install feroxbuster 2>/dev/null && \
        command -v feroxbuster &>/dev/null && FEROX_OK=true
    fi

    # Method 3: GitHub releases (latest binary)
    if [ "$FEROX_OK" = false ]; then
        info "Trying GitHub release binary..."
        FEROX_URL=$(curl -fsSL https://api.github.com/repos/epi052/feroxbuster/releases/latest \
            | grep -oP '"browser_download_url":\s*"\K[^"]+x86_64-linux[^"]*\.zip' | head -1)
        if [ -n "$FEROX_URL" ]; then
            curl -fsSL "$FEROX_URL" -o /tmp/ferox.zip && \
            unzip -o /tmp/ferox.zip feroxbuster -d /usr/local/bin/ 2>/dev/null && \
            chmod +x /usr/local/bin/feroxbuster && \
            command -v feroxbuster &>/dev/null && FEROX_OK=true
            rm -f /tmp/ferox.zip
        fi
    fi

    if [ "$FEROX_OK" = true ]; then
        _pass "feroxbuster"
    else
        _fail "feroxbuster"
    fi
fi

# ── 8. LinkFinder + aquatone ─────────────────────────────────────
header "8 / 10  LINKFINDER & AQUATONE"

# LinkFinder
_track
if [ -f /opt/LinkFinder/linkfinder.py ]; then
    _skip "LinkFinder"
else
    info "Installing LinkFinder..."
    rm -rf /opt/LinkFinder 2>/dev/null
    if git clone --depth 1 https://github.com/GerbenJavado/LinkFinder.git /opt/LinkFinder 2>/dev/null; then
        python3 -m pip install -r /opt/LinkFinder/requirements.txt \
            --break-system-packages -q 2>/dev/null || \
        pip3 install -r /opt/LinkFinder/requirements.txt \
            --break-system-packages -q 2>/dev/null || \
        pip3 install -r /opt/LinkFinder/requirements.txt -q 2>/dev/null || true
        chmod +x /opt/LinkFinder/linkfinder.py 2>/dev/null
        _pass "LinkFinder → /opt/LinkFinder/linkfinder.py"
    else
        _fail "LinkFinder"
    fi
fi

# aquatone
_track
if command -v aquatone &>/dev/null; then
    _skip "aquatone"
else
    info "Installing aquatone..."
    AQUA_VER="1.7.0"
    AQUA_FILE="aquatone_linux_${AQUA_ARCH}_${AQUA_VER}.zip"
    AQUA_URL="https://github.com/michenriksen/aquatone/releases/download/v${AQUA_VER}/${AQUA_FILE}"
    AQUA_OK=false

    if curl -fsSL "$AQUA_URL" -o /tmp/aquatone.zip 2>/dev/null; then
        mkdir -p /tmp/aquatone_ext
        unzip -o /tmp/aquatone.zip -d /tmp/aquatone_ext &>/dev/null
        if [ -f /tmp/aquatone_ext/aquatone ]; then
            mv /tmp/aquatone_ext/aquatone /usr/local/bin/aquatone && \
            chmod +x /usr/local/bin/aquatone && \
            AQUA_OK=true
        fi
        rm -rf /tmp/aquatone.zip /tmp/aquatone_ext
    fi

    if [ "$AQUA_OK" = true ]; then
        _pass "aquatone"
    else
        # gowitness already installed above — note it's the preferred replacement
        _fail "aquatone (gowitness is already installed as a preferred alternative)"
    fi
fi

# ── 9. Wordlists, resolvers & nuclei templates ───────────────────
header "9 / 10  WORDLISTS, RESOLVERS & TEMPLATES"

# SecLists
_track
if [ -d /opt/SecLists ] && [ "$(ls -A /opt/SecLists 2>/dev/null | wc -l)" -gt 5 ]; then
    _skip "SecLists (/opt/SecLists)"
else
    info "Cloning SecLists (~500MB — this takes a few minutes)..."
    rm -rf /opt/SecLists_tmp 2>/dev/null
    (
        git clone --depth 1 \
            https://github.com/danielmiessler/SecLists.git \
            /opt/SecLists_tmp && \
        mv /opt/SecLists_tmp /opt/SecLists
    ) &
    spin
    wait $!
    if [ -d /opt/SecLists ]; then
        _pass "SecLists → /opt/SecLists"
    else
        _fail "SecLists"
        info "Manual: git clone --depth 1 https://github.com/danielmiessler/SecLists.git /opt/SecLists"
    fi
fi

# DNS resolvers
_track
RESOLVERS_PATH="/opt/resolvers.txt"
if [ -f "$RESOLVERS_PATH" ] && [ "$(wc -l < "$RESOLVERS_PATH")" -gt 10 ]; then
    _skip "DNS resolvers ($RESOLVERS_PATH)"
else
    info "Downloading fresh DNS resolvers..."
    if curl -fsSL "https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt" \
        -o "$RESOLVERS_PATH"; then
        RESOLVER_COUNT=$(wc -l < "$RESOLVERS_PATH")
        _pass "DNS resolvers → ${RESOLVERS_PATH} (${RESOLVER_COUNT} servers)"
    else
        # Fallback: hardcode reliable public resolvers
        printf '8.8.8.8\n1.1.1.1\n9.9.9.9\n8.8.4.4\n1.0.0.1\n208.67.222.222\n' > "$RESOLVERS_PATH"
        warn "Used fallback resolvers (download failed). File: $RESOLVERS_PATH"
        _pass "DNS resolvers (fallback)"
    fi
fi

# Nuclei templates
_track
if command -v nuclei &>/dev/null; then
    info "Updating nuclei templates (this may take a minute)..."
    if nuclei -update-templates -silent 2>/dev/null; then
        _pass "nuclei templates"
    else
        warn "nuclei template update failed — run: nuclei -update-templates"
        _fail "nuclei templates"
    fi
else
    warn "nuclei not installed, skipping template update"
fi

# GF patterns (used by gf for param grepping)
_track
GF_DIR="$HOME/.gf"
if [ -d "$GF_DIR" ] && [ "$(ls -A "$GF_DIR" 2>/dev/null | wc -l)" -gt 5 ]; then
    _skip "gf patterns"
else
    info "Installing gf patterns..."
    mkdir -p "$GF_DIR"
    if git clone --depth 1 https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gf_patterns 2>/dev/null; then
        cp /tmp/gf_patterns/*.json "$GF_DIR/" 2>/dev/null
        rm -rf /tmp/gf_patterns
        _pass "gf patterns → $GF_DIR"
    else
        _fail "gf patterns"
    fi
fi

# ── 10. Final validation ─────────────────────────────────────────
header "10 / 10  VERIFICATION"

echo ""
info "Verifying all tools..."
echo ""

CRITICAL_TOOLS=(
    subfinder httpx nuclei dnsx katana
    gau waybackurls jsluice ffuf dalfox
    puredns subzy getJS interactsh-client
    nmap jq trufflehog gitleaks gowitness
)
OPTIONAL_TOOLS=(
    amass assetfinder naabu aquatone feroxbuster
    arjun altdns kr sqlmap wafw00f gf unfurl
    hakrawler kxss gauplus github-subdomains
)

ALL_CRIT_OK=true
echo -e "  ${W}Critical tools:${NC}"
for tool in "${CRITICAL_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null \
        || [ -f "${GOPATH:-$HOME/go}/bin/$tool" ] \
        || [ -f "$HOME/go/bin/$tool" ]; then
        printf "  ${G}✓${NC} %-28s" "$tool"
    else
        printf "  ${R}✗${NC} %-28s${R}[MISSING]${NC}" "$tool"
        ALL_CRIT_OK=false
    fi
    # newline every 2 tools
    [ $(( (CRITICAL_TOOLS[@]+1) % 2 )) -eq 0 ] && echo "" || echo ""
done

echo ""
echo -e "  ${W}Optional tools:${NC}"
for tool in "${OPTIONAL_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null \
        || [ -f "${GOPATH:-$HOME/go}/bin/$tool" ] \
        || [ -f "$HOME/go/bin/$tool" ]; then
        printf "  ${G}✓${NC} %-28s\n" "$tool"
    else
        printf "  ${DIM}○${NC} %-28s${DIM}[not installed]${NC}\n" "$tool"
    fi
done

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${W}  INSTALLATION SUMMARY${NC}"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${G}Installed : ${PASS}${NC}"
echo -e "  ${C}Skipped   : ${SKIP} (already present)${NC}"
if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
    echo -e "  ${R}Failed    : ${FAIL}${NC}"
    echo -e "  ${Y}Failed tools (you can install these manually):${NC}"
    for t in "${FAILED_TOOLS[@]}"; do
        echo -e "    ${R}→${NC} $t"
    done
else
    echo -e "  ${G}Failed    : 0 — perfect install!${NC}"
fi
echo -e "  ${DIM}Total steps: ${TOTAL}${NC}"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$ALL_CRIT_OK" = true ]; then
    echo -e "${G}  ✓ All critical tools verified. You're ready to hunt!${NC}"
else
    echo -e "${Y}  ⚠  Some critical tools are missing.${NC}"
    echo -e "${DIM}  Tip: Close terminal, reopen, and check again — PATH may need reload.${NC}"
    echo -e "${DIM}  Or run: source ~/.bashrc && python3 bughunter.py --check-tools${NC}"
fi

echo ""
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${W}  QUICK START${NC}"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "  ${G}# Reload PATH (important after first install)${NC}"
echo -e "  source ~/.bashrc"
echo -e ""
echo -e "  ${G}# Verify all tools are found${NC}"
echo -e "  python3 bughunter.py --check-tools"
echo -e ""
echo -e "  ${G}# Hunt a single target${NC}"
echo -e "  python3 bughunter.py example.com"
echo -e ""
echo -e "  ${G}# Hunt with authenticated session${NC}"
echo -e "  python3 bughunter.py example.com --cookie \"session=abc123\""
echo -e ""
echo -e "  ${G}# Hunt from a scope file${NC}"
echo -e "  python3 bughunter.py --scope scope.txt"
echo -e ""
echo -e "  ${G}# Run only JS + XSS + SSRF + IDOR phases${NC}"
echo -e "  python3 bughunter.py example.com --phase js"
echo -e "  python3 bughunter.py example.com --phase xss"
echo -e "  python3 bughunter.py example.com --phase ssrf"
echo -e "  python3 bughunter.py example.com --phase idor"
echo -e ""
echo -e "  ${Y}# Optional — set GitHub token for deeper secret scanning:${NC}"
echo -e "  export GITHUB_TOKEN='ghp_your_token_here'"
echo -e "  echo 'export GITHUB_TOKEN=ghp_...' >> ~/.bashrc"
echo -e ""
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${G}  Done! Run: source ~/.bashrc then python3 bughunter.py --help${NC}"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""