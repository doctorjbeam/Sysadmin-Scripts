<#
	Start an image build
	
	@updated 6/09/2016
	@author Michael Greenhill
#>

Start-Transcript "$(Get-Location)\StartImage.log";

$clientVmName = "ImageDev-eduSTAR Core"
$clientVmHost = "WHSC-HV01"
$serverVmName = "ImageDev-WS 2012 R2"
$serverVmHost = "WHSC-HV01"

if ((Get-VM -Name $clientVmName -ComputerName $clientVmHost).State -eq "Running") {
	Write-Output "Turning off client VM"
	Stop-VM -Name $clientVmName -ComputerName $clientVmHost -Force -TurnOff
}

if ((Get-VM -Name $serverVmName -ComputerName $serverVmHost).State -eq "Running") {
	Write-Output "Turning off server VM"
	Stop-VM -Name $serverVmName -ComputerName $serverVmHost -Force -TurnOff
}

Write-Output "Finding network adaptors..."
$clientVMNetworkAdapter = Get-VMNetworkAdapter -VMName $clientVmName -ComputerName $clientVmHost
$serverVMNetworkAdapter = Get-VMNetworkAdapter -VMName $serverVmName -ComputerName $serverVmHost

Write-Output "Re-configuring VMs"
Set-VMFirmware -VMName $clientVmName -ComputerName $clientVmHost -BootOrder $clientVMNetworkAdapter
Set-VMFirmware -VMName $serverVmName -ComputerName $serverVmHost -BootOrder $serverVMNetworkAdapter

Write-Output "Starting VMs"
Start-VM -Name $clientVmName -ComputerName $clientVmHost
Start-VM -Name $serverVmName -ComputerName $serverVmHost

Write-Output "Client VM status is: $((Get-VM -Name $clientVmName -ComputerName $clientVmHost).State)"
Write-Output "Client VM status is: $((Get-VM -Name $serverVmName -ComputerName $serverVmHost).State)"

Stop-Transcript; 