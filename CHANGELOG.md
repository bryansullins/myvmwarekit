# Changelog
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
=======

## [0.0.2] - Incremental Release 6/26/2020
### Added
 - Under the StandaloneScripts directory, added a PS1 script that will get all ESXi hosts from vCenters in a CSV file and place them into an Ansible well-formed inventory file named after the vcenter. Each host will be grouped under their Cluster Name with no spaces and the footer of the file contains Ansible Var information that can be used in plays.

## [0.0.1] - Original Release 3/29/2020
### Added
Initial Release. Current available commands:

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Connect-MYvCenters                                 0.0.1      MY.VMWAREKIT
Function        Get-MYAllHardwareDriverInfo                        0.0.1      MY.VMWAREKIT
Function        Get-MYBIOSInfo                                     0.0.1      MY.VMWAREKIT
Function        Get-MYCDandDVD                                     0.0.1      MY.VMWAREKIT
Function        Get-MYCiscoDiscoveryInfo                           0.0.1      MY.VMWAREKIT
Function        Get-MYCPUCount                                     0.0.1      MY.VMWAREKIT
Function        Get-MYCPURatio                                     0.0.1      MY.VMWAREKIT
Function        Get-MYDSPercentFree                                0.0.1      MY.VMWAREKIT
Function        Get-MYFWSettingsSyslog                             0.0.1      MY.VMWAREKIT
Function        Get-MYHostConfiguration                            0.0.1      MY.VMWAREKIT
Function        Get-MYHostManagementInfo                           0.0.1      MY.VMWAREKIT
Function        Get-MYNFSShareInfo                                 0.0.1      MY.VMWAREKIT
Function        Get-MYNumberofVMsPerHost                           0.0.1      MY.VMWAREKIT
Function        Get-MYPhysicalNICInfo                              0.0.1      MY.VMWAREKIT
Function        Get-MYSyslogLogHost                                0.0.1      MY.VMWAREKIT
Function        Get-MYVIEventPlus                                  0.0.1      MY.VMWAREKIT
Function        Get-MYvMotionHistory                               0.0.1      MY.VMWAREKIT
Function        Get-MYVMsandDatastores                             0.0.1      MY.VMWAREKIT
Function        Get-MYvRAMOvercommit                               0.0.1      MY.VMWAREKIT
Function        Get-MYvSwitchSecPolicy                             0.0.1      MY.VMWAREKIT
Function        Get-MYWWNs                                         0.0.1      MY.VMWAREKIT
Function        Set-MYChangeESXiPassword                           0.0.1      MY.VMWAREKIT
Function        Set-MYDisableAdmissionControl                      0.0.1      MY.VMWAREKIT
Function        Set-MYDisconnectCD                                 0.0.1      MY.VMWAREKIT
Function        Set-MYDisconnectCDSingleVM                         0.0.1      MY.VMWAREKIT
Function        Set-MYFWAllowSyslog                                0.0.1      MY.VMWAREKIT
Function        Set-MYPowerPolicyHigh                              0.0.1      MY.VMWAREKIT
Function        Set-MYRRDefault                                    0.0.1      MY.VMWAREKIT
Function        Set-MYScratch                                      0.0.1      MY.VMWAREKIT
Function        Set-MYSYSLOGGlobalDir                              0.0.1      MY.VMWAREKIT
Function        Set-MYSyslogValue                                  0.0.1      MY.VMWAREKIT
Function        Set-MYTaggedVMtoPartial                            0.0.1      MY.VMWAREKIT
Function        Set-MYvSwitchSecPolicy                             0.0.1      MY.VMWAREKIT
Function        Start-MYSSH                                        0.0.1      MY.VMWAREKIT
Function        Stop-MYSSH                                         0.0.1      MY.VMWAREKIT
