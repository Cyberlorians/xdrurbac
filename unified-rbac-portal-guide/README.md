# Microsoft Sentinel to Defender Portal: Unified RBAC Migration Guide

This guide provides a safe, test-first path for moving Microsoft Sentinel operations to the Microsoft Defender portal and adopting Microsoft Defender XDR Unified RBAC.

> **Current deadline:** Microsoft states that Sentinel support in the Azure portal continues through **March 31, 2027**. After that date, Sentinel is available only in the Defender portal.

## The simple version

Treat this as three separate changes:

1. **Move the user experience** to the Defender portal.
2. **Activate Unified RBAC** for one Sentinel workspace.
3. **Remove redundant Azure role assignments** only after testing proves they are no longer needed.

Do not combine these into a big-bang change.

The recommended sequence is:

> **Inventory -> Connect -> Recreate access -> Activate one workspace -> Test -> Clean up proven duplicates -> Test rollback -> Repeat**

## Important authorization rule

Sentinel access in the Defender portal can come from several independent paths:

- Defender XDR Unified RBAC
- Azure RBAC, including inherited assignments
- Microsoft Entra roles
- Direct or transitive group membership
- Active or PIM-eligible assignments
- Cross-tenant or managed-service arrangements

A narrow Unified RBAC role does not reliably restrict broader access granted through Azure RBAC or Microsoft Entra roles. Test the user's **effective access**, not just the role shown in Defender.

## What Unified RBAC does not replace

Keep Azure-side permissions when they are required for:

- Microsoft Sentinel Playbook Operator
- Microsoft Sentinel Automation Contributor
- Workbook Contributor
- Logic Apps and playbooks
- Data collection rules
- Log Analytics or workspace administration
- Connector and table management
- Content deployment
- ARM, Bicep, or Terraform pipelines
- Managed identities and service principals
- Azure Lighthouse or other managed-service scenarios

Unified RBAC does not support assigning Sentinel permissions to service principals or GDAP user groups. These are migration blockers if the design assumes they will move into Unified RBAC.

## Phase 1: Define the pilot

Choose one noncritical workspace and identify:

- Business owner
- Technical owner
- SOC personas
- Workspace and subscription IDs
- Test users with no unrelated administrator access
- Rollback owner
- Pilot dates and success criteria

Do not test only with existing administrators. Their inherited Azure or Entra access can hide missing permissions.

## Phase 2: Capture the current state

### 2.1 Run the read-only Azure inventory

Prerequisites:

- PowerShell 7
- `Az.Accounts` and `Az.Resources`
- Access to read the subscription and workspace role assignments

```powershell
Connect-AzAccount

.\scripts\Export-SentinelAccessBaseline.ps1 `
  -SubscriptionId "<subscription-id>" `
  -ResourceGroupName "<resource-group>" `
  -WorkspaceName "<log-analytics-workspace>" `
  -OutputPath ".\baseline"
```

The script exports:

- Role assignments at subscription, resource group, and workspace scope
- Relevant Sentinel and Defender role definitions
- A manifest containing the tenant, subscription, scopes, and export time

The script changes no permissions.

### 2.2 Export Unified RBAC

In the Defender portal:

1. Go to **System > Permissions > Roles**.
2. Export the current roles.
3. Save the CSV with the pilot evidence.

The Defender export is not a complete authorization inventory. It does not replace the Azure, Entra, PIM, group, or nonhuman-identity inventory.

### 2.3 Record identity access

For every pilot persona, record:

- User or service-principal object ID
- Direct and transitive groups
- Microsoft Entra roles
- PIM-eligible and active assignments
- Azure role assignments and inheritance
- Azure Lighthouse, GDAP, or MSSP access
- Emergency-access accounts

### 2.4 Record dependencies

Record the identity and required Azure permissions for:

- Playbooks and Logic Apps
- Automation rules
- Workbooks
- Data connectors
- DCRs
- CI/CD and infrastructure deployment
- Managed identities and app registrations
- Notebooks, data lake operations, and MCP tools

## Phase 3: Map job functions, not role names

Microsoft's high-level mapping is a starting point:

| Current Sentinel role | Unified RBAC starting point | Primary capability |
|---|---|---|
| Microsoft Sentinel Reader | Reader | Read security data |
| Microsoft Sentinel Responder | Responder | Read plus alert and response management |
| Microsoft Sentinel Contributor | Contributor and Responder | Security operations plus detection tuning |
| No direct classic equivalent | Scoped Reader | Scoped security-data read |
| No direct classic equivalent | Data Manager | Data-management permissions |

This is a functional mapping, not exact permission parity. A Sentinel Contributor may also perform Azure control-plane work that Unified RBAC does not replace.

For each customer persona, complete this table:

| Persona | Unified permissions | Defender data sources | Azure permissions retained | Entra dependencies | Expected denied actions |
|---|---|---|---|---|---|
| Tier 1 analyst |  |  |  |  |  |
| Incident responder |  |  |  |  |  |
| Threat hunter |  |  |  |  |  |
| Detection engineer |  |  |  |  |  |
| Sentinel platform admin |  |  |  |  |  |
| Data manager |  |  |  |  |  |
| Scoped analyst |  |  |  |  |  |

Prefer group assignments over individual assignments. Reserve `Authorization (manage)` for dedicated role administrators.

## Phase 4: Move to Defender without changing authorization

1. Connect the pilot workspace to the Defender portal.
2. Keep existing Azure assignments.
3. Validate portal navigation and normal SOC workflows.
4. Test multi-workspace and multitenant behavior where applicable.
5. Compare correlation, incident creation, and alert latency.
6. Record features that remain Azure-managed or redirect to Azure.

This establishes portal parity independently of the RBAC change.

## Phase 5: Create Unified RBAC roles

1. Create roles for the documented personas.
2. Assign groups.
3. Select the correct Sentinel workspace/data source.
4. Configure Sentinel scope only if it is a tested requirement.
5. Document every Azure role intentionally retained.
6. Keep a dedicated emergency-access path.

Do not:

- Copy Azure role names and assume equivalent behavior.
- Treat role import as an Azure-to-Unified Sentinel conversion wizard.
- Assign or clone Microsoft-managed `Defender Unified RBAC *` Azure roles.
- Depend on observed managed-role GUIDs or action lists as a stable API.

## Phase 6: Activate one workspace

Activation prerequisites currently include:

- Microsoft Entra **Security Administrator**
- Either:
  - **Owner** at subscription scope, or
  - **User Access Administrator** at subscription scope plus **Microsoft Sentinel Contributor** on the workspace

Activation is per Sentinel workspace.

During activation, Microsoft documents that the **MTP Unified RBAC** application receives User Access Administrator within the enabled workspace and that relevant permissions are synchronized into Azure RBAC. Include this privileged behavior in change approval and monitoring.

Do not directly edit synchronized Sentinel assignments in Azure after activation; Microsoft warns that this can cause synchronization errors.

## Phase 7: Test

Use [the pilot test plan](docs/pilot-test-plan.md). It includes:

- Positive tests
- Negative least-privilege tests
- Azure/Entra coexistence tests
- Automation and Azure-only dependency tests
- Scoping tests
- PIM and propagation tests
- Rollback tests

For every test, record the identity, all grant paths, expected outcome, actual outcome, error or correlation ID, and evidence location.

## Phase 8: Remove only proven duplicates

After the full pilot passes:

1. Export the baseline again.
2. Select one small class of Azure assignments believed to be redundant.
3. Record exact assignment IDs and restoration commands before removal.
4. Obtain owner approval.
5. Remove only that batch.
6. Re-run positive and negative tests.
7. Check Defender permission synchronization status.
8. Continue only when results match the approved design.

Never bulk-delete all Sentinel-related Azure assignments.

Likely candidates for removal are human analyst assignments whose tested SOC functions are fully provided by Unified RBAC. Likely retained assignments include Azure engineering, automation, deployment, workbook, playbook, service-principal, and managed-service access.

### Tool: automated migration recommendations

Instead of manually cross-referencing exports, use [rbac-migration-recommender.html](rbac-migration-recommender.html):

1. Export Azure role assignments with `scripts\Export-SentinelAccessBaseline.ps1` (or `Get-AzRoleAssignment`).
2. Export Unified RBAC roles from Defender: **System > Permissions > Roles > Export**.
3. Open `rbac-migration-recommender.html` in a browser and drop in both CSVs.

The tool runs entirely client-side (no server, no network calls — safe for GCC High and other sensitive tenants) and produces a row-by-row recommendation per Azure role assignment:

- **✅ Safe to remove** — covered by an equal-or-broader Unified RBAC role.
- **⚠️ Gap** — needs a Unified RBAC role built or upgraded first.
- **🔧 Keep** — Azure-only capability (playbooks, workbooks, automation, deployment roles) that Unified RBAC does not replace.
- **🚫 Blocked** — service principal or other identity type unsupported in Unified RBAC for Sentinel.
- **❓ Review** — role isn't a recognized Sentinel or Azure-only role; confirm intent manually.

Results are filterable, sortable, and exportable to CSV for a change record.

## Phase 9: Test rollback

Microsoft supports deactivating Unified RBAC for a workload. Defined Unified roles remain, but stop being effective for that workload and the previous permission model becomes effective.

Deactivation does **not** recreate Azure assignments the customer deleted.

Test both:

1. Deactivation while legacy assignments remain.
2. Restoration of a removed test assignment using the captured assignment ID, principal, role definition, and scope.

A complete rollback after cleanup is:

> **Deactivate Unified RBAC + restore removed Azure assignments**

## Phase 10: Expand gradually

Repeat per workspace. Each workspace needs its own:

- Dependency inventory
- Activation record
- Role mapping
- Test evidence
- Cleanup record
- Rollback procedure
- Owner approval

## Go/no-go checklist

Proceed only when all answers are yes:

- [ ] Portal workflows pass with authorization unchanged.
- [ ] Every persona has positive and negative test cases.
- [ ] Test users are free of unrelated broad roles.
- [ ] Service principals and GDAP dependencies remain on supported authorization paths.
- [ ] Playbooks, automation, workbooks, DCRs, and deployments are inventoried.
- [ ] Unified roles and assignments exist before activation.
- [ ] Emergency access is tested and audited.
- [ ] Exact Azure assignments can be restored.
- [ ] Deactivation has been tested.
- [ ] Cleanup is incremental and owner-approved.

## Key Microsoft references

- [Unified RBAC overview](https://learn.microsoft.com/en-us/defender-xdr/manage-rbac)
- [Activate or deactivate Unified RBAC](https://learn.microsoft.com/en-us/defender-xdr/activate-defender-rbac)
- [Compare role mappings](https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles#microsoft-sentinel)
- [Unified RBAC permission catalog](https://learn.microsoft.com/en-us/defender-xdr/custom-permissions-details)
- [Create custom roles](https://learn.microsoft.com/en-us/defender-xdr/create-custom-rbac-roles)
- [Export roles](https://learn.microsoft.com/en-us/defender-xdr/edit-delete-rbac-roles#export-roles)
- [Sentinel scoping](https://learn.microsoft.com/en-us/defender-xdr/scoping)
- [Plan the Defender portal transition](https://learn.microsoft.com/en-us/azure/sentinel/move-to-defender)
- [Sentinel in the Defender portal](https://learn.microsoft.com/azure/sentinel/microsoft-sentinel-defender-portal)
- [Sentinel roles and permissions](https://learn.microsoft.com/en-us/azure/sentinel/roles)
- [Current Azure portal retirement timeline](https://learn.microsoft.com/azure/sentinel/overview#microsoft-sentinel-in-the-azure-portal-retirement-timeline)

See [the source review](docs/source-review.md) for detailed findings on the community article and its linked sources.
