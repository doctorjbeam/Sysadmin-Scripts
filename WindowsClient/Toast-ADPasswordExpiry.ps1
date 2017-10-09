Import-Module BurntToast; 

$csv = "C:\Temp\ExpiringSoon.csv"
$csv = Import-CSV $csv | Where UserName -eq $env:username; 

if ($csv -eq $null) { 
	continue;
}

New-BurntToastNotification -text "Password expiring $($csv.UserMessage)", "Your WHSC password is expiring soon. Press CTRL+ALT+DEL to change it now." -AppID "WHSC IT Department" -AppLogo "C:\colorlog-sm.png"