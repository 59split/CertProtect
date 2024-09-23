function Export-CertProtectedSecretCert {
        <#
    .SYNOPSIS
        Exports an existing certificate from the users certificate store
    .DESCRIPTION
        1. Checks to see if the certificate already exists, if not it exits the function.
        2. If an output location is specified, it checks if this is writable, if not it exits the function.
        3. Exports the certificate in PFX format using a randomly generated password, which is then shared with the user.
        4. Provides instructions for the user to import the certificate elsewhere, if the export was successful.
    .PARAMETER certName
        The name of the certificate to be exported. This is a mandatory field.
    .PARAMETER filePath
        The path to output the certificate file to.
    .PARAMETER AsObject
        A switch that alters the output of the function. If present it will return a PowerShell Object containing a boolean success value,
        and a message detailing the result or issue. If not present the output will be the text of the message.
    .NOTES
        Author:         Ian Hutchison
        v0.2 - (2024-09-23) Added additional text to $return.message
        v0.1 - (2022-11-24) Initial version        
    .EXAMPLE
        Export-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\
    .EXAMPLE
        Export-CertProtectedSecret -certName MyFirstSecretCertificate -filePath c:\temp\ -AsObject
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
        Success        = $true
        Message        = ""
        OutputPath     = ""
        Password       = ""
    }

    # generate a random password for the next step
    $length = 15
    $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
    $rng.GetBytes($bytes)
    $result = New-Object char[]($length)
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
    }
    $password = ConvertTo-SecureString -String $(-join $result) -Force -AsPlainText

    # check if the certificate exists
    $cert = (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.subject -like "cn=$certName"})

    if ($cert -as [Bool] -eq $false) {
        $return.message = "Certificate specified does not exist."
        $continue = $false
    }

    # verify the output path is writable
    if ($continue) {
        $testFile = Join-Path -Path $filePath -ChildPath 'testfile.txt'
        if ($filePath -ne $env:TEMP) {
            Try { [io.file]::OpenWrite($testFile).close() }
            Catch { 
                $return.message = "Unable to write a file to outpath $filePath. Defaulting to users TEMP folder.`n$($env:TEMP)"
                $filePath = $env:TEMP
            }
        }
    }

    if ($continue) {
        # create the output full file path
        $outputPath = Join-Path $filePath -ChildPath ($certName + ".pfx")

        # export the certificate to that it can be imported into the another user profile
        Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.subject -like "cn=$certname"} | 
            Export-PfxCertificate -FilePath $outputPath -Password $password -Force |
            Out-Null

        # test exported file exists
        if (Test-Path -Path $outputPath -PathType Leaf) {
            $return.message = "The encryption certificate has been created and the corresponding decryption key exported.`n"
            $return.message += "In order to access the encrypted data on another computer, or with a differet account you will "
            $return.message += "need to import the certificate into the certificate store for that user on the device you wish to use it on."
            $return.message += "`n`n"
            $return.message += "To do that, you need to double click on the exported .pfx file using the user account which you want to be able "
            $return.message += "to access the encrypted data with. This will run the certificate import wizard. Accept all the defaults except "
            $return.message += "when it asks for the password."
            $return.message += "`n`n"
            $return.message += "The password is `'$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)))`'. "
            $return.message += "Please note it down now as it will not be shown again, and cannot be recovered."
            $return.message += "`n`n"
            $return.message += "The exported certificate file is located at $outputPath"
            $return.message += "`n`n"
            $return.message += "Finally, delete the .pfx file so that no-one else can import it."
            $return.OutputPath = $outputPath
            $return.password = $password
        }
        else {
            $return.success = $false
            $return.message =  "Failed to export the certificate. Cannot continue."
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
