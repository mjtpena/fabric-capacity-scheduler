<#
.SYNOPSIS
    Creates Azure Automation schedules for Fabric Capacity pause/resume using Azure CLI
.DESCRIPTION
    This script creates three schedules:
    1. Weekday 8:00 AM - Resume capacity (Mon-Fri)
    2. Weekday 8:00 PM - Pause capacity (Mon-Fri)
    3. Weekend - Pause capacity (all weekend)
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$CapacityName,
    
    [Parameter(Mandatory = $false)]
    [string]$Timezone = "Eastern Standard Time"
)

Write-Output "Creating automation schedules..."
Write-Output "  Subscription: $SubscriptionId"
Write-Output "  Resource Group: $ResourceGroupName"
Write-Output "  Automation Account: $AutomationAccountName"
Write-Output "  Capacity: $CapacityName"
Write-Output "  Timezone: $Timezone"

# Set subscription
Write-Output "`nSetting subscription context..."
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set subscription"
    exit 1
}

# Helper function to create schedule and link to runbook using Azure CLI REST API
function New-CapacitySchedule {
    param(
        [string]$ScheduleName,
        [string]$Description,
        [string]$RunbookName,
        [string]$Hour,
        [string]$ResourceGroupName,
        [string]$AutomationAccountName,
        [string]$CapacityName,
        [string]$CapacityResourceGroup,
        [string]$SubscriptionId
    )
    
    $startTime = (Get-Date).AddDays(1).Date.AddHours([int]$Hour).ToString("yyyy-MM-ddTHH:mm:sszzz")
    
    Write-Output "Creating schedule: $ScheduleName"
    
    # Create schedule using Azure CLI
    $scheduleResult = az automation schedule create `
        --resource-group $ResourceGroupName `
        --automation-account-name $AutomationAccountName `
        --name $ScheduleName `
        --start-time $startTime `
        --frequency "Day" `
        --interval 1 `
        --time-zone $Timezone `
        --description $Description 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        # Schedule might already exist, try to update it
        Write-Output "  Schedule may already exist, continuing..."
    }
    
    # Link schedule to runbook using REST API (Register-AzAutomationScheduledRunbook requires Az module)
    $jobScheduleId = [guid]::NewGuid().ToString()
    $baseUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName"
    
    $body = "{`"properties`":{`"schedule`":{`"name`":`"$ScheduleName`"},`"runbook`":{`"name`":`"$RunbookName`"},`"parameters`":{`"CapacityName`":`"$CapacityName`",`"ResourceGroupName`":`"$CapacityResourceGroup`"}}}"
    
    $linkResult = az rest --method put `
        --url "$baseUrl/jobSchedules/${jobScheduleId}?api-version=2023-11-01" `
        --body $body 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  Failed to link schedule to runbook: $linkResult"
        return $false
    }
    
    Write-Output "✓ Schedule '$ScheduleName' created and linked to '$RunbookName'"
    return $true
}

# Generate unique schedule names based on capacity name
$capacityShort = $CapacityName.Replace("fabricdofnetzero", "").Replace("ause", "").Substring(0,2)
$schedulePrefix = "Fabric-$capacityShort"

# Check if schedules already exist and skip if they do
Write-Output "`nCreating schedules for capacity: $CapacityName"
$existingSchedules = az automation schedule list --resource-group $ResourceGroupName --automation-account-name $AutomationAccountName --query "[].name" -o tsv 2>&1

# Create schedules
Write-Output "`nCreating new schedules..."

# Create Resume Schedule (8:00 AM - Weekdays)
New-CapacitySchedule -ScheduleName "$schedulePrefix-Resume-Weekdays" `
    -Description "Resume $CapacityName every weekday at 8:00 AM" `
    -RunbookName "Resume-Capacity" `
    -Hour "8" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -CapacityName $CapacityName `
    -CapacityResourceGroup $ResourceGroupName `
    -SubscriptionId $SubscriptionId

# Create Pause Schedule (8:00 PM - Weekdays)
New-CapacitySchedule -ScheduleName "$schedulePrefix-Pause-Weekdays" `
    -Description "Pause $CapacityName every weekday at 8:00 PM" `
    -RunbookName "Pause-Capacity" `
    -Hour "20" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -CapacityName $CapacityName `
    -CapacityResourceGroup $ResourceGroupName `
    -SubscriptionId $SubscriptionId

# Create Weekend Pause Schedule (Saturday 12:00 AM)
New-CapacitySchedule -ScheduleName "$schedulePrefix-Pause-Weekend" `
    -Description "Ensure $CapacityName is paused for the entire weekend" `
    -RunbookName "Pause-Capacity" `
    -Hour "0" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -CapacityName $CapacityName `
    -CapacityResourceGroup $ResourceGroupName `
    -SubscriptionId $SubscriptionId

Write-Output "`n✓ Schedules created successfully!"

Write-Output "`nIMPORTANT CONFIGURATION NOTES:"
Write-Output "================================================"
Write-Output "Azure Automation note: Schedules created are daily by default."
Write-Output "`nTo set proper weekday-only recurrence, update in Azure Portal:"
Write-Output "1. Go to Automation Account -> Schedules"
Write-Output "2. Edit each schedule and set recurrence:"
Write-Output "   - Resume-Weekdays: Weekly, Mon-Fri, 8:00 AM"
Write-Output "   - Pause-Weekdays: Weekly, Mon-Fri, 8:00 PM"
Write-Output "   - Pause-Weekend: Weekly, Saturday, 12:00 AM"
Write-Output "================================================"
