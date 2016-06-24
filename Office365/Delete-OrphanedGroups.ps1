# Delete orphaned groups from Exchange Online
# @author Michael Greenhill
# @updated 23/06/2016

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Cred -Authentication Basic -AllowRedirection;
Import-PSSession $Session -AllowClobber;

$groups = Get-DistributionGroup ; 

Write-Host "Processing groups..."

Foreach ($group in $groups) {

	$groupName = $group.Name; 
	$groupEmail = $group.WindowsEmailAddress; 
	
	$search = Get-ADGroup -Filter {SamAccountName -eq $groupName }
	
	if ($search -ne $null) {
		continue; 
	}
	
	Write-Host "Deleting O365 distribution group $groupName with email address $groupEmail";
	
	Remove-DistributionGroup -Identity $groupEmail -Confirm:$false; 
	
	
}

Remove-PSSession $Session; 
