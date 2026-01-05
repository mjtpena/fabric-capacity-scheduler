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
- **Resume-Capacity.ps1**: Resumes the Fabric Capacity (runs at 8am weekdays)
- **Pause-Capacity.ps1**: Pauses the Fabric Capacity (runs at 8pm weekdays + all day weekends)

### 2. Configuration
Located in `scripts/`:
- **config.json**: Configuration file with your subscription, resource group, and capacity details

### 3. Deployment Scripts
Located in `scripts/`:
- **deploy-runbooks.ps1**: Deploys the runbooks to Azure Automation Account
- **create-schedules.ps1**: Creates the automation schedules for the capacity

## Prerequisites

- Azure Subscription with Fabric Capacity
- Azure Automation Account
- PowerShell 5.1 or later (or PowerShell 7+)
- Az PowerShell modules installed
- Appropriate RBAC permissions (Contributor or higher on the Automation Account and Fabric Capacity resources)

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

### Step 3: Verify Run As Account

Ensure your Automation Account has a **"Run As Account"** (classic) for authentication. This is required for the runbooks to execute with proper permissions.

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
- Verify the Automation Account has a valid "Run As Account"
- Check that the schedules are properly linked to the runbooks
- Review job history in the Azure Portal for error details

### Authentication Failures
- Ensure the Run As Account has proper RBAC permissions on the Fabric Capacity
- Verify the subscription and resource group names in the config

### Timezone Issues
- Update the `timezone` field in config.json to match your location
- Azure Automation schedules use UTC by default; check timezone settings in the Portal

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

# Delete runbooks
az automation runbook delete --resource-group "your-rg" --automation-account-name "your-account" --name "Resume-Capacity" --yes
az automation runbook delete --resource-group "your-rg" --automation-account-name "your-account" --name "Pause-Capacity" --yes

# Manually resume capacity if needed
az resource update --resource-group "your-rg" --name "your-capacity-name" --resource-type "Microsoft.Fabric/capacities" --set "properties.state=Active"
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
