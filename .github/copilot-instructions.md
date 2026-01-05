# Fabric Capacity Scheduler - Project Instructions

This project provides Azure Automation runbooks to schedule Azure Fabric Capacity operations.

## Project Overview
- **Purpose**: Automate pausing/resuming Azure Fabric Capacity based on business hours (8am-8pm Mon-Fri)
- **Technology**: PowerShell, Azure Automation, Azure Fabric
- **Type**: Infrastructure Automation

## Key Files
- `automation/runbooks/Resume-Capacity.ps1` - Resumes the capacity at 8am
- `automation/runbooks/Pause-Capacity.ps1` - Pauses the capacity at 8pm
- `scripts/config.json` - Configuration settings
- `scripts/deploy-runbooks.ps1` - Deployment script
- `scripts/create-schedules.ps1` - Schedule creation script

## Development Guidelines
- Update `scripts/config.json` with your actual Azure resource details
- Test runbooks in non-production environment first
- Monitor Azure Automation job history for execution status
- Adjust timezone in config.json to match your region

## Deployment
Run `scripts/deploy-runbooks.ps1` to deploy runbooks to your Automation Account.
Then run `scripts/create-schedules.ps1` to create the automation schedules.
