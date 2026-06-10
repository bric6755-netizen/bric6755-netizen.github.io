# Task 2 — Basic Firewall Configuration with UFW

**AICTE Oasis Infobyte Security Analyst Internship · June 2026**  
**Author:** Richard Boakye Danquah · Kumasi, Ghana 🇬🇭

---

## Objective

Configure a basic host-based firewall on a Linux system using **UFW (Uncomplicated Firewall)** to enforce a minimal, secure ruleset:

- ✅ **Allow** SSH (port 22/tcp) — essential remote management access
- 🚫 **Deny** HTTP (port 80/tcp) — block unencrypted web traffic
- 🚫 **Default deny** all other inbound connections

---

## Tool

| Tool | Version | Purpose |
|------|---------|---------|
| UFW | 0.36+ | Host-based firewall wrapper around `iptables`/`nftables` |

> UFW ships with Ubuntu/Debian by default. It provides a human-friendly interface on top of Linux's native `iptables` netfilter framework.

---

## Files in This Repository

```
task2-ufw/
├── ufw_configuration.sh   # Automated setup script
├── ufw_status.png          # Screenshot of active firewall rules
└── README.md               # This file
```

---

## Prerequisites

- Ubuntu 20.04 / 22.04 / 24.04 (or any Debian-based system)
- `sudo` / root access
- Internet connection (for `apt-get install` if UFW is not pre-installed)

---

## Setup & Execution

### Option A — Run the Script (Recommended)

```bash
# Clone the repository
git clone https://github.com/bric6755-netizen/OIBSIP.git
cd OIBSIP/task2-ufw

# Make the script executable
chmod +x ufw_configuration.sh

# Run as root
sudo ./ufw_configuration.sh
```

### Option B — Manual Step-by-Step

```bash
# 1. Install UFW
sudo apt-get update && sudo apt-get install -y ufw

# 2. Reset to clean state
sudo ufw --force reset

# 3. Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 4. Allow SSH
sudo ufw allow 22/tcp

# 5. Deny HTTP
sudo ufw deny 80/tcp

# 6. Enable the firewall
sudo ufw --force enable

# 7. Verify rules
sudo ufw status verbose
```

---

## Expected Output

After running the script, `sudo ufw status verbose` should show:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
──                         ──────      ────
22/tcp                     ALLOW IN    Anywhere    # Allow SSH
80/tcp                     DENY IN     Anywhere    # Deny HTTP
443/tcp                    DENY IN     Anywhere    # Deny HTTPS
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                DENY IN     Anywhere (v6)
443/tcp (v6)               DENY IN     Anywhere (v6)
```

---

## Rule Rationale

### Why Allow SSH (22/tcp)?
SSH is the primary remote management protocol for Linux servers. Without it, remote access to the system is severed entirely. It is kept open deliberately and should be further hardened in production (key-based auth only, `fail2ban`, non-standard port).

### Why Deny HTTP (80/tcp)?
Port 80 carries **plaintext HTTP traffic** — credentials, session tokens, and sensitive data transmitted over HTTP are visible to anyone on the same network segment. Since this host is not running a web server, port 80 should be closed. Any legitimate web traffic should use HTTPS (443), which can be enabled separately when needed.

### Why Default Deny Incoming?
A **default-deny posture** means every inbound connection is blocked unless explicitly permitted. This follows the principle of least privilege: the attack surface is minimal, and only necessary services are reachable.

---

## Security Concepts Covered

| Concept | Description |
|---------|-------------|
| Default-deny policy | Blocks all inbound by default; only named ports allowed |
| Principle of least privilege | Only expose what is strictly necessary |
| CVE-2022-0847 (DirtyPipe) | Example of why patched + firewalled systems matter |
| NTLM relay protection | Covered in Task 1; firewall complements SMB signing |
| Host-based vs network firewall | UFW operates at the OS level, independent of network devices |

---

## Testing the Rules

```bash
# From another machine on the same network:

# Test SSH — should succeed
ssh richard@<host-ip>

# Test HTTP — should be refused/timeout
curl -v http://<host-ip>/

# Test a blocked port — should timeout
nc -zv <host-ip> 8080
```

---

## Disabling / Resetting

```bash
# Disable firewall (rules preserved but inactive)
sudo ufw disable

# Full reset — removes all rules
sudo ufw --force reset
```

---

## References

- [UFW — Ubuntu Documentation](https://help.ubuntu.com/community/UFW)
- [iptables vs UFW vs nftables](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page)
- [NIST SP 800-41 — Firewall Guidelines](https://csrc.nist.gov/publications/detail/sp/800-41/rev-1/final)
- [CIS Ubuntu Linux Benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux)

---

*Part of the AICTE Oasis Infobyte Security Analyst Internship — Task 2*
