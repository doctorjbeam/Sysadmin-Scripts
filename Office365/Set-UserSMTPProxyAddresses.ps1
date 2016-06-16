Import-Module ActiveDirectory

$Groups = Get-ADGroup -Filter *

foreach ($Group in $Groups) {
	
	$email = (Get-ADGroup $Group -properties mail).mail
	
	if ($email -eq $null) {
		continue; 
	}
	
	Set-ADGroup $Group -Add @{proxyAddresses = ("SMTP:"+$email)}
	
	write-host $email; 
	
	#break;
	
}

<#
$users = Get-ADUser -Filter *

foreach ($user in $users) {
	Write-Host "Processing "$user.samAccountName; 
	
	if ($user.samAccountName -match '^[0-9]{8}$') {
		$email = (Get-ADUser $user -properties mail).mail
		
		if ($email -eq $null) {
			continue; 
		}
		
		$bademail = $user.samAccountName + '@whsc.vic.edu.au'
		Set-ADUser $user -Remove @{proxyAddresses = ($bademail)}
		
	} else {
		$email = $user.samAccountName + '@whsc.vic.edu.au'
	}
		
	$newemail = "SMTP:"+$email
	Set-ADUser $user -Add @{proxyAddresses = ($newemail)}
}
#>