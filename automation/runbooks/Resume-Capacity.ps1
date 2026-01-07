<#
.SYNOPSIS
    Resumes an Azure Fabric Capacity at the start of business hours
.DESCRIPTION
    This runbook resumes a paused Azure Fabric Capacity using the REST API
    Called by Azure Automation at 8:00 AM on weekdays
    Uses Managed Identity for authentication
.PARAMETER SubscriptionId
    The Azure subscription ID containing the capacity
.PARAMETER ResourceGroupName
    The resource group containing the capacity
.PARAMETER CapacityName
    The name of the Fabric Capacity to resume
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
    Write-Output "Starting resume operation for capacity: $CapacityName"
    
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
    
    # Build the resume URL
    $uri = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Fabric/capacities/$CapacityName/resume?api-version=2023-11-01"
    
    # Call the resume API
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Output "Calling resume API..."
    $response = Invoke-WebRequest -Uri $uri -Method POST -Headers $headers -UseBasicParsing
    Write-Output "API Response Status: $($response.StatusCode)"
    
    Write-Output "Successfully resumed Fabric Capacity: $CapacityName"
}
catch {
    Write-Error "Error resuming capacity: $_"
    throw
}
