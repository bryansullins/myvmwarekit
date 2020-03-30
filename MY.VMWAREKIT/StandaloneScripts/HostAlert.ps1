function New-CredentialObject{
    param(
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false)]
        [string]$Username,

        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false)]
        [string]$Password
    )
    $credential = New-Object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))
    return $credential
}

function send-alert ($vm){
    $mailTo = "EMAILHERE" #[string[]]$env:SnapshotContact
    $vmHost = $vm
    $mailFrom = "MAILFROMHERE"
    $mailSMTP = "SMTPHERE"
    $mailSubject = "SUBJECTHERE"
    $mailBody = "$vmHost is offline"
	Send-MailMessage -To $mailTo -From $mailFrom -SmtpServer $mailSMTP -Body "$mailBody" -Subject $mailSubject -BodyAsHtml
    Write-Host $mailBody
    Write-Host $mailTo
    }

function clean_tags($vmhost){
    foreach ($v in $vmhost){
        if ($v.ConnectionState -eq "Connected") # -or $vmhost.ConnectionState -eq "Maintenance"){
            Write-Host -ForegroundColor Green "Host is back online"
            Set-Annotation -Entity $v -CustomAttribute "Alert" -Value 0
            Get-VMHost $v | Get-TagAssignment | Where-Object {$_.Tag -like "*Host_Connection_Alert"} | Remove-TagAssignment -Confirm:$false
            }
        }
}

function can_alert($vmhost){
    $state = Get-VMHost $vmhost | Get-TagAssignment
    if ($state.Tag.Name -like "Host_Connection_Alert"){
        Write-Host -ForegroundColor Red "Already alerted"
    }
    else{
        Write-Host -ForegroundColor Red "***Alert*** host has been offline for more than 5 minutes"
        Get-VMHost $vmhost | New-TagAssignment -Tag "Host_Connection_Alert"
        send-alert $vmhost
    }
}

function host_disconnected($vmhost){
    $failures = Get-VMHost $vmhost | Get-Annotation -CustomAttribute Alert
    if ($failures.Value -lt 5){
        $failuresInt = [int]$failures.Value
        $failuresInt ++
        Write-Host $failuresInt
        Get-VMHost $vmhost | Set-Annotation -CustomAttribute Alert -Value $failuresInt
        }
    else {
        can_alert $vmhost
        }
}

$cred = New-CredentialObject -Username $env:vcuser -Password $env:vcpw
Connect-VIServer "vCENTERHERE" -Credential $cred
$vmhosts = Get-VMHost #| Where-Object {$_.ConnectionState -ne "Connected" -or $_.ConnectionState -ne "Maintenance"}
$tagged_hosts = get-vmhost -Tag Host_Connection_Alert

foreach ($v in $vmhosts){
    if ($v.ConnectionState -eq "Disconnected" -or $v.ConnectionState -eq "Maintenance"){
        host_disconnected $v
        }
    }

$clearHosts = @()
foreach ($v in $vmhosts){
    if ($v.customFields['Alert'] -ne "0"){
        $clearHosts += $v
    }
    
}
Write-Host $clearHosts
clean_tags $clearHosts

 
