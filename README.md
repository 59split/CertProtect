# CertProtect

Powershell module for protecting a secret using public/private keys.

**Requires Windows 10 and PowerShell v5** I have not tested it on other operating systems or versions of Powershell.

## Use Case
This module can be used to protect a password that needs to be shared, e.g. I have a [KeePass](https://keepass.info/) password database which I want to access programatically from two user accounts on my computer; my regular user account, and my priviledged access user account.

* If I store the password in clear text inside my user profile its only accessible to me (and any other account that has admin rights on that host).
* If I store the password in clear text outisde of my user profile it is available to everyone.
* If if store the password in an encrypted format outside of my user profile it is accesssible to everyone, but only those that know the key can decrypt it. If I use a password to decrypt it I then have the same problem to protect that password, but if I encrypt it with a public key, and then give the private key only to the users I want to be able to decrypt it, then this solves my problem.

This module encrypts a password (secret) using a public key and exports the private key to be shared with others

## Installation
`Install-Module -Name CertProtect`

## Version History
### v0.2
Renamed from CertSecret to CertProtect, and added verbose and debug parameter passthrough

### v0.1
This is the initial version of this module and it contains the following functions:

* New-CertProtectedSecretCert - Creates a new document encrypting certificate and optionally exports the decryption key
* Test-CertProtectedSecretCertExists - Tests to see if the certificate to be used to encryt and decrypt is installed on this system.
* Export-CertProtectedSecretCert - Exports an existing certificate from the users certificate store
* Remove-CertProtectedSecretCert - Removes the specified certificate from the users certificate store.
* Set-CertProtectedSecret - Uses a document encrypting certificate to encrypt a message and stored it in a file on disk
* Get-CertProtectedSecret - Retrieves a password from a file on disk thats been encrypted using a digital certificate.


## Issues

Please see the issues tab above. If you have an issue and its not listed, please add it along with full steps to reproduce.
