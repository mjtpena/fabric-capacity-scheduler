<#
.SYNOPSIS
    Pauses an Azure Fabric Capacity outside of business hours
.DESCRIPTION
    This runbook pauses an active Azure Fabric Capacity using the REST API
    Called by Azure Automation at 8:00 PM on weekdays and all day on weekends
    Uses Managed Identity for authentication
.PARAMETER SubscriptionId
    The Azure subscription ID containing the capacity
.PARAMETER ResourceGroupName
    The resource group containing the capacity
.PARAMETER CapacityName
    The name of the Fabric Capacity to pause
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$CapacityName
)

try {
    Write-Output "Starting pause operation for capacity: $CapacityName"
    
    # Connect using Managed Identity
    Connect-AzAccount -Identity | Out-Null
    Write-Output "Connected using Managed Identity."
    
    # Get token for Azure Management API using SecureString (required for newer Az.Accounts)
    $tokenResponse = Get-AzAccessToken -ResourceUrl "https://management.azure.com" -AsSecureString
    $ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenResponse.Token)
    try {
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
    }
    Write-Output "Acquired access token."
    
    # Build the suspend URL
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Fabric/capacities/$CapacityName/suspend?api-version=2023-11-01"
    
    # Call the suspend API
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Output "Calling suspend API..."
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -UseBasicParsing
    Write-Output "API Response Status: $($response.StatusCode)"
    
    Write-Output "Successfully paused Fabric Capacity: $CapacityName"
}
catch {
    Write-Error "Error pausing capacity: $_"
    throw
}
