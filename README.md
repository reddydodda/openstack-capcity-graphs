# OpenStack Capacity Report generation tools

## About:

This repository contains data extraction scripts used for pulling openstack Hypervisor and Instances metrics from all the Regions.

Automatic email is send to Team Mentioned.

Mail contains Following Attachments :

1. Host_Reports.csv

#### Headers ( Region Name,	Hypervisor_Hostname,	vcpus,	memory_mb,	 local_gb,	 vcpus_used,	 memory_used,	 local_gb_used,	 running_vms )

2. VM_Reports.csv

#### Headers ( Region Name,	Instance ID,	 Name,	 Hypervisor_Hostname,	 Status,	 VCPUs,	 Memory_MB,	 Root_gb,	 Ephemeral_gb,	 project_id,	 Project_Name )

3. Project_Report.csv

#### Headers (Project_id, Project Name)


## How to Setup:

1. Clone this repository 
	`git clone `
2. Create two new files named `.openrc_password` and `.mysql_password` at `$PWD/capacity-report
3. Add a crontab entry to run at 3 AM EST. Change frequency when needed.

`$crontab -e`
```
0 3 * * * PWD/cloud_report.sh > PWD/cloud_report.log 2>&1
```

## Adding Email ID:

To add new email id to reports, edit `mail_host.sh`, `mail_vm.sh` and `mail_project.sh` and append new email id at `CCEMAIL`

## Note:
1. When moving scripts to a different location change paths below with `cloud_report.sh`, `mail_vm.sh`, `mail_host.sh` and `mail_project`

```
path="new-path-location"
venv_path="new-path-to-openstack-dir"
```
