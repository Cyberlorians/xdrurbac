# Unified RBAC for MDE Build Guide – Step-by-Step

## Purpose

To set up Microsoft Defender for Endpoint (MDE) access using Unified RBAC with a tiered, least-privilege strategy aligned to Zero Trust operational separation (Tier 1-3), ensuring proper scope control through Device Groups.

## Section 1 – Key Concepts

### 1. Unified RBAC vs Legacy MDE RBAC

* **Unified XDR RBAC**: Default for new tenants since February 16, 2025. Applies to Endpoint, Identity, Office, Cloud Apps, Exposure Management, and Sentinel Data Lake.
* **Legacy MDE RBAC**: Still works for existing tenants but is no longer the default.
* **Device Groups**: Still required to control scope for Endpoint permissions, even with Unified RBAC.

### 2. Tiered Security Model

A three-tier approach to separate responsibilities and enforce least privilege:

* **Tier 3 – Global Security Operations**: Full administrative access across all devices and security settings.
* **Tier 2 – Regional/Segment Security Operations**: Elevated incident response and remediation, scoped by Device Groups.
* **Tier 1 – Local Security/IT**: Read-only access for monitoring and triage, no remediation capabilities.

### 3. Device Groups

* Control the scope of what users can see and manage in MDE.
* Users inherit permissions only for devices in their assigned Device Groups.
* Device Groups are assigned per role during Unified RBAC configuration.

### 4. Permission Categories

Unified RBAC uses permission bundles across these categories:

* **Device**: Read / Respond / Manage
* **Alerts & Incidents**: View / Investigate / Respond
* **Live Response**: Restricted / Full
* **Security Settings**: Manage (ASR policies, EDR settings)
* **Authorization**: Manage roles and permissions

## Section 2 – Build Steps

### Step 1 – Define Tiered Roles and Personas

Before configuring Unified RBAC, identify who belongs in each tier:

**Tier 3 – Global Security Operations (Full Admin)**

* SOC leads, global defenders, central IR team
* Permissions: Full access to all devices, manage security settings, manage roles, unrestricted Live Response, advanced hunting

**Tier 2 – Regional/Segment Security Operations (IR + Remediation)**

* Regional SOCs, mission/business unit IR teams
* Permissions: View and investigate alerts, perform active remediation, isolate devices, run restricted Live Response, approve MDVM actions
* Scoped by Device Groups (region, mission, or segment)

**Tier 1 – Local Security/IT (Triage Only)**

* Helpdesk, local IT, system admins with monitoring responsibilities
* Permissions: Read-only access to device inventory, alerts, and software exposure
* Cannot perform remediation, isolation, or Live Response

Write down the exact names of people for each tier.

### Step 2 – Create Device Groups

Device Groups define the scope for each tier. Create them before assigning roles.

1. Go to **Defender Portal → Settings → Endpoints → Device Groups**.
2. Create groups based on your organizational structure, for example:
   * `Tier0-DomainControllers` (optional high-security scope)
   * `Tier1-HighValueAssets`
   * `Tier2-Servers`
   * `Region-East`
   * `Region-West`
   * `Mission-A`
   * `Mission-B`
   * `Contractor-Systems`
3. Define device membership criteria (tags, domain, OS, or manual assignment).
4. Save each Device Group.

**Scope Assignment**:

* **Tier 3**: All Device Groups
* **Tier 2**: Assigned region/mission groups only
* **Tier 1**: Local facility or department groups only

### Step 3 – Activate Unified RBAC

1. Go to **Defender Portal → Permissions & Roles → Unified RBAC**.
2. Select **Activate Unified RBAC**.
3. Choose workloads to enable:
   * Defender for Endpoint
   * Defender for Identity
   * Defender Vulnerability Management
   * (Optional) Defender for Office, Cloud Apps, Sentinel Data Lake
4. If migrating from Legacy MDE RBAC, import existing roles.
5. Save activation.

### Step 4 – Create Custom Roles for Each Tier

For each tier, create a custom role in Unified RBAC:

1. Go to **Defender Portal → Permissions & Roles → Unified RBAC → Roles**.
2. Click **Create custom role**.
3. Name the role using your naming standard, e.g.:
   * `MDE-Tier3-GlobalSecOps`
   * `MDE-Tier2-RegionalIR`
   * `MDE-Tier1-Monitoring`

**Tier 3 – Global Security Operations**

Assign these permissions:

| Category | Permission Level |
|----------|------------------|
| Security Operations – Alerts | All read/manage |
| Security Operations – Response | All read/manage (includes isolate device, collect investigation package, Live Response) |
| Security Operations – Basic Response | All read/manage |
| Security Operations – Advanced Response | All read/manage |
| Security Posture – Vulnerability Management | All read/manage |
| Security Posture – Threat Management | All read/manage |
| Authorization & Settings – Authorization | All read/manage (limit to 1-2 users) |
| Authorization & Settings – Security Settings | All read/manage |
| Authorization & Settings – System Settings | All read/manage |

Device Group assignment: **All Devices**

**Tier 2 – Regional/Segment Security Operations**

Assign these permissions:

| Category | Permission Level |
|----------|------------------|
| Security Operations – Alerts | All read/manage |
| Security Operations – Response | Alerts (manage), Basic live response (manage), Advanced response actions (manage) |
| Security Operations – Basic Response | File collection (manage) |
| Security Posture – Vulnerability Management | All read/manage |
| Security Posture – Threat Management | All read |
| Authorization & Settings – Security Settings | Core security settings (read) |

Device Group assignment: **Region/Mission/Segment groups** (e.g., Region-East, Mission-A)

**Tier 1 – Local Security/IT (Monitoring)**

Assign these permissions:

| Category | Permission Level |
|----------|------------------|
| Security Operations – Alerts | All read-only |
| Security Operations – Response | None |
| Security Posture – Vulnerability Management | All read-only |
| Security Posture – Threat Management | All read-only |
| Authorization & Settings | None |

Device Group assignment: **Local facility or department groups only**

### Step 5 – Assign Groups or Users to Roles

For each custom role:

1. Go to the role you created.
2. Click **Assignments**.
3. Add Microsoft Entra role-assignable groups or individual users.
4. Confirm Device Group scope for each assignment.
5. Save.

**Best Practice**: Use Microsoft Entra role-assignable groups with PIM for Tier 3 and Tier 2 roles to enforce just-in-time elevation.

### Step 6 – Test Each Tier

Validate that each tier has appropriate access:

1. Log in as a Tier 1 user:
   * Verify read-only access to alerts and devices in their Device Group.
   * Confirm they cannot isolate devices or run Live Response.
2. Log in as a Tier 2 user:
   * Verify they can investigate and respond to alerts in their assigned Device Group.
   * Confirm they can isolate devices and run restricted Live Response.
   * Confirm they cannot access devices outside their Device Group.
3. Log in as a Tier 3 user:
   * Verify full access to all devices and security settings.
   * Confirm they can manage roles and permissions.

### Step 7 – Document and Train

1. Document the tier assignments, Device Group structure, and role mappings.
2. Train users on how to:
   * Activate roles in PIM (if using eligible assignments).
   * Navigate the Defender Portal with their assigned permissions.
   * Escalate to higher tiers when needed.

## Section 3 – Unified RBAC Permission Matrix (Quick Reference)

| Tier | Alerts | Remediation | Live Response | Device Scope | Settings |
|------|--------|-------------|---------------|--------------|----------|
| **Tier 3** | Read/Manage | Full (isolate, delete files, approve MDVM) | Full | All Devices | Manage all |
| **Tier 2** | Read/Manage | Active remediation (isolate, investigate) | Restricted | Region/Mission | Read core settings |
| **Tier 1** | Read-only | None | None | Local only | None |

## Section 4 – First-Time User Experience

When a user logs in to the Defender Portal:

1. They navigate to **Microsoft Defender Portal** (https://security.microsoft.com).
2. If using PIM for role assignment:
   * Go to **Microsoft Entra → My Roles**.
   * Find the assigned role.
   * Click **Activate**.
   * Complete MFA and approval (if configured).
3. Once active (or if directly assigned), they will see:
   * Devices and alerts scoped to their assigned Device Groups.
   * Actions available based on their tier's permission level.
4. Permissions remain active for the session duration or PIM time limit.
