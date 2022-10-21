Add-Type -AssemblyName System.Web
Set-ExecutionPolicy Bypass -Scope Process -Force
'.\modules\*.psm1' | Get-ChildItem -Recurse | Import-Module -Force
cls
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

$UserLS = Import-Csv -Path "$(Get-Location)\DATA\Mappping.csv"
$Streams = Get-ChildItem -Path "$(Get-Location)\DATA\" -Directory
<#
$SaaS_Streams = (qlik space ls --server $tenantURL --headers $adminHeaders | ConvertFrom-Json) 2> $null
Foreach ($Stream in $Streams) {
    $StreamDecoded = [System.Web.HttpUtility]::UrlDecode($Stream.Name)
    if ($StreamDecoded -ne "PrivateUserApplications"){
        $StreamNameDecoded = $StreamDecoded.SubString(0 ,$StreamDecoded.Length-39)
        $StreamNameDecoded

        if (-not $SaaS_Streams.name -contains $StreamNameDecoded) {
            $CurrentStream = (qlik space create --name $StreamNameDecoded --type "shared" --server $tenantURL --headers $adminHeaders | ConvertFrom-Json)
        } else { #have same stream name
            $CurrentStream = $SaaS_Streams | Where-Object -FilterScript {$_.name -EQ $StreamNameDecoded}
        }
        
        $Apps = Get-ChildItem -Path "$(Get-Location)\DATA\$($Stream)" -Filter *.qvf
        Foreach ($App in $Apps) {
            $AppDecoded = [System.Web.HttpUtility]::UrlDecode($App.Name)
            $AppNameDecoded = $AppDecoded.SubString(0 ,$AppDecoded.Length-43)
            $AppNameDecoded
            
            $CurrentApp = (qlik app import --file $App.FullName --name $AppNameDecoded --spaceId $CurrentStream.id --server $tenantURL --headers $adminHeaders | ConvertFrom-Json)
            #$CurrentPublish = (qlik app publish create $CurrentApp.attributes.id --spaceId $CurrentStream.id --server $tenantURL --headers $adminHeaders)

        }
    }
}
#>
"USERLOOP"

foreach ($User in $UserLS) {
    $impersonateUserSubject=$User.saas_subject
    $impersonateUserName=$User.saas_name
    $impersonateUserEmail=$User.saas_email
    $impersonateUserGroups="Domain Users"

    $impersonationJWT = GenerateJWT -pfxPass $pfxPass `
        -pathToPFX $pathToPFX -iss $iss `
        -kid $kid -sub $impersonateUserSubject `
        -email $impersonateUserEmail -aud 'qlik.api/login/jwt-session' `
        -groups $impersonateUserGroups -name $impersonateUserName
    
    $impersonationHeaders = GenerateHeaders -jwt $impersonationJWT -tenantURL $tenantURL


    $SpaceList = (qlik space ls --server $tenantURL --headers $impersonationHeaders | ConvertFrom-Json) 2> $null
    "User [$($impersonateUserName)] have [$($SpaceList.Length)] Streams"
    foreach ($Space in $SpaceList) {

        $AppList = (qlik item ls --resourceType app --noActions --spaceId $Space.id --server $tenantURL --headers $impersonationHeaders | ConvertFrom-Json) 2> $null
        "> Stream [$($Space.name)] have [$($AppList.Length)] Apps [$($Space.id)]"
        foreach ($App in $AppList) {
            $BookList = (qlik app bookmark ls --app $App.id --json --server $tenantURL --headers $impersonationHeaders | ConvertFrom-Json) 2> $null
            ">> App [$($App.name)] have [$($BookList.Length)] Bookmarks [$($App.id)]"
            foreach ($Bookmark in $BookList)  {
                ">>> [$($Bookmark.title)] [$($Bookmark.qId)]"
                # add filter to JSON file unpublish stuff

                qlik app object unpublish $Bookmark.qId --json --app $App.id --server $tenantURL --headers $impersonationHeaders 2> $null
            }
            #$AppObjLS = (qlik app unbuild --app $App.id --dir "$(Get-Location)\DATA\Unb\" --server $tenantURL --headers $impersonationHeaders | ConvertFrom-Json) 2> $null
            
            $AppObjLS = (qlik app object ls --app $App.id --json --server $tenantURL --headers $impersonationHeaders | ConvertFrom-Json) 2> $null
            ">> App [$($App.name)] have [$($AppObjLS.Count)] Objects"
            foreach ($AppObj in $AppObjLS)  {
                if ($AppObj.qType -eq "sheet" -or $AppObj.qType -eq "story") {
                    ">>> [$($AppObj.qType)] [$($AppObj.title)] [$($AppObj.qId)]"
                    #$AppObj
                    qlik app object unpublish $AppObj.qId --json --app $App.id --server $tenantURL --headers $impersonationHeaders 2> $null
                }
            }
        }  #AppList
    } #SpaceList
}

"ADMIN REVERT"