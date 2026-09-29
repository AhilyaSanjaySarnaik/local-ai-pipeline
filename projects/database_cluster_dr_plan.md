## Comprehensive Disaster Recovery Runbook: Database Cluster Failure Due to Ransomware/Storage Corruption (Complete Failure)

**Version:** 1.0  
**Effective Date:** October 26, 2023  
**Applicable Systems:** [Specify DBMS, e.g., PostgreSQL 14, MySQL 8.0, MongoDB 7.0]  
**Assumption:** Complete failure of the primary database cluster (all nodes, storage, and network paths) due to ransomware encryption or catastrophic storage corruption. *No functional data access is possible.*

---

### 1. Response Checklist (Immediate Actions - Execute Within 15 Minutes)

| **Step** | **Action** | **Owner** | **Time Target** | **Criticality** | **Notes** |
|----------|------------|------------|-----------------|-----------------|------------|
| 1 | **Isolate Affected Cluster** | DevOps/DBA | < 5 min | Critical | Immediately disconnect cluster from network; block all traffic to affected storage volumes. Verify isolation via network firewall rules. |
| 2 | **Confirm Failure Scope** | DevOps/DBA | < 10 min | Critical | Validate: 1) All DB nodes unresponsive; 2) Storage volumes corrupted/encrypted (check file system checksums, `ls -l`, `df -h`, ransomware indicators like `.lock` files); 3) No backups accessible on infected storage. |
| 3 | **Identify Clean Backup Source** | Backup Engineer | < 15 min | Critical | Locate **isolated, unencrypted backups** (e.g., air-gapped backups, encrypted backups stored in *separate* infrastructure). *Do NOT use backups on infected storage.* |
| 4 | **Verify Backup Integrity** | Backup Engineer | < 10 min | High | Run checksum validation on backup files (e.g., `sha256sum` for files, `pg_checksum` for PostgreSQL). Confirm no corruption. |
| 5 | **Initiate Backup Restoration** | DBA | < 30 min | Critical | Restore clean backup to *new*, isolated environment (e.g., staging cluster). **Do NOT restore to production until verified**. |
| 6 | **Engage Ransomware Team** | Security Lead | < 10 min | Critical | If ransomware is confirmed, contact incident response team *immediately*. Provide evidence of encryption (e.g., file extensions, ransom note). |
| 7 | **Document Current State** | Incident Manager | < 5 min | Medium | Record exact failure time, affected nodes, storage paths, backup status, and ransomware indicators. |

> ⚠️ **Critical Warnings for Checklist**:  
> - **NEVER** attempt to restore from backups *on the infected storage*. This will propagate ransomware.  
> - **ALWAYS** confirm backups are *not* encrypted (rare but possible with ransomware).  
> - If no clean backups exist → **escalate to Incident Response Team immediately** (recovery may require forensic decryption).

---

### 2. Root Cause Analysis (RCA) - Post-Recovery

*Conduct within 24 hours of restoration completion. Focus on why the failure occurred and how to prevent recurrence.*

| **Root Cause Category** | **Specific Findings** | **Probability** | **Impact** | **Remediation Plan** |
|-------------------------|------------------------|-----------------|-------------|-----------------------|
| **Ransomware Attack** | 1. Initial infection vector (e.g., phishing email, unpatched vulnerability)<br>2. Encryption of all DB storage (no decryption key available)<br>3. Backup storage compromised | High (60%) | Critical | • Deploy email security & patch management<br>• Implement backup encryption with key rotation<br>• Conduct quarterly ransomware simulations |
| **Storage Corruption** | 1. Hardware failure (e.g., disk failure)<br>2. Accidental deletion of critical files<br>3. File system corruption (e.g., `ext4` errors) | Medium (30%) | Critical | • Replace failing hardware<br>• Enable automated file system checks (`fsck`)<br>• Implement immutable backups |
| **Backup Failure** | 1. Backup jobs failed due to storage corruption<br>2. No air-gapped backups available<br>3. Backup retention policy too short | High (40%) | Critical | • Enforce 3-2-1 backup rule (3 copies, 2 media, 1 offsite)<br>• Add backup integrity checks (checksums, versioning)<br>• Maintain air-gapped backups for 90+ days |
| **Human Error** | 1. Unpatched DB servers<br>2. Misconfigured backup schedules<br>3. Lack of DR testing | Medium (20%) | High | • Automate patching (e.g., Ansible)<br>• Mandate DR test quarterly<br>• Implement RBAC for backup access |

**RCA Conclusion**: *The primary root cause was the lack of isolated, unencrypted backups and insufficient ransomware resilience in the backup infrastructure. Storage corruption was secondary due to compromised backup storage.*  
**Prevention Priority**: Establish air-gapped backups with immutable storage; implement ransomware-specific backup encryption.

---

### 3. Recovery Steps (Step-by-Step)

#### **Phase 1: Isolation & Assessment (0-15 min)**
1.  **Isolate the cluster** (block network access, disconnect storage).
2.  **Confirm corruption**:
    - *Ransomware*: Check for `.lock` files, `encrypted` extensions, ransom notes.
    - *Storage corruption*: Run `fsck` (Linux), `chkdsk` (Windows), or DB-specific tools (e.g., `pg_checksum` for PostgreSQL).
3.  **Verify backup integrity** (using checksums or DB validation tools).

#### **Phase 2: Restore from Clean Backup (15-60 min)**
1.  **Deploy new isolated environment** (e.g., new VMs in a separate VPC).
2.  **Restore backup** to new environment:
    - *PostgreSQL*: `pg_restore -d new_db -Fc backup.dump`
    - *MySQL*: `mysql -u root -p < backup.sql`
    - *MongoDB*: `mongodump --out=/backup`
3.  **Validate restore**:
    - Check for data consistency (e.g., `SELECT COUNT(*) FROM users` vs. pre-failure count).
    - Confirm no ransomware artifacts in restored data.

#### **Phase 3: Apply Post-Recovery Safeguards (60-120 min)**
1.  **Patch all systems** (critical OS, DB, network components).
2.  **Update backup policy**:
    - Enable encryption for all backups (AES-256).
    - Implement 3-2-1 rule (3 copies, 2 media, 1 offsite).
    - Add air-gapped backups for ransomware recovery.
3.  **Test DR readiness** (run a 20-min recovery test on the new cluster).

#### **Phase 4: Full Recovery (120-240 min)**
1.  **Migrate production traffic** to new cluster (use zero-downtime cutover if possible).
2.  **Verify functionality** (see Section 4).
3.  **Roll back to old cluster** if new cluster fails (use failover mechanism).

> 🔑 **Key Decision Points**:
> - If backups are encrypted → **DO NOT restore**; contact ransomware team for decryption (if possible).
> - If storage corruption is minor → use DB repair tools (e.g., `REPAIR TABLE` in MySQL).
> - If no clean backups exist → **initiate full forensic analysis** (not recovery).

---

### 4. Health Verification (Post-Recovery)

**Verify the restored cluster is safe, functional, and resilient** before returning to production.

| **Verification Area** | **Checklist** | **Pass/Fail Criteria** | **Owner** |
|------------------------|----------------|------------------------|------------|
| **Data Integrity** | 1. Run `SELECT COUNT(*) FROM users` (match pre-failure count)<br>2. Validate checksums of critical files<br>3. No duplicate records | ✅ Pass: Counts match, checksums valid, no duplicates | DBA |
| **Ransomware Status** | 1. No `.lock` files in DB directories<br>2. No ransom notes in storage<br>3. Malware scan (e.g., ClamAV) on restored cluster | ✅ Pass: Zero ransomware artifacts | Security Team |
| **System Stability** | 1. Cluster uptime > 99.9% (1 hour)<br>2. No OOM errors or crashes<br>3. Query latency < 200ms (for critical paths) | ✅ Pass: Stable performance for 1 hour | DevOps |
| **Backup Resilience** | 1. Air-gapped backups exist (last 30 days)<br>2. Encrypted backups testable (decryptable)<br>3. Backup retention policy > 90 days | ✅ Pass: All backups functional | Backup Engineer |
| **Compliance** | 1. All data encrypted at rest<br>2. Audit logs show backup activity<br>3. Incident report signed off | ✅ Pass: Meets ISO 27001/NIST 800-53 | Compliance Officer |

**Pass/Fail Threshold**: **All 5 areas must pass** to declare recovery complete.  
**Recovery Time**: Maximum 24 hours (if no clean backups exist, extend to 72 hours with ransomware team support).

---

### Critical Success Factors & Contingencies
- **No Clean Backups?** → **Immediate escalation** to Incident Response Team. Ransomware decryption may be possible (e.g., via blockchain-based backups), but this requires specialized expertise.
- **Storage Corruption?** → Use DB-specific repair tools (e.g., `pg_reindex` for PostgreSQL) *before* restoration.
- **Time Sensitive**: Ransomware attacks often have short windows (24-48h). Act within 12 hours to avoid data loss.
- **Post-Mortem**: Document *all* steps in 72 hours to update this runbook.

> ✅ **Final Verification Statement**:  
> *"The database cluster is restored to a state where data integrity, ransomware immunity, and system stability are confirmed. All backups are resilient and meet the 3-2-1 rule. Production traffic is fully operational."*

---

**Approved By**:  
[Name], CTO | [Name], Head of Security | [Name], Backup Lead  
**Revision History**:  
| Version | Date | Changes | Approved By |
|---------|------|---------|--------------|
| 1.0 | Oct 26, 2023 | Initial release | [Name] |

This runbook adheres to **NIST SP 800-34** (Disaster Recovery) and **ISO 27001:2013** standards for ransomware resilience. Always tailor backup policies to your specific DBMS and environment. 

**Remember**: *The best DR is a tested, isolated backup system that doesn’t rely on the same infrastructure that failed.* 🔒