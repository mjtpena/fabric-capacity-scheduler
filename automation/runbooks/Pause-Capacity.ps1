<#
.SYNOPSIS
    Pauses an Azure Fabric Capacity outside of business hours
.DESCRIPTION
    This runbook pauses an active Azure Fabric Capacity
    Called by Azure Automation at 8:00 PM on weekdays and all day on weekends
.PARAMETER CapacityName
    The name of the Fabric Capacity to pause
.PARAMETER ResourceGroupName
    The resource group containing the capacity
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$CapacityName,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName
)

# Use Run As Account for authentication
$AzureRunAsConnectionName = "AzureRunAsConnection"

try {
    # Get the connection
    $AzureRunAsConnection = Get-AutomationConnection -Name $AzureRunAsConnectionName
    
    if ($null -eq $AzureRunAsConnection) {
        throw "Connection $AzureRunAsConnectionName not found in Automation Account"
    }
    
    Write-Output "Connecting to Azure using Run As Account..."
    Add-AzAccount -ServicePrincipal `
        -TenantId $AzureRunAsConnection.TenantId `
        -ApplicationId $AzureRunAsConnection.ApplicationId `
        -CertificateThumbprint $AzureRunAsConnection.CertificateThumbprint | Out-Null
    
    # Set the subscription context
    Set-AzContext -SubscriptionId $AzureRunAsConnection.SubscriptionId | Out-Null
    
    if ([string]::IsNullOrEmpty($CapacityName)) {
        throw "CapacityName parameter is required"
    }
    if ([string]::IsNullOrEmpty($ResourceGroupName)) {
        throw "ResourceGroupName parameter is required"
    }
    
    Write-Output "Pausing Fabric Capacity: $CapacityName in Resource Group: $ResourceGroupName"
    
    # Pause the capacity
    $capacity = Update-AzCapacity -Name $CapacityName -ResourceGroupName $ResourceGroupName -State "Paused"
    
    if ($capacity.State -eq "Paused") {
        Write-Output "Successfully paused Fabric Capacity: $CapacityName"
        Write-Output "Capacity State: $($capacity.State)"
    }
    else {
        Write-Output "Capacity state after update: $($capacity.State)"
    }
}
catch {
    Write-Error "Error pausing capacity: $_"
    throw
}
