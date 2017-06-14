<#
	Get active users with stale passwords
	@author Michael Greenhill
	@updated 30/05/2017
#>


<#
$stalePasswordAge = (Get-Date).AddMonths(-6); 

$users = Get-ADUser -Filter 'Enabled -eq $true' -Properties passwordlastset, passwordneverexpires | Where passwordlastset -lt $stalePasswordAge
#$users | ft Name,sAMAccountName,passwordlastset,passwordneverexpires; 

Foreach ($user in $users) {
	$user.groups = (Get-ADPrincipalGroupMembership $user).Name
}

$users | ft; 
#>

get-aduser -filter * -searchbase "OU=Staff,DC=curric,DC=wheelers-hill-sc,DC=wan" -Properties * | where Enabled -eq $true | Select-Object sAMAccountName,Name,PasswordLastSet,@{name='LastLogon';expression={[DateTime]::FromFileTime($_.LastLogon)}} | Where PasswordLastSet -lt ((Get-Date).AddDays(-128)) | ft 

