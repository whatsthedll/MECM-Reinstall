# Microsoft Endpoint Configuration Manager client reinstall script
# Version: 0.8
# Author: whatsthedll
#
# -------------------------------------------------
#
# 0.6 - Edited 5/22/21
# - Added a wait for 15 seconds after the SoftwareDistribution folder is removed
# - Added a wait for 10 seconds after the start of the ccm client installation
#
# 0.7 - Edited 6/8/21
# - Added Configuration parameters section
# - Added variable $computername that will be used for the removal of services
# - Added commands to remove files related to the MECM client
# - Added commands to remove registry keys and settings
# - Added commands to remove services
#
# 0.8 - Edited 6/28/21
# - Added visual confirmation when a step completes

# Configuration parameters
$computername = (Get-CimInstance -ClassName Win32_ComputerSystem).Name

# Set permissions on the CCM folder
write-host 'Setting permissions for the CCM folder...'
$ccmpath = "C:\Windows\CCM"
$NewAcl = Get-Acl -Path $ccmpath
$fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule("domain_name\Domain Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$NewAcl.SetAccessRule($fileSystemAccessRule)
Set-Acl -Path $ccmpath -AclObject $NewAcl
write-host "Complete."

# Start the uninstall
write-host 'Uninstalling Microsoft Endpoint Configuration Manager client...'
start-process -filepath "C:\Windows\ccmsetup\ccmsetup.exe" -argumentlist "/uninstall"

# Stop the script until the uninstall is complete
do {
    if ((get-process ccmsetup -erroraction silentlycontinue) -eq $null) {
        $ccmsetup = $false
    }
    else {
        $ccmsetup = $true
    }
}
until (
    $ccmsetup -eq $false
)
write-host 'Waiting for the uninstall to close gracefully...'
start-sleep 30
write-host 'Complete.'

# Remove all folders related to MECM
write-host 'Removing all folders related to the MECM client...'
remove-item -path 'C:\Windows\CCM' -force -recurse
start-sleep 5
remove-item -path 'C:\Windows\ccmsetup' -force -recurse
start-sleep 5
remove-item -path 'C:\Windows\ccmcache' -force -recurse
start-sleep 5
write-host 'Complete.'

# Remove registry keys and settings related to MECM
write-host 'Removing all registry keys and settings related to the MECM client...'
remove-item -path 'HKLM:\SYSTEM\CurrentControlSet\Services\SMS Agent Host Service' -force -recurse
start-sleep 5
remove-item -path 'HKLM:\SYSTEM\CurrentControlSet\Services\CCMSetup' -force -recurse
start-sleep 5
write-host 'Complete.'

# Remove files related to MECM
write-host 'Removing all files related to the MECM client...'
remove-item -path 'C:\Windows\SMSCFG.INI' -force
start-sleep 5
remove-item -path 'C:\Windows\sms*.mif' -force
start-sleep 5
write-host 'Complete.'

# Remove services related to MECM
write-host 'Removing all services related to MECM...'
get-wmiobject -query "Select * from __Namespace where name='ccm'" -namespace "root" -computername $computername | remove-wmiobject
start-sleep 5
get-wmiobject -query "select * from __Namespace where name='SMS'" -namespace "root\cimv2" -computername $computername | remove-wmiobject
start-sleep 5
write-host 'Complete.'

# Remove the SoftwareDistribution folder
write-host 'Resetting the Windows Update service...'
stop-service -name wuauserv
start-sleep 15
remove-item -path 'C:\Windows\SoftwareDistribution' -force -recurse
start-sleep 15
start-service -name wuauserv
write-host 'Complete.'

# Run the Windows Update Troubleshooter
write-host 'Running the Windows Update Troubleshooter...'
get-troubleshootingpack -path 'C:\Windows\diagnostics\system\WindowsUpdate' | invoke-troubleshootingpack -answerfile '.\windowsanswer.xml' -unattended
start-sleep 60
write-host 'Complete.'

# Reinstall the client
write-host 'Installing the MECM client...'
.\ccmsetup.exe /mp:mp_address SMSSITECODE=site_code
start-sleep 10
write-host 'Complete.'
