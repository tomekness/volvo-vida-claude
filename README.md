# volvo-vida-claude

Claude Code skills for Volvo VIDA 2014D diagnostics — control a VIDA VM, read diagnostic trouble codes from the SQL database, and build repair documentation from VIDA service data.

**Requires:** A machine running VIDA 2014D in VirtualBox, accessible via SSH.

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

On the **host machine** (running VirtualBox + VIDA):
- Ubuntu/Debian Linux
- VirtualBox with VIDA 2014D VM already installed and configured
- SSH server enabled
- Python 3 (for XML/ZIP decoding)
- `bcp` tool (for image extraction from VIDA DB)

On your **local machine** (running Claude Code):
- [Claude Code](https://claude.ai/code)
- SSH access to the host machine
- `remmina` or `xfreerdp` for RDP (optional, for `/vida_start`)

---

## Setup

**1. Clone this repo** on your local machine:
```bash
git clone https://github.com/your-username/volvo-vida-claude.git
cd volvo-vida-claude
```

**2. Configure** your connection:
```bash
cp scripts/config.sh.example scripts/config.sh
# Edit scripts/config.sh with your host IP, SSH user, VM name, vehicle info
```

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
| `/vida_start` | Start VIDA VM + open RDP connection |
| `/vida_stop` | Gracefully shut down VIDA VM |
| `/vida_status` | VM state + host RAM/disk usage |
| `/vida_screenshot` | Screenshot of the running VM |
| `/vida_readout` | Full diagnostic scan from VIDA SQL DB → creates readout file |
| `/vida_repair <component>` | Build repair folder from VIDA service database |
| `/vida_xps2pdf` | Convert new VIDA printouts (XPS → PDF) into repo |
| `/repair_done <folder> <name>` | Mark repair as complete, move to `_done/` |
| `/vida_debug` | Work one open debug task from `vida_debug/TODO.md`, then stop |

---

## Repo Structure

```
volvo-vida-claude/
├── .claude/commands/   — Slash command definitions
├── scripts/
│   ├── config.sh.example   — Configuration template (copy to config.sh)
│   ├── vida_start          — VM start script
│   ├── vida_stop           — VM stop script
│   ├── vida_status         — VM status script
│   └── vida_screenshot     — VM screenshot script
├── readouts/
│   ├── vida/               — VIDA scan results (YYYY-MM-DD_scanNN_*.md)
│   ├── pdfs/               — VIDA printout PDFs
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

## Vehicle Configuration

The `fkVehicleModel` and `fkModelYear` values in `scripts/config.sh` are specific to your vehicle. To find the correct values for your Volvo:

```sql
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT Id, Name FROM VehicleModel ORDER BY Name"
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT Id, Name FROM ModelYear ORDER BY Name"
```

Run these in CMD inside the VM.

---

## Notes

- VIDA 2014D is Volvo's proprietary dealer diagnostic software. This project only provides Claude Code skills to interact with an already-licensed installation — no VIDA software is distributed here.
- The VIDA VM requires a valid VIDA license (Volvo Tech Info subscription or dealer access).
- Tested with: Volvo V70 II (P2 platform, 2000–2007), MongoosePro JLR J2534 interface.
