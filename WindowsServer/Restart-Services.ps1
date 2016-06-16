# Restart critical services if they crash
# Last updated 20/5/2013
# @author Michael Greenhill

Start-Transcript C:\Scripts\Services.log;

function restartService([string]$name) {
	$Service = Get-Service | Where-Object {$_.name -eq $name};
	
	Write-Host "Looking for $name";
	
	if ($Service -eq $null) {
		Write-Host "- $name does not exist as a system service";
	} else {
		if ($Service.Status -eq "Running") {
			Write-Host "- $name is running - no need to restart";
		} else {
			Write-Host "- $name is not running - restarting";
			Restart-Service $name;
		}
	}
	
	Write-Host "";
}

restartService "vhdsvc";
restartService "nvspwmi";
restartService "vmms";
restartService "MSMFramework";
restartService "MegaMonitorSrv";

Stop-Transcript;