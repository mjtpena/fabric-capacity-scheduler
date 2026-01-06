# Azure Fabric Capacity Scheduler

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Automatically pause and resume Azure Fabric Capacity based on business hours (8am-8pm Mon-Fri) and timezone. Save up to 60% on Fabric capacity costs by turning off capacity outside business hours.

## Features

✅ **Automatic Scheduling** - Resume at 8 AM, pause at 8 PM (Mon-Fri)  
✅ **Weekend Protection** - Capacity stays paused all weekend  
✅ **Timezone Support** - Works with any Azure timezone  
✅ **Zero Configuration** - Command-line driven, no config files needed  
✅ **Cost Optimization** - Significant savings on Fabric capacity costs

## Solution Architecture

This solution uses **Azure Automation runbooks** with PowerShell to automatically pause and resume your Fabric Capacity based on a schedule.

### Schedule
- **Enabled**: Monday to Friday, 8:00 AM - 8:00 PM
- **Disabled**: All other times (weekends and outside business hours)

## Components

### 1. PowerShell Runbooks
Located in `automation/runbooks/`:

**Generic Runbooks (with parameters):**
- **Resume-Capacity.ps1**: Resumes a Fabric Capacity (requires CapacityName and ResourceGroupName parameters)
- **Pause-Capacity.ps1**: Pauses a Fabric Capacity (requires CapacityName and ResourceGroupName parameters)

**Capacity-Specific Runbooks (recommended for scheduled automation):**
- **Resume-Capacity-01.ps1**: Resumes fabricdofnetzeroause01 (hardcoded, no parameters needed)
- **Resume-Capacity-02.ps1**: Resumes fabricdofnetzeroause02 (hardcoded, no parameters needed)
- **Pause-Capacity-01.ps1**: Pauses fabricdofnetzeroause01 (hardcoded, no parameters needed)
- **Pause-Capacity-02.ps1**: Pauses fabricdofnetzeroause02 (hardcoded, no parameters needed)

> **Note**: Capacity-specific runbooks are more reliable for scheduled automation because Azure Automation job schedules can sometimes lose parameter values.

### 2. Configuration
Located in `scripts/`:
- **config.json**: Configuration file with your subscription, resource group, and capacity details

### 3. Deployment Scripts
Located in `scripts/`:
- **deploy-runbooks.ps1**: Deploys the runbooks to Azure Automation Account
- **create-schedules.ps1**: Creates the automation schedules for the capacity

## Prerequisites

- Azure Subscription with Fabric Capacity
- Azure Automation Account with **System-Assigned Managed Identity** enabled
- PowerShell 5.1 or later (or PowerShell 7+)
- Azure CLI installed and authenticated
- Appropriate RBAC permissions:
  - Contributor on the Automation Account
  - Contributor on the Fabric Capacity resources
  - The Automation Account's Managed Identity needs Contributor role on the Fabric Capacity

## Setup Instructions

### Step 1: Deploy Runbooks

Run this command from the `scripts` folder:

```powershell
cd scripts
.\deploy-runbooks.ps1 `
  -SubscriptionId "your-subscription-id" `
  -ResourceGroupName "your-resource-group" `
  -AutomationAccountName "your-automation-account"
```

### Step 2: Create Schedules

```powershell
.\create-schedules.ps1 `
  -SubscriptionId "your-subscription-id" `
  -ResourceGroupName "your-resource-group" `
  -AutomationAccountName "your-automation-account" `
  -CapacityName "your-fabric-capacity-name" `
  -Timezone "Eastern Standard Time"
```

**Optional**: Use any [Azure timezone](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones) (e.g., "AUS Eastern Standard Time", "Pacific Standard Time")

### Multiple Capacities

Run the schedule creation script once for each capacity:

```powershell
.\create-schedules.ps1 -SubscriptionId "..." -ResourceGroupName "..." `
  -AutomationAccountName "..." -CapacityName "fabric-capacity-1" -Timezone "..."

.\create-schedules.ps1 -SubscriptionId "..." -ResourceGroupName "..." `
  -AutomationAccountName "..." -CapacityName "fabric-capacity-2" -Timezone "..."
```

Each capacity gets its own unique set of schedules.

### Step 3: Configure Managed Identity

Ensure your Automation Account has a **System-Assigned Managed Identity** enabled:

1. Go to your Automation Account in Azure Portal
2. Navigate to **Identity** under Account Settings
3. Enable **System assigned** managed identity
4. Grant the managed identity **Contributor** role on your Fabric Capacity resources

> **Note**: The runbooks use `Connect-AzAccount -Identity` for authentication via Managed Identity. The legacy "Run As Account" is deprecated.

## How It Works

### Resume Schedule (Weekday 8 AM)
- Triggers at 8:00 AM every Monday through Friday
- Calls the Resume-Capacity runbook
- Your Fabric Capacity becomes available

### Pause Schedule (Weekday 8 PM)
- Triggers at 8:00 PM every Monday through Friday
- Calls the Pause-Capacity runbook
- Your Fabric Capacity is suspended, saving costs

### Weekend Pause Schedule (Always Off)
- Triggers at midnight on Saturday morning
- Ensures capacity is paused for the entire weekend

## Monitoring

Monitor the runbook execution in the Azure Portal:
1. Navigate to your Automation Account
2. Click on "Jobs" to see execution history
3. Check for any failed runs and review the error details

## Troubleshooting

### Runbooks Not Executing
- Verify the Automation Account has Managed Identity enabled
- Check that the schedules are properly linked to the runbooks (see Azure Portal → Automation Account → Schedules → Linked runbooks)
- Review job history in the Azure Portal for error details

### Authentication Failures
- Ensure the Managed Identity has Contributor RBAC permissions on the Fabric Capacity
- Verify the subscription and resource group names in the runbook
- Check that Az.Accounts and Az.Fabric modules are available in the Automation Account

### Schedule Not Linked to Runbook
- Azure Automation job schedules can silently fail to link. Verify in Azure Portal that each schedule shows the correct runbook under "Linked runbooks"
- Use capacity-specific runbooks (e.g., Pause-Capacity-01.ps1) which don't require parameters

## Cost Optimization

By using this scheduler, you'll only pay for:
- The Fabric Capacity when it's in use (8am-8pm weekdays)
- Minimal Azure Automation costs (based on runbook execution count)

**Estimated monthly savings**: Up to 60% of capacity costs (weekends + nights off)

## Rollback
```powershell
# Delete schedules
az automation schedule delete --resource-group "your-rg" --automation-account-name "your-account" --name "Fabric-Capacity-Resume-Weekdays" --yes
az automation schedule delete --resource-group "your-rg" --automation-account-name "your-account" --name "Fabric-Capacity-Pause-Weekdays" --yes
az automation schedule delete --resource-group "your-rg" --automation-account-name "your-account" --name "Fabric-Capacity-Pause-Weekend" --yes

# Delete runbooks (generic)
az automation runbook delete --resource-group "your-rg" --automation-account-name "your-account" --name "Resume-Capacity" --yes
az automation runbook delete --resource-group "your-rg" --automation-account-name "your-account" --name "Pause-Capacity" --yes

# Delete runbooks (capacity-specific, if created)
az automation runbook delete --resource-group "your-rg" --automation-account-name "your-account" --name "Resume-Capacity-01" --yes
az automation runbook delete --resource-group "your-rg" --automation-account-name "your-account" --name "Pause-Capacity-01" --yes

# Manually resume capacity if needed
az fabric capacity resume --resource-group "your-rg" --capacity-name "your-capacity-name"
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Azure Automation Documentation](https://docs.microsoft.com/azure/automation/)
- 📖 [Azure Fabric Documentation](https://learn.microsoft.com/fabric/)
- 🐛 [Report Issues](https://github.com/YOUR-USERNAME/fabric-capacity-scheduler/issues)t
2. Delete or disable the runbooks
3. Manually resume your Fabric Capacity if needed
