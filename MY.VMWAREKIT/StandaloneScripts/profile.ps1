## Will need to set the directories below and copy this file into the proper Profiles directory for your powershell installation:
Set-Location /path/to/running/toolkit/directory
Import-Module /path/to/running/toolkist/directory/MY.VMWAREKIT.psd1 -Global -Force
 
$vCenterConnect = Read-Host -Prompt "Would you like to connect to a vCenter? (Type 'y'[Enter] for vCenter Menu or 'any other key'[Enter] to exit.)"
 
If ($vCenterConnect -eq "y") {
    Connect-VIServer -Menu
} Else {
    Exit
}
