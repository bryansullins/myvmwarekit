Param(
        [Parameter()][string]$vCenter,
        [Parameter()][string]$VCUser,
        [Parameter()][String]$VCPassword
)
## vMotion Test Script
# Connect to vCenter in Question and get desired VMs:
Import-Module ./MY.VMWAREKIT/MY.VMWAREKIT.psd1 -Global
Connect-VIServer -Server $vCenter -User $VCUser -Password $VCPassword -InformationAction Ignore
# Alter this line to get the VM(s) you want to test. Use Where-Object or Regex and go crazy! This is just a sample using 1 VM for testing:
$vMotionTestVMs = Get-VM -Name "VMNAMEHERE"

#Run Parameters for the MY.VMWAREKIT Function
$NumTimestoMove = 1
$TimetoMoveMax = 30
$MinimumSeconds = 600
$MaximumSeconds = 1800

While($NumTimestoMove -le $TimetoMoveMax) {
    Write-Host "This is $NumTimesToMove of $TimetoMoveMax vMotions."
    # Don't wait if it's the first time through the loop . . .
    If ($NumTimestoMove -eq 1){
        $Wait = 0
    } 
    Else {
        $Wait = Get-Random -Minimum $MinimumSeconds -Maximum $MaximumSeconds
        Write-Host "Waiting $Wait Seconds . . ."
    }

    Start-Sleep -Seconds $Wait 
    
    ForEach ($v in $vMotionTestVMs) {
        Move-REIVMOffCurrHost -VMName $v
    }

    $NumTimestoMove += 1
}