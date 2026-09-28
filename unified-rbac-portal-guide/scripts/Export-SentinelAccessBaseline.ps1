[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path $PWD "sentinel-access-baseline")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$requiredModules = "Az.Accounts", "Az.Resources"
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        throw "Required module '$module' is not installed. Install it before running this read-only inventory."
    }
}

Import-Module Az.Accounts
Import-Module Az.Resources

$context = Get-AzContext
if (-not $context) {
    throw "No Azure context is available. Run Connect-AzAccount first."
}

Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
$context = Get-AzContext

$subscriptionScope = "/subscriptions/$SubscriptionId"
$resourceGroupScope = "$subscriptionScope/resourceGroups/$ResourceGroupName"
$workspaceScope = "$resourceGroupScope/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName"

$null = Get-AzResourceGroup -Name $ResourceGroupName
$workspace = Get-AzResource -ResourceId $workspaceScope
if (-not $workspace) {
    throw "Workspace '$workspaceScope' was not found or is not visible to the current identity."
}

$resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
New-Item -ItemType Directory -Path $resolvedOutputPath -Force | Out-Null

$scopeRecords = @(
    [pscustomobject]@{ ScopeLevel = "Subscription"; Scope = $subscriptionScope }
    [pscustomobject]@{ ScopeLevel = "ResourceGroup"; Scope = $resourceGroupScope }
    [pscustomobject]@{ ScopeLevel = "Workspace"; Scope = $workspaceScope }
)

$assignments = foreach ($scopeRecord in $scopeRecords) {
    Get-AzRoleAssignment -Scope $scopeRecord.Scope |
        Select-Object @{
            Name = "QueriedScopeLevel"
            Expression = { $scopeRecord.ScopeLevel }
        }, @{
            Name = "QueriedScope"
            Expression = { $scopeRecord.Scope }
        }, RoleAssignmentId, RoleDefinitionId, RoleDefinitionName, Scope,
        DisplayName, SignInName, ObjectType, ObjectId, CanDelegate,
        Condition, ConditionVersion
}

$assignments |
    Sort-Object RoleAssignmentId -Unique |
    Export-Csv -Path (Join-Path $resolvedOutputPath "azure-role-assignments.csv") -NoTypeInformation -Encoding utf8

$roleDefinitions = Get-AzRoleDefinition |
    Where-Object {
        $_.Name -match "Sentinel|Defender|Security|Log Analytics|Workbook|Logic App|Monitoring"
    } |
    Select-Object Name, Id, IsCustom, Description, Actions, NotActions, DataActions, NotDataActions, AssignableScopes

$roleDefinitions |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path (Join-Path $resolvedOutputPath "relevant-role-definitions.json") -Encoding utf8

$manifest = [ordered]@{
    ExportedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    TenantId = $context.Tenant.Id
    SubscriptionId = $context.Subscription.Id
    SubscriptionName = $context.Subscription.Name
    Account = $context.Account.Id
    ResourceGroupName = $ResourceGroupName
    WorkspaceName = $WorkspaceName
    WorkspaceResourceId = $workspaceScope
    ScopesQueried = $scopeRecords
    Notes = @(
        "This export is read-only.",
        "Review management-group inheritance, Entra roles, PIM, transitive groups, service principals, managed identities, Azure Lighthouse, and GDAP separately.",
        "Export Unified RBAC roles separately from the Microsoft Defender portal.",
        "Do not remove assignments solely because they contain Sentinel or Defender in the role name."
    )
}

$manifest |
    ConvertTo-Json -Depth 10 |
    Set-Content -Path (Join-Path $resolvedOutputPath "manifest.json") -Encoding utf8

Write-Host "Baseline exported to '$resolvedOutputPath'."
Write-Host "No Azure permissions were changed."
