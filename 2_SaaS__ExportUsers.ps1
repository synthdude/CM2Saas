
Set-ExecutionPolicy Bypass -Scope Process -Force
'.\modules\*.psm1' | Get-ChildItem -Recurse | Import-Module -Force

$tenantURL="https://<TENANT ID>.<REGION>.qlikcloud.com"

$pathToPFX="$(Get-Location)\certificates\text2.pfx"
$pfxPass="<PFX password>"
$iss="<TENANT ID>.<REGION>.qlikcloud.com"
$kid="<Key ID from JWT pfx cert>"

$adminSubject="<IDP Subject for Admin User from Users list in QMC>"
$adminName="<Admin Name>"
$adminEmail="<Admin email>"
$adminGroups="Domain Users" #If you don’t use Groups, please leave "Domain Users" as default

"LOGIN AS TENENT ADMIN"
"Making [$adminName] JWT"
$adminJWT = GenerateJWT -pfxPass $pfxPass `
    -pathToPFX $pathToPFX -iss $iss `
    -kid $kid -sub $adminSubject `
    -email $adminEmail -aud 'qlik.api/login/jwt-session' `
    -groups $adminGroups -name $adminName

"Authenticating [$adminName]"
$adminHeaders = GenerateHeaders -jwt $adminJWT -tenantURL $tenantURL
"[$adminName] Authenticated"

$UserLS = (qlik user ls --server $tenantURL --headers $adminHeaders | ConvertFrom-Json)
"[$($iss)] tenant have [$($UserLS.Length)] Users"
$UserLS = $UserLS | Select-Object -Property @{Name="saas_subject";Expression={$_.subject}},@{Name="saas_name";Expression={$_.name}},@{Name="saas_email";Expression={$_.email}}
$UserLS | ConvertTo-Csv -NoType | Set-Content -Path "$(Get-Location)\DATA\SaaS_UsersDatabase.csv"

$confirmation = Read-Host "Now, please make UserMapping [$(Get-Location)\DATA\], open folder? (y)"
if ($confirmation -eq 'y' -or $confirmation -eq '') {
    Invoke-Item "$(Get-Location)\DATA\"
}