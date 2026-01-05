<#
.SYNOPSIS
    Deploys PowerShell runbooks to Azure Automation Account using Azure CLI
.DESCRIPTION
    This script uploads the Resume-Capacity and Pause-Capacity runbooks
    to your Azure Automation Account using az cli commands
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName
)

Write-Output "Deploying runbooks..."
Write-Output "  Subscription: $SubscriptionId"
Write-Output "  Resource Group: $ResourceGroupName"
Write-Output "  Automation Account: $AutomationAccountName"

# Set subscription
Write-Output "`nSetting subscription context..."
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription"
    exit 1
}

# Define runbook files
$runbookPath = "../automation/runbooks"
$runbooks = @(
    @{
        Name = "Resume-Capacity"
        Path = Join-Path $runbookPath "Resume-Capacity.ps1"
        Description = "Resumes Azure Fabric Capacity at 8:00 AM on weekdays"
    },
    @{
        Name = "Pause-Capacity"
        Path = Join-Path $runbookPath "Pause-Capacity.ps1"
        Description = "Pauses Azure Fabric Capacity at 8:00 PM on weekdays and all day on weekends"
    }
)

# Import and publish runbooks
Write-Output "`nImporting runbooks..."
foreach ($runbook in $runbooks) {
    if (-not (Test-Path $runbook.Path)) {
        Write-Error "Runbook file not found: $($runbook.Path)"
        exit 1
    }
    
    Write-Output "Importing: $($runbook.Name)"
    
    # Create runbook
    az automation runbook create `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $runbook.Name `
        --type PowerShell `
        --description $runbook.Description | Out-Null
    
    # Import content
    az automation runbook content update `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $runbook.Name `
        --content (Get-Content $runbook.Path -Raw) | Out-Null
    
    # Publish runbook
    az automation runbook publish `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $runbook.Name | Out-Null
    
    Write-Output "✓ $($runbook.Name) imported and published"
}

Write-Output "`n✓ Runbooks deployed successfully!"
Write-Output "`nNext step: Run create-schedules.ps1 to set up automation schedules"
