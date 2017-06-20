$csv = @(); 

$vms = Get-VM | Where State -eq "Running"

$csv 

foreach ($vm in $vms) {
	$object = New-Object –TypeName PSObject
	$object | Add-Member –MemberType NoteProperty –Name VMName –Value $vm.Name; 
	$object | Add-Member –MemberType NoteProperty –Name VMHost –Value $env:COMPUTERNAME; 
	$object | Add-Member –MemberType NoteProperty –Name Generation –Value $vm.Generation; 
	$object | Add-Member –MemberType NoteProperty –Name RAMMinimum –Value (($vm | Get-VMMemory).Minimum/1MB)
	$object | Add-Member –MemberType NoteProperty –Name RAMStartup –Value (($vm | Get-VMMemory).Startup/1MB)
	$object | Add-Member –MemberType NoteProperty –Name RAMMaximum –Value (($vm | Get-VMMemory).Maximum/1MB)
	$object | Add-Member –MemberType NoteProperty –Name CPUs –Value (($vm | Get-VMProcessor).Count)
	$object | Add-Member –MemberType NoteProperty –Name AutomaticStartAction –Value (($vm | Select-Object AutomaticStartAction).AutomaticStartAction)
	
	$object | Add-Member –MemberType NoteProperty –Name HDD0 -Value $null
	$object | Add-Member –MemberType NoteProperty –Name HDD1 -Value $null
	$object | Add-Member –MemberType NoteProperty –Name HDD2 -Value $null
	
	$object | Add-Member –MemberType NoteProperty –Name eth0 -Value $null
	$object | Add-Member –MemberType NoteProperty –Name eth1 -Value $null
	$object | Add-Member –MemberType NoteProperty –Name eth2 -Value $null
	$object | Add-Member –MemberType NoteProperty –Name eth3 -Value $null
	
	<#
	if ($vm.Generation -eq 2) {
		$object | Add-Member -MemberType NoteProperty -Name BootOrder -Value ($vm | Get-VmFirmware).BootOrder
		$object | Add-Member -MemberType NoteProperty -Name SecureBoot -Value ($vm | Get-VmFirmware).SecureBoot
	}
	#>
	
	$hdd = $vm | Get-VMHardDiskDrive; 
	
	foreach ($disk in $hdd) {
		if ($hdd.Length -eq 1) { 
			$label = "0"; 
		} else {
			$label = $hdd.IndexOf($disk)
		}
		
		$object."HDD$label" = $disk.Path
	}
	
	$interfaces = $vm | Get-VMNetworkAdapter;
	
	foreach ($int in $interfaces) {
		if ($interfaces.Length -eq 1) { 
			$label = "0"; 
		} else {
			$label = $interfaces.IndexOf($int)
		}
		
		$object."eth$label" = ($int.IPAddresses -Join ", ")
	}
	
	$vm | Get-VMIntegrationService | Foreach { 
		$object | Add-Member –MemberType NoteProperty –Name $_.Name –Value $_.Enabled
	}
	
	$csv += $object; 
}

$csv | export-csv "\\curric.wheelers-hill-sc.wan\it admin\documentation\sips\2017\Virtual Machines.csv" -notype -append
