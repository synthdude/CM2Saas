# Leveraging Qlik CLI for CM to Saas migration

Migration of Qlik Sense content from Client Managed Qlik Sense on Windows (CM), to a Qlik Sense Saas tenant

# Preface

This document is aimed towards a Qlik Sense Saas Tenant admin, that seeks to automate the process of migrating content from CM (Client Managed QSE on Windows), to QSE Saas.

Content is made available as-is, and builds on documented tools and features provided by Qlik.

# Step 1, export

This section will attemt to export all content and objects, published on unpublished, from your Qlik Sense in Windows installation into folder(s) on your server locally.

- Generate **Certificate**
	> https://help.qlik.com/en-US/sense-admin/August2022/Subsystems/DeployAdministerQSE/Content/Sense_DeployAdminister/QSEoW/Administer_QSEoW/Managing_QSEoW/export-certificates.htm

- You will need to install **Certificate** into current user/personal certificates
- Put provided .ps1 scripts files into a folder on CM Qlik Sense server locally
- Open **PowerShell ISE** with Admin privileges
- Open/Run **1_CM_ExportAll.ps1** script to export all content from  
CM env into local temp folders. **PS Script will install Qlik-Cli if not already installed.**
- The following is executed by this script:
	> Creates Data folder and creates” \DATA\CM_UsersDatabase.csv” file
	
	> Loops through all Streams / Apps / Objects
	
	> The code Publishes / Approves all **private** Objects
	
	>Export Apps with full list of objects

	>Reverts private objects (step .3) **back to private status**

	>Exports Apps from personal ”My Work stream”
