# Pilot Test Plan

## Test evidence fields

Complete these fields for every test:

| Field | Value |
|---|---|
| Test ID | |
| Date and tester | |
| Tenant, subscription, and workspace | |
| Principal object ID | |
| Direct and transitive groups | |
| Active and eligible Entra roles | |
| Azure assignments and inheritance | |
| Unified role, data source, and scope | |
| Operation attempted | |
| Expected result | |
| Actual result | |
| Time since assignment change | |
| Error and correlation/request ID | |
| Evidence location | |
| Pass/fail | |

## Core authorization tests

| ID | Identity/configuration | Action | Expected result |
|---|---|---|---|
| T01 | No relevant roles | Open Sentinel in Defender | Access denied |
| T02 | Unified Reader only | View alerts, incidents, and hunting results | Read succeeds; update actions fail |
| T03 | Unified Responder | Assign and close incident; manage alert | Approved response actions succeed |
| T04 | Contributor and Responder | Edit supported detection/tuning content | Supported security operations succeed |
| T05 | Azure Sentinel Reader only | Open Sentinel pages in Defender | Record continued Azure-authorized read access |
| T06 | Narrow Unified role plus broad Azure Contributor | Attempt action outside the Unified role | Record whether broader Azure grant remains effective |
| T07 | Scoped Unified Reader plus broad Entra reader role | Query outside assigned scope | Verify whether Entra access defeats the intended restriction |
| T08 | Global Administrator without workspace assignment | Open workspace data | Do not assume data access; record actual behavior |
| T09 | Authorization administrator | Create, edit, and assign a Unified role | Succeeds only within authorized data sources |
| T10 | Standard analyst | Attempt role assignment/escalation | Denied and logged |

## SOC workflow tests

| ID | Workflow | Expected result |
|---|---|---|
| T11 | View and filter incidents | Matches persona permissions |
| T12 | Assign, classify, comment on, and close incident | Only approved responder actions succeed |
| T13 | View and manage alerts | Matches role |
| T14 | Run advanced hunting query | Read and data scope match design |
| T15 | Create or modify supported detection/tuning | Only approved detection engineers succeed |
| T16 | Run a playbook from an incident | Succeeds only when required Azure playbook roles remain |
| T17 | View and edit a workbook | Edit requires retained Azure workbook permission |
| T18 | Manage connector/workspace settings | Only the platform persona succeeds |

## Identity and Azure dependency tests

| ID | Identity/configuration | Action | Expected result |
|---|---|---|---|
| T19 | Service principal with retained Azure RBAC | Run required deployment or query | Succeeds |
| T20 | Service principal relying only on Unified RBAC | Perform operation | Unsupported design; must not be a dependency |
| T21 | GDAP group | Access activated workspace | Validate unsupported assignment path and retained model |
| T22 | Automation identity | Trigger SOAR and downstream Logic App | Required Azure permissions remain effective |
| T23 | Detection deployment pipeline | Deploy analytics/content | Succeeds without unsupported Unified identity assignment |
| T24 | Managed identity | Access each required downstream resource | Only approved resource access succeeds |

## Scoping tests

Run these only when Sentinel scoping is in scope for the customer.

| ID | Action | Expected result |
|---|---|---|
| T25 | Query tagged in-scope rows | Only expected rows are visible |
| T26 | Query historical or untagged data | Behavior matches documented scope limits |
| T27 | Open an incident containing mixed-scope entities | View and manage behavior matches design |
| T28 | Run query/detection that omits the scope field | Failure or visibility impact is understood and documented |
| T29 | Run playbook, notebook, or integration against scoped data | No unintended cross-scope exposure |

## Operational and propagation tests

| ID | Action | Expected result |
|---|---|---|
| T30 | Add and remove test user through a group | Effective access changes within accepted propagation time |
| T31 | Activate and expire PIM eligibility | Access appears and expires as designed |
| T32 | Change a role assignment and inspect audit logs | Actor, principal, time, role, and scope are traceable |
| T33 | Export Unified RBAC roles | CSV includes permissions, assignments, data sources, principals, and activation |
| T34 | Compare pre/post Azure baselines | Only approved assignments changed |
| T35 | Check Defender Permissions after activation or cleanup | No unresolved synchronization errors |

## Portal and service tests

| ID | Action | Expected result |
|---|---|---|
| T36 | Compare critical Azure and Defender portal workflows | Relocations, redirects, and gaps are documented |
| T37 | Search and correlate across workspaces | Results, scope, and latency match design |
| T38 | Perform normal MSSP/multitenant workflow | Context switching and incident handling meet requirements |
| T39 | Compare alert and incident creation latency | Within customer acceptance threshold |
| T40 | Exercise emergency-access procedure | Recovery succeeds and is audited |

## Cleanup and rollback tests

| ID | Action | Expected result |
|---|---|---|
| T41 | Remove one approved redundant analyst assignment | Required workflows still pass |
| T42 | Repeat negative tests after cleanup | No unexpected access expansion |
| T43 | Deactivate pilot while legacy roles remain | Unified permissions stop; prior authorization resumes |
| T44 | Restore a removed test assignment | Exact principal, role, and scope are restored |
| T45 | Deactivate after removing the test assignment | Expected access loss proves restoration is required |

## Pilot exit criteria

- All critical positive tests pass.
- All negative least-privilege tests deny access as expected.
- Every retained Azure assignment has a documented reason and owner.
- Every removed assignment has restoration evidence.
- No unresolved synchronization errors remain.
- The emergency-access and rollback procedures pass.
- The business and technical owners approve expansion.
