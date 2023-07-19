# OneView-PowerShell-script-to-create-backup-file-on-Windows-machine

The PowerShell script OV-backup.ps1 will perform a backup operation to OneView and stores the backup file on a local folder of the Windows machine.
The script uses a password file that contains teh password as Secure String
The create-password.ps1 will be used first to encrype the password of OneView in a file


## Prerequisites
* HPE OneView PowerShell library : ```` Install-Module -Name HPEOneView.660 ````
** Note: if you use HPE OneView 8.00, you need PowerShell 7


## To run the script
```` .\create-password.p1
```` .\OV-backup.ps1 -hostname <OV-Address> -pwdFile <Password-file-created-from-previous setp>