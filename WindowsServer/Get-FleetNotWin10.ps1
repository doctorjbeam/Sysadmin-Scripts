$date = (Get-Date).AddMonths(-3)
$properties = @('Name','OperatingSystem','OperatingSystemServicePack','OperatingSystemVersion','LastLogonDate')

$computers = Get-ADComputer -Filter "OperatingSystem -notlike 'Windows 10*'" -SearchBase "DC=curric,DC=wheelers-hill-sc,DC=wan" -Properties $properties

$computers | Where LastLogonDate -gt $date | Where OperatingSystem -notlike "Windows Server*" | Where OperatingSystem -notlike "Mac OS*" | Sort-Object Name | Select-Object Name,LastLogonDate,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion | Export-Csv -Path "\\curric.wheelers-hill-sc.wan\it admin\Operational\Fleet-NotWin10.csv" -Force -NoTypeInformation
