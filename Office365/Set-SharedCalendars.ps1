<#

	Create/update shared calendars
	
	Create a calendar within your organisation and delegate ownership based on AD security group managers
	AD security group members are given read-only privileges
	
	@updated 24/08/2016
	@author Michael Greenhill
	
#>

<#
Write-Output "Connecting to MsolService"; 
$secpasswd = Get-Content "C:\Scripts\Office 365\Credential.txt" | ConvertTo-SecureString; 
$Cred = New-Object System.Management.Automation.PSCredential ("admin@wheelershillsc.onmicrosoft.com", $secpasswd);

Connect-MsolService -Credential $Cred;

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber;
#>

# Fetch groups from OU. Uses SearchScope OneLevel to prevent recursion into sub-OUs, where management groups may reside
$Groups = Get-ADGroup -Filter * -SearchScope OneLevel -SearchBase "OU=Calendars,OU=Office 365,OU=Groups,DC=curric,DC=wheelers-hill-sc,DC=wan" -Properties Mail,Description,Name,ManagedBy; 

foreach ($Group in $Groups) {
	Write-Host "`n-------------------------------------`n"
	Write-Host "Processing $($Group.Name)";

	$groupAlias = $Group.Name.Replace(' ','-').Replace('---','-'); 
	$groupEmail = "$groupAlias@wheelershillsc.onmicrosoft.com"
	$members = Get-ADGroupMember -Identity $Group.Name | Get-ADGroup -Properties Mail | Select-Object Mail, Name;
	
	$Mailbox = Get-Mailbox -Identity $groupEmail -ErrorAction SilentlyContinue; 
	
	# Get the AD group owner(s)
	
	$owners = @()
	$managers = Get-ADGroupMember $Group.ManagedBy; 
	
	foreach ($object in $managers) {
		if ($object.objectClass -eq "group") {
			$group = Get-ADGroup -Identity $object -Properties Mail | Select-Object Mail, Name;
			
			# If the group has an email address add it to our owners
			if ($group.Mail -ne $null) {
				$owners += $group; 
				continue; 
			}
			
			# Group doesn't have an email address - get the addresses of the members instead
			$owners += Get-ADGroupMember -Identity $object.Name -Recursive | Get-ADUser -Properties Mail, Name | Select-Object Mail, Name | Where-Object {$_.Mail -like "*whsc.vic.edu.au" }
		}
	}
	
	# Create new group
	if ($Mailbox -eq $null) {
		$Mailbox = New-Mailbox -Name $Group.Name -Alias $groupAlias -Shared
	}
	
	Write-Host "`nGetting current permissions"
	
	$currentPermissions = Get-MailboxFolderPermission -Identity "$($groupEmail):\Calendar";
	$currentOwners = $currentPermissions | Where-Object { $_.AccessRights -eq "Owner" }
	$currentReviewers = $currentPermissions | Where-Object { $_.AccessRights -eq "Reviewer" }
	
	Write-Host "Setting owners";
	
	foreach ($member in $owners) {
	
		Write-Host " - Processing $($member.Name) ($($member.Mail))";
		
		if ($currentOwners.User -like $member.Name -ne $false) {
			Write-Host " - $($member.mail) is already an owner";
			continue;
		}
		
		Write-Host " - Adding $($member.Mail)"
		Add-MailboxFolderPermission "$($groupEmail):\Calendar" -User $member.Mail -AccessRights Owner -ErrorAction SilentlyContinue | Out-Null
	}
	
	Write-Host "`nSetting reviewers"
	foreach ($member in $members) {
		
		if ($currentReviewers.User -like $member.Name -ne $false) {
			Write-Host " - $($member.mail) is already a reviewer";
			continue;
		}
		
		Write-Host " - Adding $($member.Mail)"
		Add-MailboxFolderPermission "$($groupEmail):\Calendar" -User $member -AccessRights Reviewer -ErrorAction SilentlyContinue | Out-Null
	}
	
	#Write-Host "Finished processing $($Group.Name)"

}