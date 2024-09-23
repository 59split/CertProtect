function Set-CertProtectedSecret {
    <#
    .SYNOPSIS
        Uses a document encrypting certificate to encrypt a message and stored it in a file on disk
    .DESCRIPTION
        1. Checks to see if the certificate already exists, if not it exits the function.
        2. Checks if the path provided for the output file is writable, if not it exits the function.
        3. Prompts the user for the message to be encrypted and then encrypts it and writes the result to disk.

        Note: A secure string is used when prompting for the users message to mask the users input on screen and from any logs.
        As only the user that created the secure string can convert it back to a regular string, we need
        to do that before we save it to the file so other user accounts can access it (if they have the correct certificate).
    .PARAMETER certName
        The name (subject) of the certificate to be used to encrypt with. This is a mandatory field.
    .PARAMETER filePath
        The absolute file path on disk to where the encypted message is to be written. This is a mandatory field.
    .PARAMETER prompt
        The message to be displayed to the user when asking for the message that will be encrypted.
        Defaults to "Enter the message you want to encrypt"
    .PARAMETER AsObject
        A switch that alters the output of the function. If present it will return a PowerShell Object containing a boolean success value,
        and a message detailing the result or issue. If not present the output will be the text of the message.
    .NOTES
        Author:         Ian Hutchison
        v0.2 - (2024-09-23) Added debug and verbose passthrough
        v0.1 - (2022-08-12) Initial version
    .EXAMPLE
        Set-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\secretmessage.txt
    .EXAMPLE
        Set-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\secretmessage.txt -prompt "Enter message"
    .EXAMPLE
        Set-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\secretmessage.txt -AsObject
    .EXAMPLE
        Set-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\secretmessage.txt -prompt "Enter message" -AsObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$certName,
        [Parameter(Mandatory=$true)]
        [string]$filePath,
        [string]$prompt = "Enter the message you want to encrypt",
        [switch]$AsObject
    )

    # variables
    $continue = $true

    # create an object to return
    $return = [PSCustomObject]@{
        Success        = $true
        Message        = "Successfully wrote encrypted text to disk."
    }

    # check if the certificate exists
    $certificateExists = Test-CertProtectedSecretCertExists -certname $certName -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true) -Debug:($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent -eq $true) 
    if (-NOT $certificateExists){
        $return.Success = $false
        $return.message = "Certificate does not exists. Please verify the name and try again.`n"
        $return.message += "All certs in the current users personal store can be listed using:`n"
        $return.message += "Get-ChildItem -Path Cert:\CurrentUser\My | select Subject, FriendlyName | Format-list"
        $continue = $false
    }

    # verify the output path is writable
    if ($continue) {
        Try { [io.file]::OpenWrite($filePath).close() }
        Catch { 
            $return.Success = $false
            $return.message = "Unable to write a file to outpath $filePath. Cannot continue."
            $continue = $false
        }
    }

    # try to encrypt the message
    if ($continue) {
        $ss = Read-Host -Prompt $prompt -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
        $mp = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        try {
            $mp | Protect-CmsMessage -To "cn=$certName" -OutFile $filePath
        }
        catch {
            $return.Success = $false
            $return.message = "Failed to create encrypted file on disk."
            $continue = $false
        }
    }

    # return the results
    if ($AsObject) {
        return $return
    }
    else {
        if ($result.success) { Write-Output $return.Message }
        else { Write-Warning $return.Message }
    }

}
