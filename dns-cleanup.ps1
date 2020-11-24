Import-Module ActiveDirectory
$NodeToDelete= "000e1tool002"

$DNSServer = "000e1dc001"
$NodeARecord = $null
$getZoneName = nslookup $NodeToDelete
$ZoneNameArray = $getZoneName.Split('.')
$ZoneName = $ZoneNameArray[1] + "." + $ZoneNameArray[2]

Write-Output "Check for existing DNS record(s)"
$NodeARecord = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer -Node $NodeToDelete -RRType A -ErrorAction SilentlyContinue
if($NodeARecord -eq $null){
    Write-Output "No A record found"
} 
else {
    Remove-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer -InputObject $NodeARecord -Force
    Write-Output ("A gone: "+$NodeARecord.HostName)
}