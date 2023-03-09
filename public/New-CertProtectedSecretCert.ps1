function New-CertProtectedSecretCert {
    <#
    .SYNOPSIS
        Creates a new document encrypting certificate and optionally exports the decryption key
    .DESCRIPTION
        1. Checks to see if the certificate already exists, if so it provides instructions on how to delete it, then exits the function.
        2. If an output location is specified, it checks if this is writable, if not it reverts to the default users temp folder.
        3. Creates the document encrypting certificate using the supplied details.
        4. Tests the certificate was created successfully, if not it exits the function.
        5. Optionally, exports the decryption certificate, and tests it exported to the disk.
        6. Provides instructions for the user to import the certificate elsewhere, if the export was successful.
    .PARAMETER certName
        The name of the certificate to be created. This is a mandatory field.
    .PARAMETER certFriendlyName
        The friendly name of the certificate to be created. This is a mandatory field.
    .PARAMETER yearsValid
        An integer number of year from today that the certificate will be valid for. Defaults to 5.
    .PARAMETER filePath
        The path to output the certificate file to. If omitted, or the path is not writeable then this defaults
        to the users temp folder as defined by the account environment variables.
    .PARAMETER AsObject
        A switch that alters the output of the function. If present it will return a PowerShell Object containing a boolean success value,
        and a message detailing the result or issue. If not present the output will be the text of the message.
    .PARAMETER export
        A switch that alters the output of the function. If present, it export the cerificate that can decrypt the secret.
    .NOTES
        Author:         Ian Hutchison
        v0.1 - (2022-08-12) Initial version
        v0.2 - (2022-11-24) Moved exporting the certificate to a separate function so it can be ran independently if needed.        
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert"
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -filePath c:\temp\
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -filePath c:\temp\ -yearsValid 2
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -yearsValid 2
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -AsObject
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -filePath c:\temp\ -AsObject
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -filePath c:\temp\ -yearsValid 2 -AsObject
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -yearsValid 2 -AsObject
    .EXAMPLE
        New-CertProtectedSecret -certName MyFirstSecretCertificate -certFriendlyName "My First Cert" -yearsValid 2 -AsObject -export
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$certName,
        [Parameter(Mandatory=$true)]
        [string]$certFriendlyName,
        [int]$yearsValid = 5,
        [string]$filePath = $env:TEMP,
        [switch]$AsObject,
        [switch]$export
    )

    # variables
    $continue = $true

    # create an object to return
    $return = [PSCustomObject]@{
        success        = $true
        message        = ""
        outputPath     = ""
        password       = ""
    }

    # verify that this certificate does not exist so we dont overwrite it
    $certificateExists = Test-CertProtectedSecretCertExists -certName $certname
    if ($certificateExists){
        $return.success = $false
        $return.message = "Certificate already exists. Delete the certificate by running the following command before trying again.`n"
        $return.message += "Remove-CertProtectedSecretCert -certName $certname `n`n"
        $return.message += "Or review the current certificate information by running:`n"
        $return.message += "Test-CertProtectedSecretCert -certName $certname `n`n"
        $continue = $false
    }

    # create the certificate, and test
    if ($continue) {
        # create the certificate
        $newSelfSignedCertificateExParameters = @{
                    Subject            = "CN=$certName"
                    Type               = 'DocumentEncryptionCert'
                    KeyUsage           = @('DataEncipherment','KeyEncipherment')
                    FriendlyName       = $certFriendlyName
                    KeyExportPolicy    = 'ExportableEncrypted'
                    KeyLength          = 2048
                    Provider           = 'Microsoft Enhanced Cryptographic Provider v1.0'
                    KeyAlgorithm       = 'RSA'
                    NotAfter           = $([datetime]::now.AddYears($yearsValid))
                    CertStoreLocation  = "cert:\CurrentUser\My"
                }
        New-SelfSignedCertificate @newSelfSignedCertificateExParameters | Out-Null

        # test if the cert was successfully created
        $certificateExists = Test-CertProtectedSecretCertExists -certName $certname      
        
        if (-NOT $certificateExists) {
            $return.success = $false
            $return.message =  "Failed to create the certificate. Cannot continue."
            $continue = $false
        }
    }

    # export the certificate
    if ($continue) {
        $exportResults = Export-CertProtectedSecretCert -certName $certname -filePath $filePath -AsObject
        $exportResults
        if ($exportResults.success = $false) {
            $return.message =  "Successfully created the certificate but failed to export it. Cannot continue.`n"
            $return.message += "Try manually exporting the certificate using the following command:`n"
            $return.message += "Export-CertProtectedSecretCert -certName $certname `n`n"
            $continue = $false
        }
        else {
            $return.message = $exportResults.message
        }
    }

    
    # return the results
    if ($AsObject) {
        return $return
    }
    else {
        if ($return.success) { Write-Output $return.message }
        else { Write-Warning $return.message }
    }

}