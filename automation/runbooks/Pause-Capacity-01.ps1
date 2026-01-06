<#
.SYNOPSIS
    Pauses Azure Fabric Capacity fabricdofnetzeroause01
.DESCRIPTION
    This runbook pauses the fabricdofnetzeroause01 Fabric Capacity
    Called by Azure Automation at 8:00 PM on weekdays and weekends
#>

# Hardcoded parameters for this specific capacity
$CapacityName = "fabricdofnetzeroause01"
$ResourceGroupName = "RG-DoF-NetZero-DevPTS"

try {
    # Connect using Managed Identity
    Write-Output "Connecting to Azure using Managed Identity..."
    Connect-AzAccount -Identity | Out-Null
    
    Write-Output "Pausing Fabric Capacity: $CapacityName in Resource Group: $ResourceGroupName"
    
    # Check current state
    $capacity = Get-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName
    
    if ($null -eq $capacity) {
        throw "Capacity '$CapacityName' not found in resource group '$ResourceGroupName'"
    }
    
    Write-Output "Current capacity state: $($capacity.State)"
    
    if ($capacity.State -eq "Paused") {
        Write-Output "Capacity is already paused. No action needed."
    }
    elseif ($capacity.State -eq "Active") {
        Write-Output "Suspending capacity..."
        Suspend-AzFabricCapacity -ResourceGroupName $ResourceGroupName -CapacityName $CapacityName
        Write-Output "Capacity '$CapacityName' has been paused successfully."
    }
    else {
        Write-Warning "Capacity is in state '$($capacity.State)'. Cannot pause."
    }
}
catch {
    Write-Error "Failed to pause capacity: $_"
    throw
}
