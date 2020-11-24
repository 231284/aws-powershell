<#

Title: report-computer-ad-instances.ps1
Date: 11/19/2020
Author: Brad Perkins
Version: 1.0
Description: This script will query AD for MGEP user accounts that have been inactive for more than 90 days and email a report to Travis Lovette and the service desk on a weekly basis.
BE SURE TO HAVE THE FOLLOWING FOLDERS CREATED OR THE SCRIPT WILL NOT RUN - C:\Scripts | C:\Scripts\MGEP | C:\Scripts\MGEP\AccountsInactive

#>


function SendEmail($Server, $Port, $Sender, $Recipient, $Subject, $Body) {
    #Get SES SMTP Creds from Secrets Manager
    [string]$SecretAD = "ses-smtp-user-east.20201028-111316"
    Import-Module AWSPowerShell
    try { $SecretObj = (Get-SECSecretValue -SecretId $SecretAD) }
    catch {
        $log.WriteLine("Could not load secret <" + $SecretAD + "> - terminating execution")
        return
    }
    [PSCustomObject]$Secret = ($SecretObj.SecretString | ConvertFrom-Json)
    $password = $Secret.Password | ConvertTo-SecureString -asPlainText -Force
    $username = $Secret.Username

    $SMTPClient = New-Object Net.Mail.SmtpClient($Server, $Port)
    $SMTPClient.EnableSsl = $true
    $SMTPClient.Credentials = New-Object System.Management.Automation.PSCredential($username, $password);

    try {
        Write-Output "Sending message..."
        $SMTPClient.Send($Sender, $Recipient, $Subject, $Body)
        Write-Output "Message successfully sent to $($Recipient)"
    } catch [System.Exception] {
        Write-Output "An error occurred:"
        Write-Error $_
    }
}
function SendTestEmail(){
    $Server = "email-smtp.us-west-2.amazonaws.com"
    $Port = 587

    $Subject = "Test email sent from Amazon SES"
    $Body = "This message was sent from Amazon SES using PowerShell (explicit SSL, port 587)."

    $Sender = "no-reply@mgep.info"
    $Recipient = "bradfordlperkins@maximus.com"

    SendEmail $Server $Port $Sender $Recipient $Subject $Body
}

SendTestEmail

$daterun = (Get-Date -format "MM-dd-yyyy-HHmm")
$daterun2= (Get-Date -format "MM-dd-yyyy")
$limit = (Get-Date).AddDays(-30)
$logonDate = (Get-Date).AddDays(-89)
$path = "c:\scripts\MGEP\ComputersOU\"
$file = "$path"+"ComputersOU-$daterun.csv"
#Address the Email using this area. Make sure to edit the Send-Mailmessage script if you remove an element such as CC'd addresses
$fromaddr = "servicedesk@tech-srvs.net"
$toaddr = "bradfordlperkins@maximus.com","ChukwunonsoCAgbo@maximus.com"
$subject="Servers in the Computers OU - MGEP - $daterun2"
$body="The attached report contains the list of MGEP instances that are in the Computers OU and not in a sub OU where group policies would be applied."
$smtpServer="10.68.255.160"

Import-Module ActiveDirectory

#"The Business" - Filters in all "S-Dash" accounts for the query then pulls expiration dates
$computers = Get-ADComputer -Filter * -SearchBase "CN=Computers,DC=maxomni,DC=com" | Select-Object -Property "DNSHostName","Enabled"
$computers | Export-csv $file -NoTypeInformation
Write-Output "Sending Email Containing Report @ $file named $subject"
if($computers){
$computers
#Use this section for editing how the email is actually sent. Prefer High Priority.
Send-Mailmessage -smtpServer $smtpServer -from $fromaddr -to $toaddr -subject $subject -body $body -priority High -Attachments $file
}

#Remove logs older than 30 days
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force