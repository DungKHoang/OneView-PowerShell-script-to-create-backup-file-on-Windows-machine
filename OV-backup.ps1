[CmdletBinding ()]
Param
(
    [string]$hostname,
    [String] $pwdfile = $( throw 'Read Password requires a password file argument - none provided' )
)

Function Write-Log (
        [string]$LogFilePath,
        [string]$text, 
        [PsCustomObject]$script_error = $null,
        [bool]$time=$true, 
        [ValidateSet("Information", "Warning", "Error")][string]$State="Information", 
        [bool]$clear=$false
    )

{
    if(!(Test-Path "$($LogFilePath)")){New-Item -Path $LogFilePath -Type File -Force | Out-Null}
    elseif($clear -eq $true){Remove-Item -Path $LogFilePath -Force}

    if(!(Test-Path $LogFilePath)){Out-File -FilePath $LogFilePath -Encoding ASCII -Force -InputObject "Log file created at $datetime"}
    if($time -eq $true){$output = "$datetime`t[$state]`t$text"}else{$output = "$text"}
    if ($script_error)
    {
        Write-Output $script_error
        Write-Output "************ An unhandled exception was caught ****************"
        Out-File -FilePath $LogFilePath -Encoding ASCII -Append -InputObject "************ An unhandled exception was caught ****************"
        Out-File -FilePath $LogFilePath -Encoding ASCII -Append -InputObject $script_error
        Out-File -FilePath $LogFilePath -Encoding ASCII -Append -InputObject "*****************************************************"
        Write-Output "Dumping variables for troubleshooting"
        Get-Variable | Out-File -FilePath $LogFilePath -Encoding ASCII -Append
    }
            
    Out-File -FilePath $LogFilePath -Encoding ASCII -Append -InputObject $output
    Write-Output "$datetime`t[$State]`t$text"
    if($State -eq "Error"){throw "Terminating script due to unhandled exception"}
    

} 


#   Set folders
$wk_folder      = (get-location).Path
$bkp_folder     = "$wk_folder\Backup"
$arch_folder    = "$wk_folder\Backup\archive"
$log_folder     = "$wk_folder\Log"
$PsModules      = "$wk_folder\PsModules"

if (!(Test-Path $log_folder))   { new-item -Path $log_folder -itemType "Directory" | Out-Null }
if (!(Test-Path $arch_folder))  { new-item -Path $arch_folder -itemType "Directory" | Out-Null }
if (Test-Path $PsModules)       { dir $PsModules | % { import-module $_.FullName} } 

#   Create log file
$datetime       = (Get-Date).ToString() 
$dt             = $datetime -replace('/','-') -replace(':','-') -replace(' ','_')
$LogFile        = "$log_folder\log-$dt.txt"

# Initialize
$error.Clear()
move-item -Path $bkp_folder\*.bkp -Destination $arch_folder
del "$log_folder\*" 

 # Check password file
if(!( Test-Path $pwdfile -errorvariable $sc_error )) 
{
    write-Log -text "File $pwdfile not found" -state 'Error' -LogFilePath $LogFile -script_error $sc_error
}

# Get the credential from file
write-Log -text "Getting credential from pwd file" -state 'Information' -LogFilePath $LogFile -script_error $sc_error
foreach ($_line in (Get-Content $pwdfile))
{
    $_text              = $_line.split('|')
    $device             = $_text[0]
    $stringtodecrypt    = $_text[2]
    # An encrypted password is assumed to be at least 100 characters in length
    If ($stringtodecrypt.length -le '100') 
    {
        write-Log -text  "$pwdfile likely to contain a plain text password that will not be valid " -state 'Error' -LogFilePath $LogFile -script_error $sc_error 
    }
    $securestr          = ConvertTo-SecureString -String $stringtodecrypt

    if ($null -eq $securestr)
    {
        write-Log -text  "Error in decoding pwd from the file" -state 'Error' -LogFilePath $LogFile -script_error $error 
    }
    if ($device -eq "OneView")
    {
        $OVuser         = $_text[1]
        $OVpassword     = $securestr
        $OV_cred        =  New-Object System.Management.Automation.PSCredential($OVuser,$OVpassword) -errorvariable $sc_error

    }
    else
    {
        $iLOuser        = $_text[1]
        $iLOpassword    = $securestr
        $iLO_cred       =  New-Object System.Management.Automation.PSCredential($iLOuser,$iLOpassword) -errorvariable $sc_error

    }

}


# Connect to OV
write-Log -text "Connecting to OneView $hostname  ....." -state 'Information' -LogFilePath $LogFile
$OVSession  =   Connect-OVMgmt -Hostname $hostname -credential $OV_cred  -errorvariable $sc_error

if ($Null -eq $OVSession)
{
    write-Log -text "Error in calling Connect-OVMgmt - Check either credential or hostname..." -state 'Error' -LogFilePath $LogFile -script_error $error 
}


write-Log -text "Initializing backup of OneView and saving it to $bkp_folder" -state 'Information' -LogFilePath $LogFile
# Initiate Backup of OneView
New-OVBackup -location $bkp_folder -ErrorAction SilentlyContinue -errorvariable $sc_error

if ($sc_error)
{
    write-Log -text "Error in calling new-OVbackup" -state 'Error' -LogFilePath $LogFile -script_error $sc_error   
}


# Disconnect OneView
write-Log -text "Disconnecting from OneView" -state 'Information' -LogFilePath $LogFile
Disconnect-OVMgmt

