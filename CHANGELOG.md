# Changelog
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
=======
## [0.0.3] - Incremental Release 6/28/2020
### Added
 - Added a sample inventory file.

## [0.0.2] - Incremental Release 6/26/2020
### Added
 - Under the StandaloneScripts directory, added a PS1 script that will get all ESXi hosts from vCenters in a CSV file and place them into an Ansible well-formed inventory file named after the vcenter. Each host will be grouped under their Cluster Name with no spaces and the footer of the file contains Ansible Var information that can be used in plays.

## [0.0.1] - Original Release 3/29/2020

### Added
Initial Release. Current available commands:

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Connect-MYvCenters                                 1.0.0      MY.VMWAREKIT
Function        Get-MYAllHardwareDriverInfo                        1.0.0      MY.VMWAREKIT
Function        Get-MYBIOSInfo                                     1.0.0      MY.VMWAREKIT
Function        Get-MYCDandDVD                                     1.0.0      MY.VMWAREKIT
Function        Get-MYCiscoDiscoveryInfo                           1.0.0      MY.VMWAREKIT
Function        Get-MYCPUCount                                     1.0.0      MY.VMWAREKIT
Function        Get-MYCPURatio                                     1.0.0      MY.VMWAREKIT
Function        Get-MYDSPercentFree                                1.0.0      MY.VMWAREKIT
Function        Get-MYFWSettingsSyslog                             1.0.0      MY.VMWAREKIT
Function        Get-MYHostConfiguration                            1.0.0      MY.VMWAREKIT
Function        Get-MYHostManagementInfo                           1.0.0      MY.VMWAREKIT
Function        Get-MYNFSShareInfo                                 1.0.0      MY.VMWAREKIT
Function        Get-MYNumberofVMsPerHost                           1.0.0      MY.VMWAREKIT
Function        Get-MYPhysicalNICInfo                              1.0.0      MY.VMWAREKIT
Function        Get-MYSyslogLogHost                                1.0.0      MY.VMWAREKIT
Function        Get-MYVIEventPlus                                  1.0.0      MY.VMWAREKIT
Function        Get-MYvMotionHistory                               1.0.0      MY.VMWAREKIT
Function        Get-MYVMsandDatastores                             1.0.0      MY.VMWAREKIT
Function        Get-MYvRAMOvercommit                               1.0.0      MY.VMWAREKIT
Function        Get-MYvSwitchSecPolicy                             1.0.0      MY.VMWAREKIT
Function        Get-MYWWNs                                         1.0.0      MY.VMWAREKIT
Function        Set-MYChangeESXiPassword                           1.0.0      MY.VMWAREKIT
Function        Set-MYDisableAdmissionControl                      1.0.0      MY.VMWAREKIT
Function        Set-MYDisconnectCD                                 1.0.0      MY.VMWAREKIT
Function        Set-MYDisconnectCDSingleVM                         1.0.0      MY.VMWAREKIT
Function        Set-MYFWAllowSyslog                                1.0.0      MY.VMWAREKIT
Function        Set-MYPowerPolicyHigh                              1.0.0      MY.VMWAREKIT
Function        Set-MYRRDefault                                    1.0.0      MY.VMWAREKIT
Function        Set-MYScratch                                      1.0.0      MY.VMWAREKIT
Function        Set-MYSYSLOGGlobalDir                              1.0.0      MY.VMWAREKIT
Function        Set-MYSyslogValue                                  1.0.0      MY.VMWAREKIT
Function        Set-MYTaggedVMtoPartial                            1.0.0      MY.VMWAREKIT
Function        Start-MYSSH                                        1.0.0      MY.VMWAREKIT
Function        Stop-MYSSH                                         1.0.0      MY.VMWAREKIT