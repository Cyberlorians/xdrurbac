# Unified RBAC for MDI Build Guide – Step-by-Step

## Purpose

To set up Microsoft Defender for Identity (MDI) access using Microsoft Entra role-assignable groups with Privileged Identity Management (PIM), ensuring all privileged roles are eligible and require elevation before use.

## Section 1 – Key Concepts

### 1. Role-Assignable Group

* A special Microsoft Entra group that can be assigned directory roles (e.g., Security Administrator).
* These groups have `isAssignableToRole` set to true.
* This property cannot be changed later.

### 2. Privileged Identity Management (PIM)

* Controls who can activate privileged roles.
* All members of role-assignable groups must be eligible, not permanently active.

### 3. Eligibility Rules

* Being a group member does not mean you automatically have the role.
* You must activate via PIM before you can perform privileged actions.

### 4. Group Owners

* Can add/remove members.
* If the group is role-assignable, owners must also be eligible in PIM to manage membership.
* If the owner is not eligible, they cannot make changes requiring privileged access.

## Section 2 – Build Steps

### Step 1 – Define Roles

Before touching Entra or Defender XDR, decide:

* Who will be in Security Administrator (full access).
* Who will be in Tier 1 Analyst (read-only).
* Who will be in Tier 2 Analyst (limited operational access).
* Who will be in Tier 3 Analyst (management level).

Write down the exact names of people for each role.

### Step 2 – Create Role-Assignable Groups

Repeat this process for each role.

1. Go to Microsoft Entra Admin Center → Groups → New Group.
2. Select:
   * Group type: Security
   * isAssignableToRole: Check this box (critical).
   * Membership type: Assigned (do not choose dynamic).
3. Name the group using your naming standard, e.g.:
   * `MDI-SecAdmin-Full`
   * `MDI-SecAnalystT1-ReadOnly`
   * `MDI-SecAnalystT2-Limited`
   * `MDI-SecAnalystT3-Manage`
4. Add group owners (trusted personnel).
   * If they will manage group members, they must also be eligible in PIM for this group's assigned role.
5. Save.

### Step 3 – Assign Roles to Groups in PIM

For each group:

1. Go to Microsoft Entra Admin Center → Roles and Administrators.
2. Select the role (e.g., Security Administrator).
3. Assign the role-assignable group.
4. In PIM, ensure all members are set to eligible.
5. Configure activation settings:
   * MFA required.
   * Approval required (recommended).
   * Time limit (e.g., 8 hours).

### Step 4 – Map Groups to Defender XDR Permissions

Inside Defender XDR:

1. Go to Permissions → Unified RBAC.
2. Create or update custom roles to match your MDI tiers.
3. Assign the Entra role-assignable group to the matching Defender XDR role.

| Group | Security Operations | Security Posture | Authorization & Settings |
|-------|---------------------|------------------|--------------------------|
| `MDI-SecAdmin-Full` | All read/manage | All read/manage | All read/manage |
| `MDI-SecAnalystT1-ReadOnly` | All read-only | All read-only | None |
| `MDI-SecAnalystT2-Limited` | Alerts, Response, Basic live response, File collection (manage) | All read/manage | Detect tuning (manage) |
| `MDI-SecAnalystT3-Manage` | All read/manage | All read/manage | Detect tuning (manage), Core security settings (read/manage), System settings (read/manage) |

### Step 5 – First-Time User Experience

When a new member tries to use MDI:

1. They log in to Defender XDR.
2. They will not have access until they activate their role in PIM:
   * Go to Microsoft Entra → My Roles.
   * Find the assigned role.
   * Click Activate.
   * Complete MFA and approval (if configured).
3. Once active, permissions will apply until their session expires.
