Function encrypt_password(
    [ValidateSet("OneView","iLO")][string]$device)
{
    $user_text          = "Enter OneView username"
    $pwd_text           = "Enter OneView password"
    $pwd_rpt            = "Repeat OneView password"
    if ($device -eq "iLO")
    {
        $user_text      = "Enter iLO username"
        $pwd_text       = "Enter iLO password"
        $pwd_rpt        = "Repeat OneView password"
    }

    write-host "`n ********************** "
    $user                       = Read-Host $user_text 
    $secureStringPassword       = Read-Host $pwd_text -AsSecureString

    $p1                         = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureStringPassword))
    $secureStringPassword_c     = Read-Host $pwd_rpt -AsSecureString
    $p2                         = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureStringPassword_c))
    if ( $p1 -eq $p2 )
    {
        Write-Host "Store username and secure password in $FileToStorePassword"
        $encryptedPassword      = ConvertFrom-SecureString $secureStringPassword
        $_text                  = "{0}|{1}|{2}" -f $device,$user,$encryptedPassword

        Add-Content -Path $FileToStorePassword -Value $_text
    }
    else { throw("Outch! Entries do not match. Please re-run script." )}
}

$FileToStorePassword        = Read-Host "Enter filename to store encrypted password"
new-item -Name $FileToStorePassword -itemType "file" -force |out-Null
encrypt_password -device "OneView"
#encrypt_password -device "iLO"