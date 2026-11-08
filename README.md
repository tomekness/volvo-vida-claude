# volvo-vida-claude

Claude Code skills for Volvo VIDA 2014D diagnostics — control a VIDA VM, read diagnostic trouble codes from the SQL database, and build repair documentation from VIDA service data.

**Requires:** A machine running VIDA 2014D in VirtualBox.
Works with VIDA on the **same machine** as Claude Code (local mode) or on a **remote host** (SSH mode).

---

## What is VIDA?

VIDA (Vehicle Information and Diagnostics for Aftersales) is Volvo's official dealer diagnostic software, used to read fault codes, program modules, and access service documentation for Volvo vehicles.

Community resources for obtaining a VIDA VM can be found at [volvodiag.com](https://volvodiag.com/) — this project is not affiliated with any provider.

---

## What This Does

- Start/stop/screenshot the VIDA Windows VM from Claude Code
- Query the VIDA SQL Server database directly for DTC sessions (no GUI needed)
- Build structured repair folders with service manuals extracted from VIDA's database
- Track trouble codes over time across multiple scans
- Convert VIDA printouts (XPS → PDF) into the repo
- Debug VIDA VM problems step-by-step with persistent memory across sessions (`/vida_debug`)

---

## Prerequisites

### Local Mode (`AGENT_MODE=local`) — VIDA and Claude Code on the same machine

- Ubuntu/Debian Linux
- VirtualBox with VIDA 2014D VM
- [Claude Code](https://claude.ai/code)
- Python 3 (for `/vida_repair`)
- `remmina` or `xfreerdp` for RDP (optional)

### SSH Mode (`AGENT_MODE=ssh`) — VIDA on a remote host

On the **host machine** (running VirtualBox + VIDA):
- Ubuntu/Debian Linux with VirtualBox and SSH server
- Python 3 and `bcp` tool (for `/vida_repair`)

On your **local machine** (running Claude Code):
- [Claude Code](https://claude.ai/code)
- SSH access to the host machine
- `remmina` or `xfreerdp` for RDP (optional)

> New to VIDA setup? See [docs/SETUP_VM.md](docs/SETUP_VM.md) — or run `/vida_provision` and let the agent guide you through it.

---

## Setup

**1. Clone this repo:**
```bash
git clone https://github.com/your-username/volvo-vida-claude.git
cd volvo-vida-claude
```

**2. Configure** your connection (all variables explained inline):
```bash
cp scripts/config.sh.example scripts/config.sh
# Set AGENT_MODE to "local" or "ssh", then fill in VM_NAME and other values
```

**2b. Set up vida_docs.db** (optional, ~230 MB — enables offline document search):

`vida_docs.db` is a SQLite full-text index of all VIDA service documents. It's not in git. It lives on the diagnostics host machine (or locally on your workstation for SSH-free queries). Set `VIDA_DOCS_LOCAL` and `VIDA_DOCS_DB_PATH` in `scripts/config.sh` accordingly. See `scripts/vida_docs_query.sh` for usage.

**3. Set up SSH key** (if not already done):
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519 -p YOUR_PORT USER@HOST_IP
```

**4. Clone the repo on the host machine** (for git sync after scans):
```bash
ssh USER@HOST_IP "git clone https://github.com/your-username/volvo-vida-claude.git ~/Desktop/volvo-vida-claude"
```
*(German Ubuntu locale: use `~/Schreibtisch/` instead of `~/Desktop/`)*

**5. Open Claude Code** in the repo directory and run `/vida_status` to verify connectivity.

---

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/vida_provision` | **Set up the VIDA VM** — walks through first-time setup or completes a partial install |
| `/vida_init <vehicle>` | **Set up a new vehicle project** — query VIDA IDs, create `facts/vehicle_facts.md` |
| `/vida_start` | Start VIDA VM + open RDP connection |
| `/vida_stop` | Gracefully shut down VIDA VM |
| `/vida_status` | VM state + host RAM/disk usage |
| `/vida_screenshot` | Screenshot of the running VM |
| `/vida_snapshot [name]` | Take a snapshot, list snapshots, or delete one |
| `/vida_reset [snapshot]` | Restore VM to a snapshot (default: `DEFAULT_SNAPSHOT` from config.sh) |
| `/vida_readout` | Full diagnostic scan from VIDA SQL DB → creates readout file |
| `/vida_repair <component>` | Build repair folder from VIDA service database |
| `/vida_xps2pdf` | Convert new VIDA printouts (XPS → PDF) into repo |
| `/vida_debug` | Work one open debug task from `vida_debug/TODO.md`, then stop |
| `/repair_done <folder> <name>` | Mark repair as complete, move to `_done/` |
| `/host_sync` | Sync the diagnostics host machine with the central git repo |

---

## Repo Structure

```
volvo-vida-claude/
├── .claude/commands/   — Slash command definitions
├── facts/
│   └── vehicle_facts.md    — Single source of truth for verified vehicle data (created by /vida_init)
├── scripts/
│   ├── config.sh.example   — Configuration template (copy to config.sh)
│   ├── vida_docs_query.sh  — Query vida_docs.db locally or via SSH (see VIDA_DOCS_LOCAL in config)
│   ├── host_sync           — Sync diagnostics host with git repo
│   ├── vida_start          — VM start script
│   ├── vida_stop           — VM stop script
│   ├── vida_status         — VM status script
│   ├── vida_screenshot     — VM screenshot script
│   ├── vida_reset          — Restore VM to a snapshot
│   ├── vida_connect        — SSH tunnel to VIDA web UI
│   └── extract_vida_images.ps1 — Extract GIF images from VIDA DB (for /vida_repair)
├── readouts/
│   ├── vida/               — VIDA scan results
│   │   └── YYYY-MM-DD/     — Per-scan folder
│   │       ├── scanNN_*.md — Scan analysis file
│   │       ├── dtc_raw.txt — Raw SQL export
│   │       ├── printouts/  — VIDA printout PDFs (converted from XPS)
│   │       └── screenshots/— Host screenshots from scan session
│   └── fehler_verlauf.md   — DTC history across all scans
├── repairs/
│   ├── _done/              — Completed repairs
│   ├── reparatur_log.md    — Repair status overview
│   └── <component>/        — Per-component repair folder
├── vida_debug/             — Structured debugging workspace
│   ├── TODO.md             — Open debug tasks (used by /vida_debug)
│   ├── WORKFLOWS.md        — VM interaction checklists for Claude
│   ├── logs/               — Session logs (newest first)
│   └── memory/             — Persistent debug state across sessions
├── CLAUDE.md               — Agent context
└── scripts/config.sh       — Your config (git-ignored, not in repo)
```

---

## How It Works

VIDA 2014D stores all diagnostic data in a SQL Server database (`DiagSwdlSession`) inside the VM. Instead of using the VIDA GUI, `/vida_readout` opens a CMD window in the VM via VirtualBox keyboard scan codes and runs `sqlcmd` queries, then reads the output files from the shared folder (`Z:\` = `~/Downloads` on the host).

`/vida_repair` similarly queries the `servicerep_de-DE` database for service documents, decodes the ZIP-compressed XML content, extracts images via `bcp`, and builds structured repair documentation.

---

## Changing the VIDA UI Language

The VIDA VM (from volvodiag.com) ships with a **Language Switcher** folder on the Windows desktop, containing an installer for each supported language (`V2DLS-German.exe`, `V2DLS-French.exe`, etc.).

Via RDP (`remmina rdp://$RDP_HOST`, login `vida/vida`):
1. Double-click `Language Switcher\V2DLS-German.exe` (or your language)
2. Accept the license agreement
3. Enter password: `volvodiag.com`
4. Restart VIDA

After switching, take a snapshot so you can always roll back:
```bash
scripts/vida_reset --list          # see available snapshots
```

---

## Resetting to a Known-Good State

If the VM ends up in a broken state, restore a snapshot:

```bash
scripts/vida_reset                  # restore DEFAULT_SNAPSHOT from config.sh
scripts/vida_reset "my-snapshot"    # restore a specific snapshot by name
scripts/vida_reset --list           # list all available snapshots
```

The script powers off the VM (hard), restores the snapshot, and starts it again headless.

---

## Vehicle Configuration

The `fkVehicleModel` and `fkModelYear` values in `scripts/config.sh` are specific to your vehicle. The easiest way to find them is:

```bash
/vida_init "Volvo V70 2002"   # queries VIDA SQL automatically and sets up facts/vehicle_facts.md
```

Or manually in CMD inside the VM:
```sql
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT Id, Name FROM VehicleModel ORDER BY Name"
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT Id, Name FROM ModelYear ORDER BY Name"
```

VIDA 2014D covers all Volvo models from approximately 1990–2014.

---

## Notes

- VIDA 2014D is Volvo's proprietary dealer diagnostic software. This project only provides Claude Code skills to interact with an already-licensed installation — no VIDA software is distributed here.
- The VIDA VM requires a valid VIDA license (Volvo Tech Info subscription or dealer access).
- Tested with: Volvo V70 II (P2 platform, 2000–2007), MongoosePro JLR J2534 interface.
