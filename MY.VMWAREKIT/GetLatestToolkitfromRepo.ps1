# Standalone PS Script to download your custom Toolkit without having to download the entire repo. This script will only copy the Modules file and the Manifest file. Any additional files will have to be augmented to this script. This script is meant to pull down the TOOLKIT for individuals who are not git-savvy. This script will delete any existing Toolkit files and copy down the latest files from the repo.
# Run-time variables and parameters:
$ErrorActionPreference = "Stop"
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false

# If the TOOLKIT file exists, delete it. If not, do nothing.
Write-Host -Foregroundcolor Green "Cleaning up Local Directory . . ."
$GetVMWAREKITFile = Get-ChildItem | Where {$_.Name -match "MY.VMWAREKIT" } -ErrorAction SilentlyContinue
If ($GetVMWAREKITFile -ne $Null) {
    Remove-Item $GetVMWAREKITFile
}

Sleep 1

# Get Credentials for proper basic authentication.
# If git access is public or read only, comment these lines out:  
$Creds = Get-Credential
$Username = $Creds.GetNetworkCredential().username
$Password = $Creds.GetNetworkCredential().password
$Pair = "${Username}:${Password}"
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Pair)
$Base64 = [System.Convert]::ToBase64String($Bytes)
$Basic = "Basic $Base64"
$Headers = @{ Authorization = $Basic }

# Download your Custom Toolkit and convert it to a usable file:
Write-Host -Foregroundcolor Green "Downloading VMware Toolkit Manifest file . . ."
Invoke-WebRequest -Uri 'https://path/to/raw/git/MY.VMWAREKIT.psd1' -Headers $Headers -OutFile MY.VMWAREKIT.psd1
Sleep 1

Write-Host -Foregroundcolor Green "Downloading VMware Toolkit Modules file . . ." 
Invoke-WebRequest -Uri 'https://path/to/raw/git/MY.VMWAREKIT.psm1' -Headers $Headers -OutFile MY.VMWAREKIT.psm1
Sleep 1

# Import the Module needed to run the scripts. The Global and Force options will reload the module if it has been laoded previously:
Write-Host -Foregroundcolor Green "Importing PowerCLI VMware Toolkit . . ." 
Sleep 1
Import-Module ./MY.VMWAREKIT.psd1 -Global -Force

#Show the end-user the commands available for use:
Write-Host -Foregroundcolor Green "Here are the commands available:"
Get-Command -Module MY.VMWAREKIT | Select-Object Name,Source | FT