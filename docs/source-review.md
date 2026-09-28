# Source Review

Assessment date: **September 25, 2026**

## Community article reviewed

[Sentinel in Defender Unified RBAC - Roles and Permissions | PS, Here's What I Learned](https://pisinger.github.io/posts/sentinel-defender-unified-rbac-urbac-roles-permissions/)

## Overall assessment

The article is a strong technical investigation. Its central warning is correct: activating Unified RBAC does not automatically remove access available through Azure RBAC or Microsoft Entra roles.

The article is best used as a diagnostic deep dive, not as the sole customer migration procedure. It combines:

- Microsoft-documented behavior
- Observations from `Get-AzRoleDefinition`
- Interpretation of Microsoft-managed Azure roles
- Preview functionality
- Speculation about undocumented or empty definitions

Microsoft Learn should control customer-facing decisions.

## Confirmed findings

Current Microsoft documentation supports these article conclusions:

- Unified RBAC is not required just to use Sentinel in Defender.
- Activation is per Sentinel workspace.
- Activation has both Entra and Azure permission prerequisites.
- Unified assignments synchronize into Azure RBAC.
- The MTP Unified RBAC application receives User Access Administrator in an activated workspace.
- Applicable Azure permissions can remain effective in Defender.
- Relevant Entra security roles remain important.
- Service-principal and GDAP-group assignments are unsupported in Unified RBAC for Sentinel.
- Playbook Operator, Automation Contributor, and Workbook Contributor remain Azure-managed.
- Directly changing synchronized Azure assignments after activation can cause synchronization errors.
- Deactivation returns the workload to its previous permission model.

## Claims requiring qualification

### "Broadest grant wins"

This is useful operational shorthand, but not a documented universal authorization algorithm. The safer customer statement is:

> A narrower Unified RBAC role does not reliably constrain access independently granted through Azure RBAC or Microsoft Entra roles.

### Role mapping

Microsoft's Reader, Responder, and Contributor mappings are functional mappings. They do not prove exact parity with Azure roles. Test each job function and retain Azure control-plane permissions where required.

### Microsoft-managed role definitions

Role IDs and action lists observed with `Get-AzRoleDefinition` are implementation evidence at a point in time, not a supported migration API or stable contract. Do not hard-code them.

### Deactivation

Deactivation returns to the previous permission model, but it does not recreate Azure assignments the customer deleted. Restoration data is required.

### Preview features

Sentinel scoping, data operations, data-lake jobs, and MCP scenarios can have changing limitations. Validate them in the customer tenant and keep them out of the core migration unless required.

## Outdated information

The current Microsoft deadline is **March 31, 2027**, not July 1, 2026.

- [Sentinel overview and retirement timeline](https://learn.microsoft.com/azure/sentinel/overview#microsoft-sentinel-in-the-azure-portal-retirement-timeline)
- [February 2026 timeline announcement](https://learn.microsoft.com/partner-center/announcements/2026-february#update-extended-timeline-for-microsoft-sentinel-azure-portal-transition-to-the-defender-portal)

## Assessment of substantive linked sources

| Source | Type | Assessment |
|---|---|---|
| [Compare RBAC roles](https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles#microsoft-sentinel) | Microsoft | Authoritative high-level mapping; not exact Azure action parity |
| [Manage Unified RBAC](https://learn.microsoft.com/en-us/defender-xdr/manage-rbac) | Microsoft | Supports coexistence, prerequisites, synchronization, and identity caveats |
| [Governance relationships](https://learn.microsoft.com/en-us/unified-secops/governance-relationships) | Microsoft | Cross-tenant feature guidance; does not make GDAP groups or service principals valid Unified assignments |
| [Get-AzRoleDefinition](https://learn.microsoft.com/en-us/powershell/module/az.resources/get-azroledefinition) | Microsoft | Valid definition inspection; does not identify who has access |
| [List Azure assignments with PowerShell](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-powershell) | Microsoft | Correct assignment inventory starting point; also account for inheritance, groups, PIM, and Entra roles |
| [Azure integration roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/integration) | Microsoft | Useful for Azure roles that can remain necessary |
| [Unified permission details](https://learn.microsoft.com/en-us/defender-xdr/custom-permissions-details#data-operations-preview) | Microsoft | Current catalog; preview capabilities are not immutable |
| [Manage Sentinel data-lake jobs](https://learn.microsoft.com/en-us/azure/sentinel/roles#manage-jobs-in-the-microsoft-sentinel-data-lake) | Microsoft | Relevant to analytics jobs; apparent permission differences require tenant testing |
| [Sentinel MCP getting started](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-get-started) | Microsoft | Specialized data-lake/MCP scenario; not a core migration prerequisite |
| [Sentinel MCP triage tool](https://learn.microsoft.com/en-us/azure/sentinel/datalake/sentinel-mcp-triage-tool) | Microsoft | Specialized authorization guidance; place in an appendix |
| [Defender for Cloud built-in Azure roles](https://pisinger.github.io/posts/defender-for-cloud-built-in-azure-roles-permissions/) | Community | Useful context for the author's research method; not authoritative for Sentinel migration |

## Recommended decision

Proceed with a pilot, but do not describe activation as an automatic least-privilege conversion.

Use this sequence:

> **Inventory -> Connect to Defender -> Create Unified roles -> Activate one workspace -> Test with clean identities -> Remove only proven duplicates -> Retain Azure-only assignments -> Verify rollback -> Repeat**
