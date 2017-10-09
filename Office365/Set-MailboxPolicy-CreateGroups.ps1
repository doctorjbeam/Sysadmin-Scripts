Write-Output "Connecting to MsolService"; 
$secpasswd = ConvertTo-SecureString "atotallysecurepasswordLOLZDONTUSETHISINPRODUCTION" -AsPlainText -Force;

$Cred = New-Object System.Management.Automation.PSCredential ("admin@blah.com", $secpasswd);

# Members of this AD security group - federated to O365 of course - will be granted permission to create Unified Groups and Teams. 
$allowedADSecurityGroup = "O365-MailboxPolicy-AllowCreateGroups";

Connect-AzureAD -Credential $Cred;
#Import-Module AzureADPreview; 

$Template = Get-AzureADDirectorySettingTemplate | where {$_.DisplayName -eq 'Group.Unified'};

$Setting = $Template.CreateDirectorySetting();
New-AzureADDirectorySetting -DirectorySetting $Setting;
$Setting = Get-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id;

$Setting["EnableGroupCreation"] = $False;
$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $allowedADSecurityGroup).objectid;

Set-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | where -Property DisplayName -Value "Group.Unified" -EQ).id -DirectorySetting $Setting;Uninstall-Module AzureADPreview