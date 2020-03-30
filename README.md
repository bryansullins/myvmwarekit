# MYVMware PowerCLI Toolkit

MY VMware PowerCLI Toolkit: This PowerCLI module is made up of commonly-used custom actions in some environments. It also includes companion files and the ability to augment the toolkit with your own custom modules.

## Getting Started

All commands in the MY VMWAREKIT have help text. Simply use the Powershell Get-Help command to see how to use each MY Toolkit Command.

### Prerequisites

    Required: PowerCLI 10.x.x installed on the machine you intend to run these modules on.    
    Required: Run Powershell as Administrator.    
    Required: Execution policy cannot be "Restricted".    
    Optional: Git    

### [Installation](#Installation)

1. Clone the repo using the `git clone` command.
2. Start Powershell
3. `cd myvmwarekit\MY.VMWAREKIT`
4. Import the module for use:

    `PS> Import-Module ./MY.VMWAREKIT.psd1 -Global -Force -Verbose`

5. You can see the list of Commands by using the Get-Command CMDLet:

    `PS> Get-Command -Module MY.VMWAREKIT`

There is also the GetLatestToolkitfromRepo.ps1 file for users unfamiliar with git. Please ensure the GetLatestToolkitFromRepo script has the proper URLs for downloading the files for your Modules:
1. Download the GetLatestToolkitfromRepo.ps1 file into a new, empty directory.
2. Run the script by typing .\GetLatestToolkitfromRepo.ps1.
3. The script will download the latest Version of the toolkit using the latest companion manifest.
4. This script can be run repeatedly each time you need to update the local Module.
5. IMPORTANT WARNING: DO NOT run GetLatestToolkitfromRepo.ps1 in your master git repo, otherwise the files will get deleted. This should NEVER be run in the master repo directory.

### Usage

You will need to connect to the vCenter(s) yourself or use the included `profile.ps1` file.

Most Functions are built to use the ESXi host as its only parameter, but there are some exceptions.

1. Help text is available for all current functions. It is recommended that you use the help text method (as per each Function in the Module) for added modules to standardize usage.
2. Additional recommendations for running against multiple hosts:

## Running Module functions on multiple Objects (Steps):

1. Once connected to your vCenter(s), create a variable that contains the Hosts/Clusters/VMs you want to run the command on.
2. Then, use an inline ForEach loop to execute across each host.
3. Additionally, You can set the ForEach loop to a variable as well (I call this iterative variables) which would allow for additional actions, including Exporting as a report.
4. That process looks something like this, using the Get-MYHostConfiguration Module Function:

    `PS> $AllHosts = Get-VMHost | Sort-Object Name`   
    `PS> ForEach ($h in $ALLHosts) { Get-MYHostConfiguration -ESXiHost $h }`
    or .. .
    `PS> $HostConfigReport =  ForEach ($h in $ALLHosts) { Get-MYHostConfiguration -ESXiHost $h }`
    `PS> $HostConfigReport | Export-CSV -Path /path/to/report/location`

### Folder Structure:

* MY.VMWAREKIT
    * StandaloneScripts - Scripts that are valuable for use but are not part of the MYToolkit. Not maintained or documented - use at your own risk.
    * TestandSupportCode - Test code (I call this the WHITEBOARD area where I can build scripts independently. Use at your own risk.)
    
    * Relevant Files:
        * AllvCenters.csv - All known MY vCenters. For use with Connect-ToAllvCenters function.
        * GetLatestToolkitfromRepo.ps1 - Standalone "helper" script to download and Import the MY Toolkit Module.
        * MY.VMWAREKIT.psd1 - Manifest file for the VMWARE Kit Module. 
        * MY.VMWAREKIT.psm1 - Main Function file containing most relevant code (required).

### Contributing

Contact Bryan Sullins bryansullins@thinkingoutcloud.org

### Versioning

None at this time. Using "master" as the only branch.

### Authors

Bryan Sullins bryansullins@thinkingoutcloud.org

### License

Does not apply.