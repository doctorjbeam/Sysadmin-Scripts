# http://virot.eu/manually-remove-direct-access-from-a-client/
# https://acbrownit.com/2013/06/05/resolving-directaccess-connectivity-issues-the-easy-solution/


$nrpt = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient\DnsPolicyConfig'
Get-ChildItem -Path $nrpt| ForEach {Remove-Item $_.pspath}
Restart-Service DNSCache
& gpupdate /force /target:computer
& gpupdate /force /target:computer