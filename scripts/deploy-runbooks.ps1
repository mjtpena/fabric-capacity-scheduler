<#
.SYNOPSIS
    Deploys PowerShell runbooks to Azure Automation Account using Azure CLI
.DESCRIPTION
    This script uploads the Resume-Capacity and Pause-Capacity runbooks
    to your Azure Automation Account using az cli commands.
    It also ensures the required Az.Fabric module is imported.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipModuleImport
)

Write-Output "========================================"
Write-Output "Deploying Fabric Capacity Runbooks"
Write-Output "========================================"
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

# Import required modules (Az.Fabric)
if (-not $SkipModuleImport) {
    Write-Output "`n========================================"
    Write-Output "Step 1: Importing Required Modules"
    Write-Output "========================================"
    
    # Check if Az.Fabric module exists and is ready
    $fabricModule = az automation module show `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name "Az.Fabric" `
        --output json 2>$null | ConvertFrom-Json
    
    if ($fabricModule -and $fabricModule.provisioningState -eq "Succeeded") {
        Write-Output "✓ Az.Fabric module is already available"
    }
    else {
        Write-Output "Importing Az.Fabric module from PowerShell Gallery..."
        Write-Output "This module provides: Get-AzFabricCapacity, Suspend-AzFabricCapacity, Resume-AzFabricCapacity"
        
        $result = az automation module create `
            --automation-account-name $AutomationAccountName `
            --resource-group $ResourceGroupName `
            --name "Az.Fabric" `
            --content-link-uri "https://www.powershellgallery.com/api/v2/package/Az.Fabric/1.0.0" `
            --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Output "✓ Module import initiated"
            Write-Output ""
            Write-Output "⚠ IMPORTANT: Module import takes 5-10 minutes to complete."
            Write-Output "  The runbooks will fail until the module is fully available."
            Write-Output "  Check module status in Azure Portal:"
            Write-Output "  Automation Account > Shared Resources > Modules > Az.Fabric"
            Write-Output ""
        }
        else {
            Write-Warning "Module import may have failed. Check Azure Portal to verify."
            Write-Warning "You can also run: .\import-modules.ps1 separately"
        }
    }
}
else {
    Write-Output "`nSkipping module import (use -SkipModuleImport:$false to import)"
}

Write-Output "`n========================================"
Write-Output "Step 2: Deploying Runbooks"
Write-Output "========================================"

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
