function Get-CertProtectedSecret{
    <#
    .SYNOPSIS
        Retrieves a password from a file on disk thats been encrypted using a digital certificate.
    .DESCRIPTION
        1. Checks to see if the certificate already exists, if not it exits the function.
        2. Checks if the path provided for the encrypted file exists, if not it exits the function.
        3. Reads the file from disk and decrypts the contents.
        4. Returns the decrypted text in a secure string.
    .PARAMETER certName
        The name (subject) of the certificate to be used to encrypt with. This is a mandatory field.
    .PARAMETER filePath
        The absolute file path on disk to the file where the encrypted message is stored. This is a mandatory field.
    .PARAMETER AsObject
        A switch that alters the output of the function. If present it will return a PowerShell Object containing a boolean success value,
        and a message detailing the result or issue. If not present the output will be the text of the message. 
    .NOTES
        Author:         Ian Hutchison
        v0.1 - (2022-08-12) Initial version
    .EXAMPLE
        Get-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\secretmessage.txt
    .EXAMPLE
        Get-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\secretmessage.txt -AsObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$certName,
        [Parameter(Mandatory=$true)]
        [string]$filePath,
        [switch]$AsObject
    )

    
    # variables
    $continue = $true

    # create an object to return
    $return = [PSCustomObject]@{
        success        = $true
        message        = "Successfully decrypted file."
        secureStringPassword = ""
    }

    # check if the certificate exists
    $certificateExists = [bool] (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.subject -like "cn=$certname"})
    if (-NOT $certificateExists){
        $return.success = $false
        $return.message = "Certificate does not exists. Please verify the name and try again.`n"
        $return.message += "All certs in the current users personal store can be listed using:`n"
        $return.message += "Get-ChildItem -Path Cert:\CurrentUser\My | select Subject, FriendlyName | Format-list"
        $continue = $false
    }

    # test if the file on disk exists
    if ($continue) {
        if (-NOT (Test-Path -Path $filePath -PathType Leaf)) {
            $return.Success = $false
            $return.message = "The encrypted file on disk specified does not exist. Cannot continue."
            $continue = $false
        }
    }

    # try to decrypt the message
    if ($continue) {
        
        try {
            $unencryptedPassword = Unprotect-CmsMessage -Path $filePath
            # convert the plaintext password to a secure string then embed it in a credentials object with a dummy username
            $return.secureStringPassword = $unencryptedPassword | ConvertTo-SecureString -AsPlainText -Force
            
            # now overwrite the plain text password in memory
            $unencryptedPassword = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        }
        catch {
            $return.success = $false
            $return.message = "Failed to decrypt file on disk."
            $continue = $false
        }
    }

    # return the results
    if ($AsObject) {
        return $return
    }
    else {
        if ($return.success) { Write-Output $return.secureStringPassword }
        else { Write-Warning $return.Message }
    }

}