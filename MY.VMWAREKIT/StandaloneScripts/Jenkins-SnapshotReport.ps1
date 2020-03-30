 
#This function generates a nice HTML output that uses CSS for style formatting.
function Generate-Report {
	Write-Output "<html><head><title></title><style type=""text/css"">.Error {color:#FF0000;font-weight: bold;}.Title {background: #0077D4;color: #FFFFFF;text-align:center;font-weight: bold;}.Normal {}</style></head><body><table><tr class=""Title""><td colspan=""7"">VMware Snaphot Report</td></tr><tr class="Title"><td>vCenter </td><td>VM Name  </td><td>Snapshot Name  </td><td>Date Created  </td><td>Description  </td><td>Size in GB  </td><td>Power State</td></tr>"
		Foreach ($snapshot in $report){
			Write-Output "<td>$($snapshot.vcenter)</td><td>$($snapshot.vm)</td><td>$($snapshot.name)</td><td>$($snapshot.created)</td><td>$($snapshot.description)</td><td>$($snapshot.SizeGB)</td><td>$($snapshot.PowerState)</td></tr> " 
			}
	Write-Output "</table></body></html>" 
	}

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
#List of servers including Virtual Center Server.  The account this script will run as will need at least Read-Only access to Cirtual Center
$ServerList = "COMMA","SEPARATED","LIST","OF","SERVERS","HERE"
$cred = New-CredentialObject -Username $env:svcusername -Password $env:svcpassword

#Initialise Array
$Report = @()

foreach ($server in $ServerList){
	Connect-VIServer -server $server -Credential $cred
	$snapshots = get-vm | Get-Snapshot
	foreach ($snap in $snapshots){
		$size = '{0:N2}' -f $snap.SizeGB
		$snap = New-=New-Object -TypeName [PSCustomObject]
		$snap | Add-Member -MemberType NoteProperty -Name vCenter -Value $server
		$snap | Add-Member -MemberType NoteProperty -Name vm -Value $snap.vm
		$snap | Add-Member -MemberType NoteProperty -Name name -Value $snap.name
		$snap | Add-Member -MemberType NoteProperty -Name created -Value $snap.created
		$snap | Add-Member -MemberType NoteProperty -Name description -Value $snap.description
		$snap | Add-Member -MemberType NoteProperty -Name SizeGB -Value $size
		$snap | Add-Member -MemberType NoteProperty -Name PowerState -Value $snap.PowerState
		$Report += $Snap
		}    
disconnect-viserver -confirm:$false
} 
Generate-Report > "VmwareSnapshots.html"
$mailTo = "MAILTOEMAILHERE"
$mailFrom = "MAILFROMHERE"
$mailSMTP = "SMTPSERVERHERE"
$mailBody = Generate-Report
$mailSubject = "VMWare Snapshots $Server"
    
Send-MailMessage -To $mailTo -From $mailFrom -SmtpServer $mailSMTP -Body "$mailBody" -Subject $mailSubject -BodyAsHtml