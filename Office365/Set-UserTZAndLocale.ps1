# Set Office 365 licenses and ServicePlan availability based on AD group membership
# @updated 8/06/2016
# @author Michael Greenhill

Start-Transcript "C:\Scripts\Office 365\Set-TZAndLocale.log";


Write-Output "Enforcing proxy settings"; 
& netsh winhttp set proxy 10.142.204.19:8080 "<local>;wsus*;whsc-server04*;*.wan"

Write-Output "Connecting to MsolService"; 
$secpasswd = Get-Content "C:\Scripts\Office 365\Credential.txt" | ConvertTo-SecureString; 
$Cred = New-Object System.Management.Automation.PSCredential ("admin@wheelershillsc.onmicrosoft.com", $secpasswd);

Connect-MsolService -Credential $Cred;

# Set the timezone and language for all users
Write-Output "Setting the timezone and langauge for all users";

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber

Get-Mailbox -Filter {RecipientTypeDetails -eq 'UserMailbox'} | Set-MailboxRegionalConfiguration -Timezone "AUS Eastern Standard Time" -Language 3081

Remove-PSSession $Session; 

Stop-Transcript; 