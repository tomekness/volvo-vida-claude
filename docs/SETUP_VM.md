# Setting Up the VIDA VM

Step-by-step guide to provision a fresh VIDA 2014D VM and connect it to Claude Code.
An agent can follow this guide autonomously using `/vida_provision`.

---

## Prerequisites

Install on the machine that will run VirtualBox:

```bash
sudo apt install virtualbox remmina python3
# Optional: bcp tool for image extraction in /vida_repair
# Optional: xpstopdf (libgxps-utils) for /vida_xps2pdf
```

**Agent mode** (`AGENT_MODE` in `scripts/config.sh`):

| Mode | When to use |
|------|-------------|
| `local` | VirtualBox and Claude Code run on the **same machine** — no SSH needed |
| `ssh` | VirtualBox runs on a **remote host** — Claude Code reaches it via SSH |

---

## Step 1: Get the VIDA VM

VIDA 2014D is Volvo's proprietary dealer software. This project does not distribute it.
Community resources for pre-built VMs can be found at [volvodiag.com](https://volvodiag.com/).

The VM comes as an `.ova` file (~10–15 GB). Download it to your host machine (the one
running VirtualBox).

---

## Step 2: Import the OVA

```bash
# Replace the path and VM name as needed
VBoxManage import /path/to/vida-2014d.ova --vsys 0 --vmname "VIDA 2014D"
```

Import takes 2–10 minutes. Verify:
```bash
VBoxManage list vms | grep VIDA
```

---

## Step 3: Configure Shared Folder

The shared folder maps `~/Downloads` on the host to `Z:\` inside Windows.
This is where SQL query output and screenshots land.

```bash
VM_NAME="VIDA 2014D"
VBoxManage sharedfolder add "$VM_NAME" \
  --name "SharedDownloads" \
  --hostpath "$HOME/Downloads" \
  --automount
```

> German Ubuntu locale: `~/Downloads` = `~/Downloads` (Downloads is not translated).

---

## Step 4: Configure NAT Port Forwarding

VIDA uses SQL Server on port 1433 inside the VM. Forward it to a host port:

```bash
VBoxManage modifyvm "$VM_NAME" --natpf1 "vida-sql,tcp,,14333,,1433"
```

Verify VRDE (RDP) is enabled:
```bash
VBoxManage modifyvm "$VM_NAME" --vrde on --vrdeport 3389
VBoxManage showvminfo "$VM_NAME" | grep -E "VRDE|NIC"
```

---

## Step 5: Create config.sh

```bash
cp scripts/config.sh.example scripts/config.sh
```

Edit `scripts/config.sh` — key values:

| Variable | Local mode | SSH mode |
|----------|-----------|---------|
| `AGENT_MODE` | `"local"` | `"ssh"` |
| `VM_NAME` | exact name from VirtualBox | same |
| `RDP_HOST` | `"localhost:3389"` | `"<host-ip>:3389"` |
| `SQL_PORT_NAT` | `14333` | `14333` |
| `SSH_HOST` | (leave empty) | `"192.168.1.100"` |
| `SSH_USER` | (leave empty) | `"username"` |
| `SSH_KEY` | (leave empty) | `"~/.ssh/id_ed25519"` |

---

## Step 6: (SSH mode only) Configure SSH Access

On the remote host, ensure SSH server is running and your key is authorized:

```bash
# On the remote host:
sudo systemctl enable ssh --now
# From your local machine:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519 -p 22 user@host-ip
# Test:
ssh -i ~/.ssh/id_ed25519 user@host-ip "echo OK"
```

---

## Step 7: Start the VM and Verify

```bash
scripts/vida_start
# Wait ~90 seconds for Windows to boot
scripts/vida_status
scripts/vida_screenshot   # visual check
```

Expected status output:
```
=== VIDA VM (VIDA 2014D) ===
State:           running (since ...)
Memory size:     3072MB
```

---

## Step 8: Switch VIDA Language (optional)

The VM ships with a **Language Switcher** folder on the Windows desktop
containing an installer for each supported language (`V2DLS-German.exe`, etc.).

Via RDP (`remmina rdp://localhost:3389`, login `vida` / `vida`):
1. Double-click `Language Switcher\V2DLS-German.exe` (or your language)
2. Accept the license → enter password: `volvodiag.com`
3. Restart VIDA

---

## Step 9: Take a Baseline Snapshot

After the initial setup is working (and after any language switch):

```bash
scripts/vida_snapshot "baseline-setup"
```

Then set it as the default in `scripts/config.sh`:
```bash
DEFAULT_SNAPSHOT="baseline-setup"
```

This lets `/vida_reset` restore a known-good state without arguments.

---

## Step 10: Verify Everything Works

```bash
scripts/vida_status          # VM running, RDP accessible
scripts/vida_screenshot      # desktop visible
scripts/vida_connect         # VIDA web UI URL printed
```

Then run `/vida_init <vehicle>` to set up your first vehicle project.

---

## Troubleshooting

| Problem | Likely cause | Fix |
|---------|-------------|-----|
| `VBoxManage: not found` | VirtualBox not installed | `sudo apt install virtualbox` |
| SSH timeout | Firewall or wrong IP | Check `SSH_HOST` and host firewall |
| RDP: black screen | VM still booting | Wait 90s, retry `vida_screenshot` |
| SQL queries fail | NAT port not forwarded | Re-run Step 4 |
| `Z:\` not visible in VM | Shared folder not automounted | Reboot VM, check VirtualBox Guest Additions |
| VIDA UI: locked session | Another browser is logged in | Close all browser tabs, reload |

For deeper issues with the VIDA installation: `/vida_debug`
