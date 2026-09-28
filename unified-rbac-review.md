# Microsoft Sentinel → Defender Portal: Unified RBAC Migration Guide

*A simple, safe way to move Sentinel access from Azure into Defender's new permissions system — without accidentally cutting off access people still need, or leaving old access open longer than it should be.*

> **Azure portal support continues through March 31, 2027.** After that date, Sentinel is available only in the Defender portal.

---

## Part 1 — Understand the migration

*Read this part first. No steps yet — just what's changing and why.*

### What's actually happening here

Microsoft Sentinel is moving into the Defender portal, and it comes with a **new, simpler permissions system** called Unified RBAC. Right now, your permissions live in Azure (Azure RBAC). The goal is to rebuild those same permissions in the new system — **then** turn off the old ones.

> 🔑 **Think of it like changing the locks on a building.**
> Azure RBAC is the old lock. Unified RBAC is the new lock. Installing the new lock does **not** automatically remove the old one — both keys keep working until you physically take the old lock off the door. If you skip that last step, people can still walk in with their old key, even if the new keycard system says they shouldn't have access.

**The 3 things we're really doing:**

1. **① Switch portals** — Start using Sentinel inside Defender instead of Azure. Nobody's access changes yet — this step is just about the screen you look at.
2. **② Rebuild permissions** — Recreate everyone's current access inside the new Unified RBAC system, and turn it on for one team first.
3. **③ Remove the old keys** — Once the new roles are live, delete the old Azure permissions that are no longer needed — a few at a time, not all at once.

> ⚠️ **Why we go one team at a time:** turning on the new system does not "override" the old one. If someone still has old Azure access, they'll keep that access no matter what the new system says. That's actually good news for safety — it means turning on Unified RBAC can't accidentally lock anyone out. The only risky moment is Step ③, when you actually remove the old access — so do that in small batches, and remember [you can always turn the new system back off](#how-to-undo-this-if-something-goes-wrong) if something looks wrong.

### There are 3 badge systems checking your access — not just 1

Sentinel inside Defender is watched by **three separate systems at the same time**. Nobody turns two of them off just because you set up the third one. Think of it like a building with three different badge readers on every door, and you only need *one* of your badges to work to get in:

| System | Role |
|---|---|
| ☁️ **Azure RBAC** *(the old badge)* | The classic roles people already have: `Microsoft Sentinel Reader`, `Responder`, `Contributor`. |
| 🪪 **Microsoft Entra roles** *(the master badge)* | Big, tenant-wide roles like `Security Administrator` or `Global Administrator`. These work everywhere, building-wide. |
| 🛡️ **Defender Unified RBAC** *(the new badge)* | The role you build fresh inside the Defender portal, just for security work. |

> ➕ **The most important rule: access adds up, it doesn't cancel out.**
> If someone has a wide-open old badge (Azure RBAC) *and* a narrow new badge (Unified RBAC), they still get in with whichever badge is more powerful. Microsoft says it plainly: turning on the new system does **not** take away anything the old badges already allow. If your goal is to make someone's access *smaller*, giving them a narrow new role isn't enough — you also have to go take away their old badge.

> ⚠️ **Watch for this one:** even the person with the biggest master badge — Global Administrator — does *not* automatically get to walk into a Sentinel workspace. But they *can* hand themselves a badge whenever they want. That's a fast way for someone to go from "big boss role" to "full access to security data" in one click — worth watching closely.

### How today's Sentinel roles map to the new system

Confirmed against [Microsoft's official mapping doc](https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles#microsoft-sentinel).

> *(GCC High note: the "Scoped Reader" and "Data Manager" bundles depend on preview features — Sentinel scoping and the data lake — that aren't currently available in GCC High, so they're left out of this table.)*

> 🧱 **Important: these aren't buttons you click.**
> Unified RBAC has **no** built-in "Reader," "Responder," or "Contributor" roles to pick from a list. When you build a role, you type your own name for it (like "Tier 1 Analyst") and check individual permission boxes. The names in the table below — *Reader, Responder, Contributor and Responder* — are just **Microsoft's labels for a specific bundle of checkboxes**. Use the "Permission boxes to check" column to know exactly which boxes to check when you build your own role.

| Today (Azure role) | Microsoft's name for this bundle | Permission boxes to check + what it means |
|---|---|---|
| Microsoft Sentinel Reader | "Reader" | `Security data basics (read)` — can view alerts and data, can't change anything |
| Microsoft Sentinel Responder | "Responder" | + `Alerts (manage)`, `Response (manage)` — everything Reader can do, plus work incidents and alerts |
| Microsoft Sentinel Contributor | "Contributor and Responder" | + `Detection tuning (manage)` — everything Responder can do, plus tune detections (custom detections, alert rules, threat indicators). **Does not** include managing analytics rules as resources, content hub, workbooks, or deployments. |

> 🚨 **The most common mistake:** the old "Microsoft Sentinel Contributor" role is a broad grant — it includes deploying content, managing workbooks, and other Azure engineering tasks. Checking the boxes for the "Contributor and Responder" bundle is *narrower* — it's really "Responder + detection tuning." It does **not** let someone author or run playbooks, manage workbooks, deploy content-hub solutions, or manage analytics-rule resources. If someone needs those things, they still need the matching Azure role (see below).

### Some things have to stay in Azure

The new Unified RBAC system covers day-to-day SOC work (viewing alerts, responding to incidents, hunting). Per Microsoft's docs, it explicitly does **not** cover these — they stay on Azure roles:

**🤖 Playbooks & automation**
- `Microsoft Sentinel Playbook Operator` — run playbooks
- `Logic App Contributor` — build/edit Consumption playbooks
- `Logic Apps Standard Developer/Contributor/Operator` — Standard playbooks
- `Microsoft Sentinel Automation Contributor`

**🛠️ Engineering & deployment**
- `Workbook Contributor` — Sentinel workbooks
- `Monitoring Contributor` — data collection rules
- `Log Analytics Contributor` — the Search feature
- `Template Spec Contributor` — deploying Content Hub solutions
- `Microsoft Sentinel Contributor` (Azure role) — analytics rules, resource management

**🧩 Non-human & outside identities**
- Service principals (apps/scripts)
- Managed identities
- Partner/MSSP access (Azure Lighthouse, GDAP)

> 🚫 **Two things the new system flat-out can't do:** you cannot give Sentinel access to a **service principal** (an app or script's identity), and you cannot give it to a **GDAP partner group**. If any automation, CI/CD pipeline, external SOAR tool, or MSSP partner logs in as one of these, leave that workspace on Azure RBAC. A newer feature called "governance relationships" does *not* fix this either — those permissions are still assigned in Azure RBAC.

*Source: [Microsoft Learn — Map existing RBAC permissions (Microsoft Sentinel section)](https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles#microsoft-sentinel).*

### What "turning it on" really does behind the scenes

> ✅ **Good news, and this is confirmed directly by Microsoft's docs:** this is *not* a one-way door. You can turn Unified RBAC off again later, per workload, per workspace, any time — go to **System > Permissions > Roles > Workload settings** and flip the toggle off. Microsoft's own words: *"You can deactivate Microsoft Defender unified RBAC and revert to the individual RBAC models from... Microsoft Sentinel."* ([source](https://learn.microsoft.com/en-us/defender-xdr/activate-defender-rbac#deactivate-microsoft-defender-unified-rbac)). The one thing it can't undo is bringing back Azure permissions you already deleted — that's on you to restore from a backup, not the toggle's job.

Turning on Unified RBAC for a workspace isn't just a settings toggle — a few automatic things happen that are worth understanding *before* you click it:

1. **Microsoft's own robot helper gets temporary admin rights.** An app called `MTP Unified RBAC` automatically becomes `User Access Administrator` on that one workspace. This is expected and documented — but it is a privileged change, so it belongs in your change-approval record.
2. **It copies your new roles into Azure automatically.** From then on, whatever you build in Defender gets written into Azure RBAC behind the scenes so the two systems stay in sync.
3. **After this, only make Sentinel permission changes in the Defender portal.** If you edit those same permissions in the Azure portal afterward, the two systems can get out of sync, and the Defender **Permissions** page will show you an error to fix.
4. **Turning it back off quietly reverts — but doesn't undo deletions.** If you deactivate, the old permission model takes over again automatically. But if you already deleted the old Azure permissions, deactivating does not bring them back. You'd have to restore them yourself.

---

## Part 2 — Do the migration

*Now that the concept makes sense, here's the step-by-step plan, in order.*

### The migration plan, boiled down to 6 steps

The core loop really is that simple: **build the roles → turn it on → remove the old access**. These 6 steps just add the small safety checks worth doing along the way.

#### Step 1 · Turn today's access into a short list of job roles

Write down the actual jobs people do (e.g. "Tier 1 analyst who just reads alerts," "Responder who closes incidents," "Engineer who builds detections") and which Sentinel workspace(s) they need. This becomes your shopping list for Step 2 — you're not copying old role *names*, you're copying what people actually need to do.

#### Step 2 · Build the new custom roles (don't turn them on yet)

- In Defender, create one custom role per job function from Step 1, and name it yourself — there's no "Reader/Responder/Contributor" button to click, you check permission boxes (see the [mapping table above](#how-todays-sentinel-roles-map-to-the-new-system) for which boxes match each old role).
- Assign each role to a **group**, not individual people, when possible.
- Note which Azure permissions each person will still need to keep (playbooks, workbooks, deployments — see [what stays in Azure](#some-things-have-to-stay-in-azure)).

#### Step 3 · Turn on Unified RBAC for one workspace

Go to **System > Permissions > Microsoft Defender XDR > Roles > Workload settings**, then **View Workspaces**, and activate your pilot workspace.

You'll need Entra **Security Administrator**, plus either subscription **Owner**, or **User Access Administrator** + workspace **Sentinel Contributor**. See ["What turning it on really does"](#what-turning-it-on-really-does-behind-the-scenes) above — and remember, this step is [fully reversible](#how-to-undo-this-if-something-goes-wrong) if needed.

#### Step 4 · Quick sanity check (10 minutes, optional but cheap insurance)

You don't need a big formal test cycle for this. Since roles are hand-built from checkboxes (no templates), it's easy to miss one — so just have 2-3 real people from the pilot team confirm their access looks normal. If something's off, fix the role — nothing is destructive yet since their old Azure access is still there too. See the [optional deeper checklist](#optional-a-deeper-checklist-if-you-want-more-rigor) if you want more rigor for a sensitive team.

#### Step 5 · Remove their old Azure group membership

This is the actual "shrink access" step — everything before this was additive. Take those people out of the old `Microsoft Sentinel Reader/Responder/Contributor` Azure groups (keep any Azure roles they still need per Step 2 — playbooks, workbooks, deployments, etc.). Do it for the whole pilot team at once if you're confident, or in a couple of batches if you want extra caution. If anything breaks, you can always [turn Unified RBAC back off](#how-to-undo-this-if-something-goes-wrong) while you sort it out.

> **Optional safety net:** before removing anything, export a snapshot of current Azure role assignments (`Get-AzRoleAssignment`) so you have an exact list to restore from if needed.

#### Step 6 · Repeat for the next team

Once the pilot team is clean and working, do the same for the next team. One team at a time keeps mistakes small and easy to fix.

### Optional: a deeper checklist, if you want more rigor

Not required for every team. Use this for a sensitive/critical group, or if you want an audit trail — otherwise the quick check in Step 4 is enough.

- **✅ Can-do:** Reader can view, responder can respond, engineer can build detections, playbooks/workbooks still run.
- **🚫 Can't-do:** No role = no access; a Reader can't edit anything; nobody can grant themselves more access.
- **🤖 Non-human accounts:** Service accounts, automation, and partner/MSSP access still work — these should never have moved to Unified RBAC in the first place.

### How to undo this if something goes wrong

> ✅ **To be crystal clear: yes, you can turn this off.** Microsoft explicitly supports deactivating Unified RBAC for Sentinel and reverting to Azure RBAC — this is not a permanent, irreversible switch. ([Microsoft Learn — Deactivate Microsoft Defender unified RBAC](https://learn.microsoft.com/en-us/defender-xdr/activate-defender-rbac#deactivate-microsoft-defender-unified-rbac))

1. **Turn off the new system** — **System > Permissions > Roles > Workload settings**, flip the Sentinel toggle off, confirm. The roles you built stay saved but stop being used — the old Azure permissions take over again automatically.
2. **Put back anything you deleted** — Turning off the new system does *not* bring back old permissions you already deleted. You have to manually restore those from your earlier snapshot.
3. **Spot-check** — Have a couple of real users confirm their access looks normal again before calling it done.

> 🚨 **Golden rule:** never delete old permissions before you've saved an exact copy of what you're deleting. That copy is your undo button — the toggle alone won't restore deletions.

### Ready to move forward? Check these off

- [ ] The Defender portal works fine with permissions unchanged.
- [ ] Every job role has been tested for "can do" and "can't do."
- [ ] Test accounts don't have unrelated admin access hiding problems.
- [ ] Service accounts and partner/MSSP access are left on the old system on purpose.
- [ ] Playbooks, automation, workbooks, and deployments still work.
- [ ] New roles are built and assigned before turning anything off.
- [ ] Emergency/break-glass access has been tested.
- [ ] You have an exact list of what to restore if you need to undo a change.
- [ ] You've tested turning the new system off and on again.
- [ ] Cleanup happens in small batches with sign-off, not all at once.

---

## Where this came from

Most of the explanation in this guide is based on [this deep-dive community article](https://pisinger.github.io/posts/sentinel-defender-unified-rbac-urbac-roles-permissions/) — it's an excellent, technically accurate breakdown. This guide simplifies its language and checks every fact against Microsoft's own documentation below.

- ⭐ Main source: [Sentinel in Defender Unified RBAC - Roles and Permissions](https://pisinger.github.io/posts/sentinel-defender-unified-rbac-urbac-roles-permissions/)
- [Unified RBAC overview and coexistence](https://learn.microsoft.com/en-us/defender-xdr/manage-rbac)
- [Activation, deactivation, prerequisites, and blockers](https://learn.microsoft.com/en-us/defender-xdr/activate-defender-rbac)
- [Sentinel role mapping (verified table above against this)](https://learn.microsoft.com/en-us/defender-xdr/compare-rbac-roles#microsoft-sentinel)
- [Unified RBAC permission catalog](https://learn.microsoft.com/en-us/defender-xdr/custom-permissions-details)
- [Plan the Defender portal transition](https://learn.microsoft.com/en-us/azure/sentinel/move-to-defender)
- [Current portal retirement timeline](https://learn.microsoft.com/azure/sentinel/overview#microsoft-sentinel-in-the-azure-portal-retirement-timeline)

---

*Prepared as a customer review artifact. Validate preview features and tenant-specific behavior immediately before production rollout.*
