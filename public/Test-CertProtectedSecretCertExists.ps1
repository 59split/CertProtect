function Test-CertProtectedSecretCertExists {
   <#
    .SYNOPSIS
        Tests to see if the certificate to be used to encryt and decrypt is installed on this system.
    .DESCRIPTION
        Returns true if the certificate exists, and false if certificate does not exist.
    .PARAMETER certName
        The name (subject) of the certificate to be used to encrypt with. This is a mandatory field.
    .PARAMETER AsObject
        A switch that alters the output of the function. If present it will return a PowerShell Object containing a boolean success value,
        and a message detailing the result or issue. If not present the output will be the text of the message.
    .NOTES
        Author:         Ian Hutchison
        v0.1 - (2022-08-12) Initial version
    .EXAMPLE
        Test-CertProtectedSecretCertificateExists -certName MyFirstSecretCertificate
    .EXAMPLE
        Test-CertProtectedSecretCertificateExists -certName MyFirstSecretCertificate -AsObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$certName,
        [switch]$AsObject
    )

    # check if the certificate exists
    $certificate = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.subject -like "cn=$certName"}

    $certificateDetails = [ordered]@{
        'Certificate Name' = $certName
        'Subject' = $certificate.Subject
        'Issuer' = $certificate.Issuer
        'Friendly Name' = $certificate.FriendlyName
        'Valid From' = $certificate.NotBefore
        'Valid Until' = $certificate.NotAfter
        'EnhancedKeyUsageList' = $certificate.EnhancedKeyUsageList.FriendlyName
    }

    # return the results
    if ($AsObject) {
        return $certificateDetails
    }
    else {
        return ($certificate -as [Bool])
    }

}
