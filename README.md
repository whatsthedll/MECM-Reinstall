# MECM-Reinstall
This removes the MECM client from your system and then completely removes all files, registry keys and services from the system. At the end it will reinstall the MECM client.

--- Instructions ---

Place the two files in this repository (mecm_reinstall.ps1 and windowsanswer.xml) in your folder that you have ccmsetup.exe and the rest of it's file.

Before running make the following changes:

1. On line 31, change the 'domain_name' part to your domain name that MECM is installed on
2. On line 118, enter in your management point URL in the /mp: switch
3. On line 118, enter in you site code in the SMSSITECODE= switch

Place the folder on the system you are targeting. Currently the script is built to run only in the powershell console. If you run remotely the end user will not see the prompts (Powershell Remote only).
