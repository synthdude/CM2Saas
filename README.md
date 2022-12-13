This document is aimed towards a Qlik Sense Saas Tenant admin, that seeks to automate the process of migrating content from CM (Client Managed QSE on Windows), to QSE Saas.

# Prerequisites
* *License*: Make sure the Qlik SaaS license has the number of users plus one you want to move private objects for.
* *Qlik-CLI*: Please install Qlik-CLI from here (https://github.com/ahaydon/Qlik-Cli-Windows)
* *Environment*: This tool should be run locally on the Qlik Sense Server machine using an administrative account. Alternatively this tool can be run from another computer, but then Qlik Sense Server certificates needs to be exported and imported/installed into cert store with "Friendly Name" as "QlikClient".
* *multitenancy*: This tool doesn’t included distribution of content across multiple target tenants, but it can be changed to do so. So with the currently release you can migrate from 1 CM site to 1 Qlik Cloud tenant.
* *Script and Github*: The script can be downloaded from: [The github repo of this migration tool](https://github.com/synthdude/CM2Saas/)
* *Stream Names*: Please check that no Streams on QLik Sense Server contains single quotes [ ' ].

Note: Content is made available as-is, and builds on documented tools and features provided by Qlik.

# Step 1, export

This section will attempt to export all content and objects, published on unpublished, from your Qlik Sense in Windows installation into folder(s) on your server locally.

- Put provided .ps1 scripts files into a folder on CM Qlik Sense server locally
- Open *PowerShell ISE* with Admin privileges
- Open/Run *1_CM_ExportAll.ps1* script to export all content from  
CM env into local temp folders. *PS Script will install Qlik-Cli if not already installed.*


The following is executed by this script:
- Creates Data folder and creates” \DATA\CM_UsersDatabase.csv” file
- Loops through all Streams / Apps / Objects
- The code Publishes / Approves all *private* Objects
- Export Apps with full list of objects
- Reverts private objects (step .3) *back to private status*
- Exports Apps from personal ”My Work stream”




## Step 2, User mapping - prepare

*Setup JWT* auth in OEM licensed QS Saas tenant (1st one)
- https://qlik.dev/tutorials/create-signed-tokens-for-jwt-authorization

Convert .pem and .cer certificates into *.PFX* file using
```
openssl pkcs12 -inkey privatekey.pem -in publickey.cer -export -out bob_pfx.pfx
```
- Store *.PFX* file into a *"\certificates\"* subfolder to the project

Admin needs to manually *invite users* of choice to tenant
- https://help.qlik.com/en-US/cloud-services/Subsystems/Hub/Content/Sense_Hub/Admin/SaaS-invite-users.htm#anchor-2

Please prepare *2_SaaS__ExportUsers.ps1* file with Admin/tenant details before continuing.

### Tenant Admin details

![image](https://user-images.githubusercontent.com/28060254/198076521-8d6c7e3d-f30f-40b5-b28c-a8f7c78b1a54.png)


Now execute *2_SaaS__ExportUsers.ps1*

### This script will do the following:
Create *SaaS_UsersDatabase.csv* file, with complete list of current Saas users

### Admin now needs to merge user file content between
*CM_UsersDatabase.csv* and  *SaaS_UsersDatabase.csv*
- The result should look like example file ”Mapping.csv”





## Step 3, import CM content into Saas tenant

- Open / edit *3_aaS__ImportAll.ps1*

- Input the same details/credentials as in *Step 2/Tenant details* on the previous page

This script will do the following:
- Logon current session as tenant Admin context using *JWT*
- Create Saas *Shared Spaces* equal to *CM Streams*
- Import all Apps exported in *Step 1*, into Shared Spaces
- Run a *User Context impersonation Loop*, that will Unpublish / return ownership of Objects that belong to this User

```
Authors: Simon Matele & Simon Astakhov
OEM EMEA Presales Team at Qlik 
https://www.qlik.com
```
