# Fabric Capacity Scheduler - Project Instructions

This project provides Azure Automation runbooks to schedule Azure Fabric Capacity operations.

## Project Overview
- **Purpose**: Automate pausing/resuming Azure Fabric Capacity based on business hours (8am-8pm Mon-Fri)
- **Technology**: PowerShell, Azure Automation, Azure Fabric
- **Type**: Infrastructure Automation

## Key Files
- `automation/runbooks/Resume-Capacity.ps1` - Generic resume runbook (with parameters)
- `automation/runbooks/Pause-Capacity.ps1` - Generic pause runbook (with parameters)
- `automation/runbooks/Resume-Capacity-01.ps1` - Resume first capacity (hardcoded)
- `automation/runbooks/Resume-Capacity-02.ps1` - Resume second capacity (hardcoded)
- `automation/runbooks/Pause-Capacity-01.ps1` - Pause first capacity (hardcoded)
- `automation/runbooks/Pause-Capacity-02.ps1` - Pause second capacity (hardcoded)
- `scripts/config.example.json` - Example configuration (copy to config.json)
- `scripts/config.json` - Local configuration (gitignored)
- `scripts/deploy-runbooks.ps1` - Deployment script
- `scripts/create-schedules.ps1` - Schedule creation script

## Development Guidelines
- Copy `scripts/config.example.json` to `scripts/config.json` and update with your Azure resource details
- Update hardcoded values in the capacity-specific runbooks before deploying
- Test runbooks in non-production environment first
- Monitor Azure Automation job history for execution status
- Adjust timezone in config.json to match your region

## Deployment
Run `scripts/deploy-runbooks.ps1` to deploy runbooks to your Automation Account.
Then run `scripts/create-schedules.ps1` to create the automation schedules.
