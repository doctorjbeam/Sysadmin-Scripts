# Update Whole Staff unified group membership
# @author Michael Greenhill
# @updated 12/09/2017

Start-Transcript "C:\Scripts\Office 365\Update-WholeStaffMembers.txt";

$ADGroup = "All Staff"; 
$O365UnifiedGroup = "Whole Staff"

$GroupMembers = [System.Collections.ArrayList](Get-ADGroupMember -Identity $ADGroup -Recursive | Get-ADUser -Properties Mail | Where {$_.Mail -like "*@whsc.vic.edu.au"} | Where {$_.Enabled -eq $true} | Select-Object Mail).Mail;

$secpasswd = Get-Content "C:\path\to\secure\credential.txt" | ConvertTo-SecureString; 

$Cred = New-Object System.Management.Automation.PSCredential ("admin@blah.com", $secpasswd);

Connect-MsolService -Credential $Cred;

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber;

$UnifiedGroup = Get-UnifiedGroup -Identity $O365UnifiedGroup -ErrorAction SilentlyContinue; 

Write-Output "`nPopulating group members";
Add-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Members -Links $GroupMembers; 

Write-Output "`nPopulating group subscribers";
Add-UnifiedGroupLinks -Identity $UnifiedGroup.Identity -LinkType Subscribers -Links $GroupMembers; 

Remove-PSSession $Session; 

Stop-Transcript; 