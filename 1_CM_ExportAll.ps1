$ErrorActionPreference = 'Stop'
"installing qlik cli for qscm (additional requests may apppear)"
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module Qlik-Cli -Scope CurrentUser
Import-Module Qlik-Cli
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

"connecting to server"

#connect to QSCM
try{
    Connect-Qlik -Certificate (Get-ChildItem cert:CurrentUser\My | Where-Object { $_.FriendlyName -eq 'QlikClient' }) | Out-Null
} catch {
    "cannot connect to server"
    Exit
}

#making initial folder structure
MKDIR -Path "$(Get-Location)" -Name "DATA" -Force | Out-Null
MKDIR -Path "$(Get-Location)\DATA" -Name "PrivateUserApplications" -Force | Out-Null

"exporting users"
#expoprting users to JSON
$Users = Get-QlikUser
$Users = $Users | Select-Object -Property @{Name="cm_name";Expression={$_.name}},@{Name="cm_userDirectory";Expression={$_.userDirectory}},@{Name="cm_userId";Expression={$_.userId}},@{Name="cm_id";Expression={$_.id}} 
$Users | ConvertTo-Csv -NoType | Set-Content -Path "$(Get-Location)\DATA\CM_UsersDatabase.csv"

"getting streams"
$Streams = Get-QlikStream
"will proceed $($Streams.count) streams in total"

#loop thru streams
foreach ($Stream in $Streams) {
    "working in [$($Stream.name)] stream"

    #making folders for streams
    $StreamFolderName = "$($Stream.name) ($($Stream.id))"
    $StreamFolderNameEncoded = [System.Web.HttpUtility]::UrlEncode($StreamFolderName)
    MKDIR -Path "$(Get-Location)\DATA" -Name $StreamFolderNameEncoded -Force | Out-Null
    
    #get apps from stream
    $StreamApps = Get-QlikApp -filter "stream.name eq '$($Stream.name)'"
    "$($StreamApps.count) apps inside"
    #Loop thru stream apps
    foreach ($App in $StreamApps) {
        "[$($Stream.name)] > [$($App.name)]"
        
        #original state container
        $ObjectsBackup = @()
        
        #get obj from app
        $Objects = Get-QlikObject -filter "app.id eq $($App.id)"

        #loop thru app objects
        foreach ($Object in $Objects) {

            #filter "sheet","story","bookmark" objects
            if($Object.objectType -in ("sheet","story","bookmark")){

                #get extended obj props (we need .approved)
                $Object = Get-QlikObject -id $Object.id

                #filter objects that require an action
                if($Object.approved -eq $false){

                    #store original state of objects that need to be changed
                    $ObjectsBackup += $Object
                    $ObjectsBackup | ConvertTo-Json -depth 100 | Set-Content -Path "$(Get-Location)\DATA\$($StreamFolderNameEncoded)\$($App.id).json"

                }
            }
        }  #obj loop

        #publish all unpublished
        foreach ($Object in ($ObjectsBackup | Where-Object {$_.published -eq $false})) {
            Publish-QlikObject -id $Object.id | Out-Null
        }
        #approve all unpublished
        foreach ($Object in ($ObjectsBackup | Where-Object {$_.approved -eq $false})) {
            Update-QlikObject -id $Object.id -approved $true | Out-Null
        }

        #app.name can contain filename unsupported chars, need to encode it
        $FileName = "$($App.name) ($($App.id))"
        $FileNameEncoded = [System.Web.HttpUtility]::UrlEncode($FileName)

        Export-QlikApp -id $App.id -filename "$(Get-Location)\DATA\$($StreamFolderNameEncoded)\$($FileNameEncoded).qvf"
        
        #UNapprove back
        foreach ($Object in ($ObjectsBackup | Where-Object {$_.approved -eq $false})) {
            Update-QlikObject -id $Object.id -approved $false | Out-Null
        }
        #UNpublish back
        foreach ($Object in ($ObjectsBackup | Where-Object {$_.published -eq $false})) {
            Unpublish-QlikObject -id $Object.id | Out-Null
        }

    } #app loop
} #stream loopp

#Export "Work" stream Apps
$WorkApps = Get-QlikApp -filter "published eq False"
"exporting $($WorkApps.count) apps from personal work"
foreach ($App in $WorkApps) {
    #getting app meta to get owner
    $App = Get-QlikApp -id $App.id

    #making folder for personal apps owner
    $User = $App.owner
    $UserFolderName = "$($User.name) ($($User.userDirectory)\$($User.userId)) $($User.id)"
    $UserFolderNameEncoded = [System.Web.HttpUtility]::UrlEncode($UserFolderName)
    MKDIR -Path "$(Get-Location)\DATA\PrivateUserApplications" -Name $UserFolderNameEncoded -Force | Out-Null

    #app.name can contain filename unsupported chars, need to encode it
    $FileName = "$($App.name) ($($App.id))"
    $FileNameEncoded = [System.Web.HttpUtility]::UrlEncode($FileName)

    "[$($App.name)] for [$($User.userDirectory)\$($User.userId)]"
    Export-QlikApp -id $App.id -filename "$(Get-Location)\DATA\PrivateUserApplications\$($UserFolderNameEncoded)\$($FileNameEncoded).qvf"
}

$confirmation = Read-Host "All data stored at [$(Get-Location)\DATA\], open folder? (y)"
if ($confirmation -eq 'y' -or $confirmation -eq '') {
    Invoke-Item "$(Get-Location)\DATA\"
}