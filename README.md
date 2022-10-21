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

# Step 2, User mapping - prepare

- **Setup JWT** auth in OEM licensed QS Saas tenant (1st one)
> [Qlik Help link](https://qlik.dev/tutorials/create-signed-tokens-for-jwt-authorization)

- Admin needs to manually **invite users** of choice to tenant
> [Qlik Help link](https://help.qlik.com/en-US/cloud-services/Subsystems/Hub/Content/Sense_Hub/Admin/SaaS-invite-users.htm#anchor-2)

-Please prepare **2_SaaS__ExportUsers.ps1** file with Admin/tenant details before continuing.

## Tenant Admin details

|Parameter                |Value                 | Comment |
|-------------------------|-----------------------------|----------|
|`$tenantURL=`            |'"https://\<TENANT ID>.eu.qlikcloud.com"'  ||
|`$pathToPFX=`            |"$(Get-Location)\certificates\text2.pfx"   ||
|`$pfxPass=`              |“\<PFX password>"||
|`$iss=`                   |“\<TENANT ID>.eu.qlikcloud.com"||
|`$kid=`                   |“\<Key ID from **Setup JWT** step above>"||
|`$adminSubject=`          |"auth0\|****************c4481cda860b8526bdaf3752f2a552b3ea4f4549293241fc“|IDP Subject for Admin User from Users list in QMC|
|`$adminName=`              |“\<Admin Name>"||
|`$adminEmail=`              |“\<Admin email>"||
|`$adminGroups=`              |"Domain Users“|If you don’t use Groups, please leave Domain Users as default|
