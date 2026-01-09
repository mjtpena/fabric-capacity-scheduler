<#
.SYNOPSIS
    Resumes Azure Fabric Capacity (Capacity 01)
.DESCRIPTION
    This runbook resumes the first Fabric Capacity
    Called by Azure Automation at 8:00 AM on weekdays
#>

# Hardcoded parameters for this specific capacity
# TODO: Update these values with your actual Azure resource details
$CapacityName = "your-fabric-capacity-01"
$ResourceGroupName = "your-resource-group"
$SubscriptionId = "00000000-0000-0000-0000-000000000000"

try {
    # Connect using Managed Identity
    Write-Output "Connecting to Azure using Managed Identity..."
    Connect-AzAccount -Identity -Subscription $SubscriptionId | Out-Null
    
    Write-Output "Resuming Fabric Capacity: $CapacityName in Resource Group: $ResourceGroupName"
    
    # Check current state
    $capacity = Get-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName
    
    if ($null -eq $capacity) {
        throw "Capacity '$CapacityName' not found in resource group '$ResourceGroupName'"
    }
    
    Write-Output "Current capacity state: $($capacity.State)"
    
    if ($capacity.State -eq "Active") {
        Write-Output "Capacity is already active. No action needed."
    }
    elseif ($capacity.State -eq "Paused") {
        Write-Output "Resuming capacity..."
        Resume-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName
        Write-Output "Capacity '$CapacityName' has been resumed successfully."
    }
    else {
        Write-Warning "Capacity is in state '$($capacity.State)'. Cannot resume."
    }
}
catch {
    Write-Error "Failed to resume capacity: $_"
    throw
}
