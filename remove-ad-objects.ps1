<#
For usage install the AD DS RSTA Tools and DNS RSAT tools
Install-WindowsFeature rsat-dns-server
#>
Import-Module AWSPowerShell
Import-Module ActiveDirectory
$ADlog="C:\Users\a-bperkins\Desktop\adlog.txt.txt"
$NonADlog="C:\Users\a-bperkins\Desktop\log.txt.txt"
$QueueUrl="https://sqs.us-east-1.amazonaws.com/912042807419/000-e1-mgmt-adcleanup-sqs"
$SQSMessage = Receive-SQSMessage -QueueUrl $QueueUrl -WaitTimeInSeconds 10  -MessageCount 1


$Logtime=get-date -Format "dd-MM-yyyy HH-mm-ss"

if ($null -eq $SQSMessage)
 {
 }
else
 {
    $SQSMessage|ForEach-Object{
    $MessageBodyObject = $SQSMessage.Body | ConvertFrom-Json
    $ok=Get-ADComputer -filter {Name -eq $MessageBodyObject}
    if ($ok -and $ok -ne "000e1dc001" -and $ok -ne "000e2dc001" -and $ok -ne "000w1dc001" -and $ok -ne "000w2dc001"){

            if (Test-Connection -BufferSize 32 -Count 1 -ComputerName $MessageBodyObject -Quiet){
                 $logmsg = $logtime + "Still present: " + $MessageBodyObject
                }
            else{
                $logmsg = $logtime + " Deprovisioning of the following server: " + $MessageBodyObject
                Write-Output  $logmsg | Out-File -Append $ADlog
                Get-ADComputer $MessageBodyObject |Remove-ADObject -Recursive -Confirm:$false
                Remove-SQSMessage -QueueUrl $QueueUrl -ReceiptHandle $($SQSMessage.ReceiptHandle) -Select '^QueueUrl' -Force
                }
            }
    else{
            $logmsg = $logtime + " Not present in AD: " + $MessageBodyObject
            Write-Output  $logmsg | Out-File -Append $NonADlog
            Remove-SQSMessage -QueueUrl $QueueUrl -ReceiptHandle $($SQSMessage.ReceiptHandle) -Select '^QueueUrl' -Force
    }
 }
    <#
    #Send Email after successful termination
    $fromaddr = "servicedesk@tech-srvs.net"
    $toaddr = "bradfordlperkins@maximus.com","ChukwunonsoCAgbo@maximus.com"
    $subject="Instance removed from AD after AWS termination"
    $smtpServer="10.68.255.160"
    $body="$ok was removed from AD"
    Send-Mailmessage -smtpServer $smtpServer -from $fromaddr -to $toaddr -subject $subject -body $body -priority High -Attachments $NonADlog
    #>
 }