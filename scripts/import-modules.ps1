<#
.SYNOPSIS
    Imports required PowerShell modules to Azure Automation Account
.DESCRIPTION
    This script imports the Az.Fabric module (and its dependency Az.Accounts)
    to the Azure Automation Account. These modules are required for the
    Fabric Capacity runbooks to work.
    
    Required modules:
    - Az.Accounts (dependency, usually pre-installed)
    - Az.Fabric (for Get-AzFabricCapacity, Suspend-AzFabricCapacity, Resume-AzFabricCapacity)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$RuntimeVersion = "5.1"  # PowerShell runtime version: "5.1" or "7.2"
)

Write-Output "========================================"
Write-Output "Importing Required Modules"
Write-Output "========================================"
Write-Output "  Subscription: $SubscriptionId"
Write-Output "  Resource Group: $ResourceGroupName"
Write-Output "  Automation Account: $AutomationAccountName"
Write-Output "  Runtime Version: $RuntimeVersion"
Write-Output ""

# Set subscription context
Write-Output "Setting subscription context..."
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription. Make sure you're logged in with 'az login'"
    exit 1
}

# Define modules to import
# Az.Fabric depends on Az.Accounts, which is usually pre-installed
$modules = @(
    @{
        Name = "Az.Accounts"
        Version = "3.0.5"  # Latest stable version
        ContentLinkUri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts/3.0.5"
        Description = "Azure Accounts module - required for Azure authentication"
    },
    @{
        Name = "Az.Fabric"
        Version = "1.0.0"  # Latest stable version
        ContentLinkUri = "https://www.powershellgallery.com/api/v2/package/Az.Fabric/1.0.0"
        Description = "Azure Fabric module - required for Fabric Capacity operations"
    }
)

Write-Output ""
Write-Output "Checking and importing modules..."
Write-Output ""

foreach ($module in $modules) {
    Write-Output "Processing module: $($module.Name) v$($module.Version)"
    
    # Check if module already exists
    $existingModule = az automation module show `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $module.Name `
        --output json 2>$null | ConvertFrom-Json
    
    if ($existingModule) {
        Write-Output "  Module '$($module.Name)' already exists (Provisioning State: $($existingModule.provisioningState))"
        
        if ($existingModule.provisioningState -eq "Succeeded") {
            Write-Output "  ✓ Module is ready to use"
            continue
        }
        elseif ($existingModule.provisioningState -eq "Creating" -or $existingModule.provisioningState -eq "Running") {
            Write-Output "  ⏳ Module is still being provisioned. Please wait..."
            continue
        }
        else {
            Write-Output "  ⚠ Module is in state '$($existingModule.provisioningState)'. Attempting to re-import..."
        }
    }
    
    Write-Output "  Importing module from PowerShell Gallery..."
    
    # Import the module using Azure CLI
    $result = az automation module create `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $module.Name `
        --content-link-uri $module.ContentLinkUri `
        --output json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "  ✓ Module import initiated successfully"
        Write-Output "  ⏳ Note: Module import can take several minutes to complete"
    }
    else {
        Write-Warning "  Failed to import module: $result"
        Write-Output "  You may need to import this module manually via the Azure Portal"
    }
    
    Write-Output ""
}

Write-Output "========================================"
Write-Output "Module Import Summary"
Write-Output "========================================"
Write-Output ""
Write-Output "Checking module status..."

# Wait a moment for Azure to register the import requests
Start-Sleep -Seconds 5

foreach ($module in $modules) {
    $moduleStatus = az automation module show `
        --automation-account-name $AutomationAccountName `
        --resource-group $ResourceGroupName `
        --name $module.Name `
        --output json 2>$null | ConvertFrom-Json
    
    if ($moduleStatus) {
        $status = $moduleStatus.provisioningState
        $icon = switch ($status) {
            "Succeeded" { "✓" }
            "Creating" { "⏳" }
            "Running" { "⏳" }
            "Failed" { "✗" }
            default { "?" }
        }
        Write-Output "  $icon $($module.Name): $status"
    }
    else {
        Write-Output "  ? $($module.Name): Not found"
    }
}

Write-Output ""
Write-Output "========================================"
Write-Output "IMPORTANT NOTES"
Write-Output "========================================"
Write-Output ""
Write-Output "1. Module imports can take 5-10 minutes to complete."
Write-Output ""
Write-Output "2. To check module status in Azure Portal:"
Write-Output "   - Go to your Automation Account"
Write-Output "   - Navigate to 'Shared Resources' > 'Modules'"
Write-Output "   - Verify Az.Fabric shows status 'Available'"
Write-Output ""
Write-Output "3. If using PowerShell 7.2 runtime, you may need to import"
Write-Output "   modules separately for that runtime version."
Write-Output ""
Write-Output "4. Alternative: Import via Azure Portal"
Write-Output "   - Go to Automation Account > Modules > Browse gallery"
Write-Output "   - Search for 'Az.Fabric' and click Import"
Write-Output ""
Write-Output "Run this script again to check updated status."
