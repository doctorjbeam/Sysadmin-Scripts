# Create/Replace/Update/Delete unified groups
# @author Michael Greenhill
# @updated 24/08/2016

#Write-Output "Enforcing proxy settings"; 
#& netsh winhttp set proxy 10.142.204.19:8080 "<local>;wsus*;whsc-server04*;*.wan"

Write-Output "Connecting to MsolService"; 
$secpasswd = Get-Content "C:\Scripts\Office 365\Credential.txt" | ConvertTo-SecureString; 
$Cred = New-Object System.Management.Automation.PSCredential ("admin@wheelershillsc.onmicrosoft.com", $secpasswd);

Connect-MsolService -Credential $Cred;

#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Cred -Authentication Basic -AllowRedirection;
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber;

$Groups = Get-ADGroup -Filter * -SearchBase "OU=Unified Groups,OU=Office 365,OU=Groups,DC=curric,DC=wheelers-hill-sc,DC=wan" -Properties Mail,Description,Name,ManagedBy; 

# Loop through all found groups 

foreach ($Group in $Groups) {
	Write-Host "`n-------------------------------------`n"
	Write-Host "Processing $($Group.Name)";
	
	$groupAlias = "group-$($Group.Name.ToLower().Replace(' ','-'))"; 
	$groupEmail = "$groupAlias@whsc.vic.edu.au"
	
	# Find unified group
	$UnifiedGroup = Get-UnifiedGroup -Identity $groupEmail -ErrorAction SilentlyContinue; 
	
	# Get group members as a string
	$GroupMembers = [System.Collections.ArrayList](Get-ADGroupMember -Identity $Group.Name -Recursive | Get-ADUser -Properties Mail | Select-Object Mail).Mail;
	
	# Get the AD group owner(s)
	try {
		$owners = Get-ADGroupMember $Group.ManagedBy -Recursive | Get-ADUser -Properties Mail | Where {$_.Mail -like "*@whsc.vic.edu.au"} | Select-Object Mail;
	} catch {
		$owners = Get-ADUser $Group.ManagedBy -Properties Mail | Select-Object Mail; 
	}
	
	$owners = [System.Collections.ArrayList]($owners).Mail; 
	
	# Ensure that group owners are also group members
	foreach ($member in $owners) {
		if (!$GroupMembers.Contains($member)) {
			$GroupMembers.Add($member) | Out-Null;
			Write-Warning "$($member) is not a member of the AD group $($Group.Name). Automatically added to group membership"; 
		}
	}
	
	# Create new group
	if ($UnifiedGroup -eq $null) {
		$UnifiedGroup = New-UnifiedGroup -DisplayName $Group.Name -Alias $groupAlias -EmailAddresses $groupEmail -Members $GroupMembers; 
	} else {
		Add-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Members -Links $GroupMembers; 
	}
	
	# Set the owners
	Add-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Owners -Links $owners; 
	
	# Get the UnifiedGroup members
	$unifiedGroupMembers = Get-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Members; 
	$unifiedGroupOwners  = Get-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Owners; 
	
	# Remove admins no longer in the $owners list
	foreach ($owner in $unifiedGroupOwners) {
		if (!$owners.Contains($owner.PrimarySmtpAddress)) {
			Write-Host "$($owner.Name) is no longer in the AD group managers - removing from unified group owners list"; 
			Remove-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Owners -Links $owner.PrimarySmtpAddress -Confirm:$false; 
		}
	}
	
	# Remove members no longer in the $GroupMembers list
	foreach ($member in $unifiedGroupMembers) {
		if (!$GroupMembers.Contains($member.PrimarySmtpAddress)) {
			Write-Host "$($member.Name) is no longer in the AD group members - removing from unified group owners list"; 
			Remove-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Members -Links $member.PrimarySmtpAddress -Confirm:$false; 
		}
	}
	
	Write-Host "Finished processing $($Group.Name)"
	
}

#Remove-PSSession $Session; 