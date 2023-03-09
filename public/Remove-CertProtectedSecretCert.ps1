function Remove-CertProtectedSecretCert {
       <#
    .SYNOPSIS
        Removes the specified certificate from the users certificate store.
    .DESCRIPTION
        Verifies that the specified certificate exists in the current users certificate store, and if so it tries to remove it, and reports the result.
    .PARAMETER certName
        The name (subject) of the certificate to be uremoved. This is a mandatory field. This needs to be the full subject name.
    .PARAMETER AsObject
        A switch that alters the output of the function. If present it will return a PowerShell Object containing a boolean success value,
        and a message detailing the result or issue. If not present the output will be the text of the message.
    .NOTES
        Author:         Ian Hutchison
        v0.1 - (2022-11-24) Initial version
    .EXAMPLE
        Remove-CertProtectedSecretCert -certName MyFirstSecretCertificate
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$certName,
        [switch]$AsObject
        )

    # variables
    $continue = $true

    # create an object to return
    $return = [PSCustomObject]@{
        Success        = $true
        Message        = "Successfully removed $certName certificate from current users certificate store."
    }

    # check if the certificate exists
    $cert = (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.subject -like "cn=$certName"})

    if ($cert -as [Bool] -eq $false) {
        $return.message = "Certificate specified does not exist."
        $continue = $false
    }

    if ($continue) {
        # remove the certificate
        $cert | Remove-Item
        # test if it was removed successfully
        $certVerify = (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.subject -like "cn=$certName"})
        if ($certVerify -as [Bool] -eq $true) {
            $return.message = "Certificate exists but could not be removed."
            $continue = $false
        }
    }

    # return the results
    if ($AsObject) {
        return $return
    }
    else {
        if ($return.success) { Write-Output $return.Message }
        else { Write-Warning $return.Message }
    }

}