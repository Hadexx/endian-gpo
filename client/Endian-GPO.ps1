# endian-gpo - Linking Endians transparent proxy with Active Directory Group Policies
# Copyright (c) 2018 Dorian Stoll
# Licensed under the Terms of the MIT License

function Get-RegValue([String] $KeyPath, [String] $ValueName) {
    (Get-ItemProperty -LiteralPath $KeyPath -Name $ValueName).$ValueName
}
function Get-RegValues([String] $KeyPath) {
    $RegKey = (Get-ItemProperty $KeyPath)
    $RegKey.PSObject.Properties | 
        Where-Object { $_.Name -ne "PSPath" -and $_.Name -ne "PSParentPath" -and $_.Name -ne "PSChildName" -and $_.Name -ne "PSDrive" -and $_.Name -ne "PSProvider" } | 
        ForEach-Object {
        $_.Name
    }
}

# Get the router IP and whether the client should be whitelisted
$routerIP = ""
$bypass = 0
$secret = ""
Get-RegValues 'HKLM:\SOFTWARE\Policies\Endian' | ForEach-Object {
    if ($_ -eq 'routerIP') {
        $routerIP = Get-RegValue 'HKLM:\SOFTWARE\Policies\Endian' $_
    }
    if ($_ -eq 'bypass') {
        $bypass = Get-RegValue 'HKLM:\SOFTWARE\Policies\Endian' $_
    }
    if ($_ -eq 'secret') {
        $secret = Get-RegValue 'HKLM:\SOFTWARE\Policies\Endian' $_
    }
}

# Apply the changes to the router
getmac /FO CSV /NH | ForEach-Object { $_.Replace('"', "").Split(",")[0] } | ForEach-Object {
    if ($_ -Match "-") {
        if ($bypass -eq 1) {
            Invoke-WebRequest -Uri "http://$($routerIP):7777/register" -UseBasicParsing -Method POST -Body @{mac = $_.Replace("-", ":"); secret=$secret}
        }
        if ($bypass -eq 0) {
            Invoke-WebRequest -Uri "http://$($routerIP):7777/unregister" -UseBasicParsing -Method POST -Body @{mac = $_.Replace("-", ":"); secret=$secret}
        }
    }
}
