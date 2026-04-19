<div align="center">

```
██████╗ ██╗   ██╗ ██████╗ ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗
██╔══██╗██║   ██║██╔════╝ ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
██████╔╝██║   ██║██║  ███╗███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
██╔══██╗██║   ██║██║   ██║██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
██████╔╝╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
```

# BugHunter Pro v4.0

**A full-pipeline, real-recon bug bounty automation tool.**  
From passive subdomain enumeration all the way to active XSS, SSRF, and IDOR testing — in one command.

*Made by IK*

![Platform](https://img.shields.io/badge/platform-Linux-blue)
![Python](https://img.shields.io/badge/python-3.8%2B-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

---

## Table of Contents

- [What It Does](#what-it-does)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage & Options](#usage--options)
- [All Phases Explained](#all-phases-explained)
- [JS Recon & Provenance Tracking](#js-recon--provenance-tracking)
- [XSS Testing](#xss-testing)
- [SSRF Testing](#ssrf-testing)
- [IDOR Testing](#idor-testing)
- [Output Structure](#output-structure)
- [Scope Files](#scope-files)
- [Tips & Tricks](#tips--tricks)
- [Tool Reference](#tool-reference)

---

## What It Does

BugHunter Pro is a **16-phase** automated reconnaissance and vulnerability testing pipeline. You give it a domain — it does everything:

| Category | What it finds |
|---|---|
| **Subdomains** | Passive enum, DNS brute-force, permutations, cert transparency |
| **Live hosts** | HTTP probing, tech fingerprinting, WAF detection, screenshots |
| **Ports** | Fast port scanning with naabu/masscan/nmap |
| **Content** | Deep crawl, JS file harvesting, wayback machine, GAU |
| **Parameters** | SSRF-prone, redirect-prone, injection-prone param classification |
| **JavaScript** | Deep JS recon with full provenance (which tool, which JS file, which website) |
| **Secrets** | 60+ regex patterns + entropy analysis across all JS files |
| **GraphQL** | Endpoint discovery + introspection leak detection |
| **API Fuzzing** | ffuf on API paths, HTTP method fuzzing, Swagger/OpenAPI detection |
| **XSS** | dalfox + manual payload probing + DOM sink scanning in JS |
| **SSRF** | 19 payloads, OOB via interactsh, AWS/GCP/Azure metadata targets |
| **IDOR** | Numeric ID enumeration, REST path ID walking, UUID/GUID extraction from JS |
| **Vulns** | nuclei CVEs, misconfigs, default creds, CORS, CRLF, open redirects |
| **Cloud** | S3, GCP Storage, Azure Blob, Firebase, DigitalOcean Spaces |
| **GitHub** | TruffleHog, gitleaks, dork generation |
| **Dorks** | 100+ Google/GitHub dorks pre-generated for the target |

---

## Requirements

- **OS:** Kali Linux 2023+, Ubuntu 20.04/22.04/24.04, Debian 11/12, Parrot OS
- **Python:** 3.8 or higher
- **Go:** 1.21+ (auto-installed by the installer)
- **RAM:** 2GB minimum, 4GB recommended
- **Disk:** 3GB free (mostly for SecLists wordlists)
- **Network:** Internet access required

---

## Installation

### One command — installs everything

```bash
git clone https://github.com/YOUR_USERNAME/bughunter-pro.git
cd bughunter-pro
chmod +x install.sh
sudo bash install.sh
```

That's it. The installer handles:

- Go 1.23 (downloads and installs if missing or outdated)
- All 30+ Go-based recon tools (subfinder, httpx, nuclei, dalfox, etc.)
- System packages (nmap, masscan, jq, sqlmap, wafw00f, chromium)
- Python packages (arjun, altdns)
- TruffleHog secret scanner
- Feroxbuster directory fuzzer
- LinkFinder JS endpoint extractor
- aquatone / gowitness for screenshots
- SecLists wordlists → `/opt/SecLists/`
- DNS resolvers → `/opt/resolvers.txt`
- Nuclei templates (auto-updated)
- GF patterns for param grepping

After install, reload your shell:

```bash
source ~/.bashrc
```

Verify everything installed correctly:

```bash
python3 bughunter.py --check-tools
```

### Install from a one-liner (if hosted)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/bughunter-pro/main/install.sh | sudo bash
```

### Manual install (if you prefer)

<details>
<summary>Click to expand manual install steps</summary>

**Step 1 — Go:**
```bash
wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
source ~/.bashrc
```

**Step 2 — Go tools:**
```bash
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/unfurl@latest
go install github.com/tomnomnom/gf@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/hahwul/dalfox/v2@latest
go install github.com/PentestPad/subzy@latest
go install github.com/BishopFox/jsluice/cmd/jsluice@latest
go install github.com/003random/getJS@latest
go install github.com/d3mondev/puredns/v2@latest
go install github.com/owasp-amass/amass/v4/...@master
go install github.com/zricethezav/gitleaks/v8@latest
go install github.com/sensepost/gowitness@latest
```

**Step 3 — System packages:**
```bash
sudo apt update
sudo apt install -y nmap masscan jq wafw00f sqlmap chromium-browser python3-pip
```

**Step 4 — Python:**
```bash
pip3 install arjun py-altdns --break-system-packages
```

**Step 5 — TruffleHog:**
```bash
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sudo sh -s -- -b /usr/local/bin
```

**Step 6 — SecLists + resolvers:**
```bash
sudo git clone --depth 1 https://github.com/danielmiessler/SecLists.git /opt/SecLists
sudo wget https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt -O /opt/resolvers.txt
nuclei -update-templates
```

</details>

---

## Quick Start

```bash
# Scan a single domain (runs all 16 phases)
python3 bughunter.py example.com

# Scan with an authenticated session cookie
python3 bughunter.py example.com --cookie "session=abc123; auth=xyz"

# Scan multiple domains at once
python3 bughunter.py example.com api.example.com staging.example.com

# Scan from a scope file
python3 bughunter.py --scope scope.txt

# Merge all scope targets into one output folder
python3 bughunter.py --scope scope.txt --merge
```

---

## Usage & Options

```
python3 bughunter.py <domain> [options]
python3 bughunter.py --scope scope.txt [options]
```

| Argument | Description |
|---|---|
| `target` | One or more target domains (`example.com api.example.com`) |
| `-s / --scope` | Path to a scope file (one domain per line) OR comma-separated domains |
| `--exclude` | Comma-separated domains to exclude from scope |
| `--cookie` | Session cookie string for authenticated crawling/testing |
| `--phase` | Run only a specific phase (see list below) |
| `--output` | Custom output directory name |
| `--threads` | Thread count for parallel operations (default: 20) |
| `--merge` | When using `--scope`, merge all results into one folder |
| `--check-tools` | Check which required/optional tools are installed |
| `--install` | Print manual install instructions for all tools |

### Running a specific phase

```bash
python3 bughunter.py example.com --phase <phase_name>
```

| Phase | What it runs |
|---|---|
| `all` | Everything (default) |
| `subs` | Passive subdomain enumeration only |
| `dns` | DNS resolution + brute-force |
| `http` | HTTP probing + tech fingerprinting |
| `ports` | Port scanning |
| `content` | Crawling + URL collection |
| `params` | Parameter discovery + classification |
| `js` | Full JavaScript deep recon + secret scanning |
| `graphql` | GraphQL endpoint discovery + introspection |
| `apifuzz` | API path fuzzing with ffuf |
| `dorks` | Generate Google/GitHub dorks |
| `xss` | Active XSS testing (dalfox + manual + DOM sinks) |
| `ssrf` | Active SSRF testing with OOB callbacks |
| `idor` | IDOR testing (ID enumeration + UUID extraction) |
| `vulns` | Full nuclei scan + CORS + CRLF + redirects |
| `cloud` | Cloud asset discovery (S3, GCS, Azure, Firebase) |
| `github` | GitHub secret scanning + dork generation |

---

## All Phases Explained

### Phase 1 — Passive Subdomain Enumeration
Collects subdomains without touching the target. Sources: subfinder (all passive sources), assetfinder, amass passive, crt.sh certificate transparency, GAU, waybackurls, github-subdomains. All results merged and deduplicated into `subdomains/all_passive.txt`.

### Phase 2 — DNS Resolution + Active Bruting
Resolves all passive subdomains using puredns + resolvers. Runs puredns bruteforce against `dns-Jhaddix.txt` (from SecLists). Runs altdns + gotator for permutations. Collects A, AAAA, CNAME, MX records via dnsx. Automatically detects dangling CNAME takeover candidates (40+ services checked).

### Phase 3 — HTTP Probing + Fingerprinting
Probes all resolved subdomains with httpx: status code, title, web server, tech stack, IP, CDN detection. Takes screenshots via gowitness or aquatone. Detects WAFs. Collects 403 hosts for bypass testing.

### Phase 4 — Port Scanning
Fast scanning with naabu (top ports). Optional nmap service detection. Optional masscan for speed. Results in `ports/`.

### Phase 5 — Content Discovery + URL Collection
Deep crawl with katana (JS rendering enabled). Collects historical URLs via GAU and waybackurls. Directory fuzzing with ffuf and feroxbuster. Kiterunner API route discovery. Sensitive file probing (`.env`, `.git`, backup files, config files, etc.).

### Phase 6 — Parameter Discovery
Arjun parameter mining on live endpoints. Classifies all parameters into categories: injection-prone, SSRF-prone, redirect-prone, XSS-prone. Results in `params/`.

### Phase 7 — JavaScript Deep Recon
See [JS Recon section](#js-recon--provenance-tracking) below.

### Phase 8 — GraphQL Detection
Probes 15+ GraphQL paths on all live hosts. Fires introspection query. Dumps schema types and flags sensitive ones (user, admin, auth, token, payment). Runs nuclei GraphQL templates.

### Phase 9 — API Fuzzing
Probes 20+ common API base paths. ffuf fuzzing on `/api/FUZZ` and `/FUZZ`. HTTP method fuzzing (PUT, DELETE, PATCH, OPTIONS) on discovered endpoints. Flags Swagger/OpenAPI specs.

### Phase 10 — Dork Generation
Generates 100+ ready-to-paste Google dorks and GitHub dorks for the target. Categories: sensitive files, admin panels, APIs, error pages, open redirect params, SQLi-prone params, cloud assets, source code leaks, subdomain discovery.

### Phase 10b — XSS Testing
See [XSS Testing section](#xss-testing) below.

### Phase 10c — SSRF Testing
See [SSRF Testing section](#ssrf-testing) below.

### Phase 10d — IDOR Testing
See [IDOR Testing section](#idor-testing) below.

### Phase 11 — Vulnerability Scanning
Full nuclei scan: CVEs (high/critical), exposed panels, default credentials, misconfigurations, token/secret exposure, CORS issues, tech detection. Plus: 403 bypass testing (path and header methods), CORS misconfiguration testing with evil origins, CRLF injection, open redirect validation, host header injection testing. SQLmap on injection-prone parameters.

### Phase 12 — Cloud Asset Discovery
Checks S3 buckets (30+ name permutations), Firebase Realtime Database, GCP Storage, Azure Blob Storage (8 accounts × 16 containers), DigitalOcean Spaces (5 regions).

### Phase 13 — GitHub Secret Scanning
TruffleHog on the target GitHub org (verified secrets only). gitleaks on any cached repos. Pre-built GitHub search dorks for secrets, keys, config files, and more.

---

## JS Recon & Provenance Tracking

Phase 7 is the most powerful phase. Every JS file gets a **full provenance record** so you know exactly where a finding came from.

### How JS files are collected

| Tool | What it finds |
|---|---|
| `katana/crawl` | JS files found during active crawl |
| `gau/wayback` | Historical JS files from Wayback Machine / GAU |
| `getJS` | JS files linked from each live website's HTML |
| `js-import` | JS files imported by other JS files (recursive, depth 2) |

Every JS URL and its discovery source is saved to `js/js_provenance.json`.

### What the per-file report shows

For every JS file that has findings, the report (`secrets/js_findings_per_file.txt`) shows:

```
┌─ JS FILE ─────────────────────────────────────────────────────────────────
│  Filename       : a3f8c2e1d9b47f06.js
│  Source URL     : https://cdn.example.com/assets/app.bundle.js
│  Discovered By  : getJS
│  Parent Website : https://app.example.com
│  Findings       : 3  (CRITICAL:1  HIGH:2)
└───────────────────────────────────────────────────────────────────────────

  [01] [CRITICAL] AWS Access Key
       Match   : AKIAIOSFODNN7EXAMPLE
       Context : ... accessKeyId: "AKIAIOSFODNN7EXAMPLE", region: "us-east ...

  [02] [HIGH] API Key Generic
       Match   : api_key: "sk_live_abcdef..."
       Context : ... stripe_key = "sk_live_abcdef123" ...
```

### Secret patterns detected (60+)

AWS keys, Azure keys, GCP credentials, GitHub tokens, Slack tokens, Stripe keys, Twilio credentials, SendGrid keys, Discord bot tokens, JWT tokens, SSH private keys, MongoDB/PostgreSQL/MySQL URIs, Redis URIs, OpenAI keys, Anthropic keys, HuggingFace tokens, Shopify tokens, Supabase keys, Algolia admin keys, Mapbox tokens, NPM tokens, Cloudinary URLs, Sentry DSNs, Datadog keys, generic API keys, hardcoded passwords, encryption keys, internal URLs, feature flags, debug statements, and more.

**Plus entropy-based detection** — catches secrets that don't match any known pattern by looking for high-entropy strings (Shannon entropy > 4.0) near keywords like `secret`, `key`, `token`, `password`.

### Extra patterns scanned per JS file

Beyond secrets, each file is also scanned for: internal/staging URLs, admin/debug routes, hardcoded emails, commented credentials, GraphQL/REST endpoints, JWT tokens, Base64-encoded secrets, cloud storage URLs, WebSocket URLs, private IPs, sensitive param names, debug/dev flags, and SSRF-prone fetch calls.

---

## XSS Testing

Phase `xss` runs three separate XSS detection methods:

### 1. dalfox (primary)
Feeds injection-prone parameters + JS-extracted endpoints into dalfox for automated reflected XSS detection. Results in `vulns/xss_results.txt`.

### 2. Manual payload probing
Tests 9 XSS payloads across discovered parameter URLs:
- `<script>alert(1)</script>`
- `"><script>alert(1)</script>`
- `<img src=x onerror=alert(1)>`
- `<svg onload=alert(1)>`
- `javascript:alert(1)`
- Template injection probes (`{{7*7}}`, `${7*7}`)

Any reflected payload is logged with the exact URL, parameter name, and payload used.

### 3. DOM XSS sink scanning
Scans all downloaded JS files for 15 dangerous DOM sinks:

| Sink | Risk |
|---|---|
| `.innerHTML =` | Direct DOM write |
| `.outerHTML =` | Direct DOM write |
| `document.write()` | Classic sink |
| `eval()` | Code execution |
| `setTimeout` with concatenation | Code execution |
| `location.href =` from URL param | Navigation hijack |
| `location.replace()` | Navigation hijack |
| `window.open()` | Popup with URL |
| `jQuery .html()` with dynamic content | DOM write |
| `dangerouslySetInnerHTML` | React DOM write |
| `v-html =` | Vue DOM write |

Each DOM sink finding includes the source URL, discovered-by tool, parent website, and surrounding context. Results in `vulns/dom_xss_sinks.txt` and `vulns/dom_xss_sinks.json`.

---

## SSRF Testing

Phase `ssrf` tests all SSRF-prone parameters across crawled URLs and JS-extracted endpoints.

### SSRF-prone parameter names detected
`url`, `uri`, `host`, `src`, `dest`, `destination`, `redirect`, `out`, `view`, `fetch`, `load`, `path`, `endpoint`, `proxy`, `preview`, `callback`, `import`, `export`, `source`, `return`, `next`, `go`, `forward`, `location`, `link`, `href`, `resource`, `file`, `template`

### Payloads tested (19)

| Payload | Target |
|---|---|
| `http://<interactsh_domain>/ssrf` | OOB callback detection |
| `http://169.254.169.254/latest/meta-data/` | AWS IMDSv1 |
| `http://169.254.169.254/latest/meta-data/iam/security-credentials/` | AWS IAM roles |
| `http://metadata.google.internal/computeMetadata/v1/` | GCP metadata |
| `http://100.100.100.200/latest/meta-data/` | Alibaba Cloud metadata |
| `http://169.254.169.254/metadata/v1/` | DigitalOcean metadata |
| `http://127.0.0.1/` | Localhost |
| `http://0.0.0.0/` | Null address |
| `http://[::1]/` | IPv6 localhost |
| `http://2130706433/` | 127.0.0.1 in decimal |
| `http://0177.0.0.1/` | 127.0.0.1 in octal |
| `dict://127.0.0.1:6379/info` | Redis via dict:// |
| `file:///etc/passwd` | Local file read |
| `gopher://127.0.0.1:6379/` | Redis via gopher |
| `http://<interactsh>@169.254.169.254/` | @ bypass |

### OOB detection with interactsh

If `interactsh-client` is installed, BugHunter Pro automatically starts an OOB listener to catch blind SSRF callbacks that don't reflect in the response. Install it:

```bash
go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
```

Results in `vulns/ssrf_results.txt` and `vulns/nuclei_ssrf.txt`.

---

## IDOR Testing

Phase `idor` runs four separate IDOR detection methods:

### 1. Numeric parameter enumeration
Finds URLs with numeric ID parameters (`id=123`, `user_id=456`, `order_id=789`) and tests adjacent IDs (±1, ±2, ±10, ±100). If the response differs from the original and isn't an error page, it's flagged as an IDOR candidate.

### 2. REST path ID walking
Detects REST-style numeric path segments (`/users/123`, `/orders/456/items`) and tests adjacent IDs directly in the path.

### 3. UUID/GUID extraction from JS
Scans all JS files for hardcoded UUIDs and GUIDs near sensitive parameter names (`user_id`, `account_id`, `doc_id`, etc.). Reports source URL, discovery tool, and parent website for each hit. Results in `vulns/idor_uuid_references.json`.

### 4. nuclei IDOR templates
Runs nuclei with `idor`, `access-control`, and `auth-bypass` tags.

**Note:** For confirmed IDOR, you need an authenticated session. Pass your cookie with `--cookie "session=abc123"` and test the candidates in `vulns/idor_results.txt` manually with two different accounts.

---

## Output Structure

```
hunt_example.com_20241201_143022/
├── subdomains/
│   ├── subfinder.txt          ← Raw subfinder output
│   ├── assetfinder.txt        ← Raw assetfinder output
│   ├── crt.txt                ← crt.sh results
│   ├── all_passive.txt        ← All passive subs merged
│   └── puredns_brute.txt      ← DNS brute-force results
├── dns/
│   ├── resolved.txt           ← Live/resolved subdomains
│   ├── dns_details.txt        ← A, CNAME, MX records
│   └── resolvers.txt          ← Resolvers used
├── web/
│   ├── httpx_full.txt         ← Full httpx output (status, tech, title)
│   ├── live_urls.txt          ← Live URLs (used by most phases)
│   └── 403_hosts.txt          ← 403 hosts for bypass testing
├── screenshots/               ← gowitness/aquatone screenshots
├── ports/
│   └── naabu_*.txt            ← Port scan results
├── endpoints/
│   ├── all_urls.txt           ← All crawled URLs
│   ├── gau_urls.txt           ← Historical URLs
│   ├── js_extracted_endpoints.txt  ← API routes from JS
│   ├── jsluice_endpoints.txt  ← JSluice AST results
│   └── linkfinder.txt         ← LinkFinder results
├── params/
│   ├── injection_prone.txt    ← SQLi/XSS-prone param URLs
│   ├── ssrf_prone.txt         ← SSRF-prone param URLs
│   └── redirect_prone.txt     ← Open redirect candidates
├── js/
│   ├── js_urls.txt            ← All discovered JS URLs
│   ├── js_provenance.json     ← Full provenance map (url → tool, parent)
│   ├── files/                 ← All downloaded JS files (md5.js)
│   ├── maps/                  ← Downloaded source maps
│   └── source_maps_found.txt  ← Exposed .js.map files
├── secrets/
│   ├── js_findings_per_file.txt   ← ★ MAIN REPORT: per-file findings with provenance
│   ├── js_findings_per_file.json  ← Same as above in JSON
│   ├── js_aws_access_key.json     ← Per-pattern JSON results
│   ├── js_high_entropy_secrets.json
│   ├── jsluice_secrets.json
│   └── trufflehog_github.txt
├── graphql/
│   ├── graphql_endpoints.txt
│   ├── introspection_*.json   ← Full introspection dumps
│   └── schema_types.txt
├── api/
│   ├── found_api_paths.txt
│   ├── ffuf_api_*.json
│   └── method_allowed.txt
├── vulns/
│   ├── xss_results.txt        ← XSS findings (dalfox + manual)
│   ├── dom_xss_sinks.txt      ← DOM XSS sinks from JS
│   ├── dom_xss_sinks.json     ← DOM XSS sinks (JSON)
│   ├── ssrf_results.txt       ← SSRF findings
│   ├── idor_results.txt       ← IDOR candidates
│   ├── idor_uuid_references.json ← UUID/GUID refs from JS
│   ├── nuclei_cve.txt         ← nuclei CVE findings
│   ├── nuclei_panels.txt      ← Exposed admin panels
│   ├── nuclei_default_creds.txt
│   ├── nuclei_misconfig.txt
│   ├── nuclei_cors.txt
│   ├── nuclei_ssrf.txt
│   ├── nuclei_idor.txt
│   ├── cors_misconfig.txt     ← Manual CORS testing
│   ├── crlf_injection.txt
│   ├── open_redirects.txt
│   ├── host_header_injection.txt
│   ├── 403_bypasses.txt
│   ├── cname_takeovers.txt
│   └── subzy_results.txt
├── dorks/
│   └── google_dorks.txt       ← 100+ ready-to-use dorks
├── cloud/
│   ├── open_s3_buckets.txt
│   ├── open_gcp_buckets.txt
│   ├── open_azure_blobs.txt
│   └── open_do_spaces.txt
└── report.md                  ← Final markdown report with all findings
```

---

## Scope Files

Create a text file with one domain per line:

```
example.com
api.example.com
staging.example.com
# Lines starting with # are comments — ignored
# Blank lines are also ignored
```

Run it:
```bash
python3 bughunter.py --scope scope.txt
```

**Exclude domains from scope:**
```bash
python3 bughunter.py --scope scope.txt --exclude "out-of-scope.example.com,legacy.example.com"
```

**Merge all scope targets into one output directory:**
```bash
python3 bughunter.py --scope scope.txt --merge --output my_program_hunt
```

---

## Tips & Tricks

**Set a GitHub token for deeper secret scanning:**
```bash
export GITHUB_TOKEN="ghp_your_token_here"
echo 'export GITHUB_TOKEN="ghp_..."' >> ~/.bashrc
```

**Speed up scans by running specific phases only:**
```bash
# If you already have subdomains and live hosts, skip to JS
python3 bughunter.py example.com --phase js

# Run XSS, SSRF, IDOR without full recon
python3 bughunter.py example.com --phase xss
python3 bughunter.py example.com --phase ssrf
python3 bughunter.py example.com --phase idor
```

**Authenticated scanning — get more endpoints:**
```bash
# Log in manually, copy your session cookie from browser DevTools → Network tab
python3 bughunter.py example.com --cookie "session=abc123; csrf=xyz789"
```

**Review JS findings quickly:**
```bash
# Most important file — shows ALL JS secrets with source URL and tool
cat hunt_example.com_*/secrets/js_findings_per_file.txt | grep -A5 "CRITICAL"

# See which JS files came from which website
cat hunt_example.com_*/js/js_provenance.json | python3 -m json.tool

# Check for exposed source maps (full source code)
cat hunt_example.com_*/js/source_maps_found.txt
```

**Re-run nuclei with updated templates:**
```bash
nuclei -update-templates
python3 bughunter.py example.com --phase vulns
```

**Custom output directory:**
```bash
python3 bughunter.py example.com --output /tmp/my_hunt
```

---

## Tool Reference

### Required (tool skipped if missing)

| Tool | Purpose | Install |
|---|---|---|
| subfinder | Passive subdomain enum | `go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest` |
| httpx | HTTP probing + fingerprinting | `go install github.com/projectdiscovery/httpx/cmd/httpx@latest` |
| nuclei | Vulnerability scanning | `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest` |
| naabu | Port scanning | `go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest` |
| dnsx | DNS resolution | `go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest` |
| katana | Web crawling | `go install github.com/projectdiscovery/katana/cmd/katana@latest` |
| interactsh-client | OOB SSRF callbacks | `go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest` |
| assetfinder | Subdomain enum | `go install github.com/tomnomnom/assetfinder@latest` |
| waybackurls | Historical URLs | `go install github.com/tomnomnom/waybackurls@latest` |
| gau | Historical URLs | `go install github.com/lc/gau/v2/cmd/gau@latest` |
| getJS | JS file discovery | `go install github.com/003random/getJS@latest` |
| puredns | Fast DNS resolution | `go install github.com/d3mondev/puredns/v2@latest` |
| subzy | Subdomain takeover | `go install github.com/PentestPad/subzy@latest` |
| ffuf | Web fuzzing | `go install github.com/ffuf/ffuf/v2@latest` |
| jsluice | JS AST analysis | `go install github.com/BishopFox/jsluice/cmd/jsluice@latest` |
| arjun | Parameter discovery | `pip3 install arjun --break-system-packages` |
| trufflehog | Secret scanning | See installer |
| amass | Subdomain enum | `go install github.com/owasp-amass/amass/v4/...@master` |
| altdns | DNS permutations | `pip3 install py-altdns --break-system-packages` |
| jq | JSON processing | `apt install jq` |
| unfurl | URL parsing | `go install github.com/tomnomnom/unfurl@latest` |

### Optional (phases enhanced when present)

| Tool | Purpose |
|---|---|
| dalfox | Automated XSS scanning |
| sqlmap | SQL injection testing |
| masscan | Ultra-fast port scanning |
| nmap | Service/version detection |
| feroxbuster | Directory fuzzing |
| wafw00f | WAF detection |
| aquatone | Visual recon screenshots |
| gowitness | Visual recon screenshots |
| amass | Deep passive subdomain enum |
| kr (kiterunner) | API route discovery |
| gitleaks | Git secret scanning |
| github-subdomains | GitHub subdomain hunting |
| gotator | DNS permutation generation |

---

## Disclaimer

This tool is for **authorized security testing only**. Only use it on targets you have explicit written permission to test. The author is not responsible for misuse.

---

*BugHunter Pro v4.0 · Made by KJI*
