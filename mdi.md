# Unified RBAC for MDI – Deployment Guide

## Overview

This guide configures Microsoft Defender for Identity (MDI) access using Microsoft Entra role-assignable groups integrated with Privileged Identity Management (PIM) and Defender XDR Unified RBAC.

> **Important:** Some highly privileged Entra global roles, such as Global Administrator, will continue to have admin privileges. Defender XDR respects these roles by maintaining their extensive access rights. This ensures critical administrative capabilities (such as for emergency access/break-glass accounts) remain uninterrupted.

---

## Prerequisites

- **Privileged Role Administrator** role in Microsoft Entra ID (required to create role-assignable groups)

---

## Step 1 – Define Roles

Define roles based on job functions within your organization:

| Role | Description |
|------|-------------|
| Security Administrator | Full access privileges |
| Security Analyst Tier 1 | Read-only, monitoring roles |
| Security Analyst Tier 2 | Limited operational tasks |
| Security Analyst Tier 3 | Manage configurations and settings |

---

## Step 2 – Create Role-Assignable Groups

Go to **Microsoft Entra Admin Center** → **Groups** → **New Group**

Create each group with these settings:

| Setting | Value |
|---------|-------|
| Group type | Security |
| Microsoft Entra roles can be assigned to the group | ☑️ Yes |
| Membership type | Assigned |

### Group Examples

| Group Name | Purpose |
|------------|---------|
| **MDI-SecAdmin-Full** | Security Administrators with full access privileges |
| **MDI-SecAnalystT1-ReadOnly** | Tier 1 Security Analysts with read-only access, suitable for monitoring roles |
| **MDI-SecAnalystT2-Limited** | Tier 2 Security Analysts with limited access for certain operational tasks without full administrative rights |
| **MDI-SecAnalystT3-Manage** | Tier 3 Security Analysts who can manage configurations and settings, tailored for senior analysts responsible for complex tasks |

### Restrictions

- `isAssignableToRole` is **immutable** – cannot be changed after creation
- Existing groups **cannot** have this property set retroactively
- Membership type must be **Assigned** – dynamic groups are not permitted
- **No group nesting** – a group cannot be a member of another role-assignable group

### Group Owners

You can delegate management by assigning trusted group owners. Owners can add or remove members but should be carefully selected to prevent unauthorized access or privilege escalation.

---

## Step 3 – Enable PIM for Groups

Go to **Microsoft Entra Admin Center** → **Identity Governance** → **Privileged Identity Management** → **Groups**

For each group:

1. Select the group → **Settings** → **Member**
2. Configure activation settings:
   - MFA required: **Yes**
   - Approval required: **Yes** (recommended)
   - Activation maximum duration: **8 hours**
3. Add members as **Eligible** (not Active)

---

## Step 4 – Assign Permissions in Defender XDR

Go to **Defender XDR Portal** → **Settings** → **Microsoft Defender XDR** → **Permissions** → **Roles**

Create custom roles and assign each Entra group to matching permissions:

### MDI-SecAdmin-Full

| Category | Permissions |
|----------|-------------|
| Security operations | All read and manage |
| Security posture | All read and manage |
| Authorization and settings | All read and manage |

### MDI-SecAnalystT1-ReadOnly

| Category | Permissions |
|----------|-------------|
| Security operations | All read only |
| Security posture | All read only |
| Authorization and settings | None |

### MDI-SecAnalystT2-Limited

| Category | Permissions |
|----------|-------------|
| Security operations | Alerts (manage), Response (manage), Basic live response (manage), File collection (manage) |
| Security posture | All read and manage |
| Authorization and settings | Security settings → Detect tuning (manage) |

### MDI-SecAnalystT3-Manage

| Category | Permissions |
|----------|-------------|
| Security operations | All read and manage |
| Security posture | All read and manage |
| Authorization and settings | Security settings → Detect tuning (manage), Core security settings (read and manage); System settings (read and manage) |

---

## Step 5 – Activate Unified RBAC

Go to **Settings** → **Microsoft Defender XDR** → **Permissions** → **Roles**

Enable Unified RBAC for Microsoft Defender for Identity workload.

---

## Step 6 – User Activation

When users need MDI access:

1. Go to **myaccess.microsoft.com** → **Groups**
2. Find the assigned group membership
3. Click **Activate**
4. Complete MFA and approval (if configured)
5. Permissions apply until session expires

---

## Continuous Review

Regularly review and adjust roles, groups, and permissions to ensure they meet evolving security needs and organizational changes.
