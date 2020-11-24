Import-Module ActiveDirectory
<#
Description : Update DNSHostname and SPN of all instances in an OU
For usage install the AD DS RSAT Tools and DNS RSAT tools
Install-WindowsFeature rsat-dns-server
#>
$tools = Get-WindowsFeature -Name rsat-dns-server
if ($tools.InstallState -eq "Available")
{
    Install-WindowsFeature rsat-dns-server
}

$instances = Get-ADComputer -filter "Name -like '003l*'" -searchbase "OU=Cent_OS,OU=Servers,OU=NCDOR,OU=Customers,DC=maxomni,DC=com" 
foreach ($instance in $instances)
{
    $dnshostname = $instance.Name + '.ncdor.com'
    $spn = 'host/' + $instance.Name + '.maxomni.com'

    Write-Output $('Updating DNSHostname to: ' + $dnshostname)
    Set-ADComputer -Identity $instance.Name -DNSHostName $dnshostname
    Write-Output $('Adding SPN: ' + $spn)
    Set-ADComputer -Identity $instance.Name -ServicePrincipalNames @{Add=$spn}
}
