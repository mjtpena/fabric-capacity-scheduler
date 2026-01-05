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

# Helper function to create schedule
function New-CapacitySchedule {
    param(
        [string]$ScheduleName,
        [string]$Description,
        [string]$RunbookName,
        [string]$Hour,
        [string]$ResourceGroupName,
        [string]$AutomationAccountName,
        [string]$CapacityName,
        [string]$CapacityResourceGroup
    )
    
    $startTime = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:00:00")
    
    Write-Output "Creating schedule: $ScheduleName"
    
    # Create schedule
    az automation schedule create `
        --resource-group $ResourceGroupName `
        --automation-account-name $AutomationAccountName `
        --name $ScheduleName `
        --frequency Day `
        --interval 1 `
        --start-time $startTime `
        --description $Description | Out-Null
    
    # Link schedule to runbook
    az automation job-schedule create `
        --resource-group $ResourceGroupName `
        --automation-account-name $AutomationAccountName `
        --schedule-name $ScheduleName `
        --runbook-name $RunbookName `
        --parameters @{ CapacityName=$CapacityName; ResourceGroupName=$CapacityResourceGroup } | Out-Null
    
    Write-Output "✓ Schedule '$ScheduleName' created and linked to '$RunbookName'"
}

# Remove existing schedules if they exist
Write-Output "`nCleaning up existing schedules..."
$scheduleNames = @("Fabric-Capacity-Resume-Weekdays", "Fabric-Capacity-Pause-Weekdays", "Fabric-Capacity-Pause-Weekend")
foreach ($scheduleName in $scheduleNames) {
    az automation schedule delete `
        --resource-group $ResourceGroupName `
        --automation-account-name $AutomationAccountName `
        --name $scheduleName `
        --yes 2>&1 | Out-Null
}

# Create schedules
Write-Output "`nCreating new schedules..."

# Create Resume Schedule (8:00 AM - Weekdays)
New-CapacitySchedule -ScheduleName "Fabric-Capacity-Resume-Weekdays" `
    -Description "Resume Fabric Capacity every weekday at 8:00 AM" `
    -RunbookName "Resume-Capacity" `
    -Hour "8" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -CapacityName $CapacityName `
    -CapacityResourceGroup $ResourceGroupName

# Create Pause Schedule (8:00 PM - Weekdays)
New-CapacitySchedule -ScheduleName "Fabric-Capacity-Pause-Weekdays" `
    -Description "Pause Fabric Capacity every weekday at 8:00 PM" `
    -RunbookName "Pause-Capacity" `
    -Hour "20" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -CapacityName $CapacityName `
    -CapacityResourceGroup $ResourceGroupName

# Create Weekend Pause Schedule (Saturday 12:00 AM)
New-CapacitySchedule -ScheduleName "Fabric-Capacity-Pause-Weekend" `
    -Description "Ensure Fabric Capacity is paused for the entire weekend" `
    -RunbookName "Pause-Capacity" `
    -Hour "0" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -CapacityName $CapacityName `
    -CapacityResourceGroup $ResourceGroupName

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
