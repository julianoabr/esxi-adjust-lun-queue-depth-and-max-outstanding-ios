#Requires -RunAsAdministrator
#Requires -Modules Posh-SSH
#Requires -Modules Vmware.VimAutomation.Core

<#
.Synopsis
  Set LUN Queue Depth on HBAs and Max Outstanding IOs on VMFS Devices
.DESCRIPTION
    Set LUN Queue Depth on HBAs and Max Outstanding IOs on VMFS Devices
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet

Based on these articles:

#https://community.broadcom.com/vmware-cloud-foundation/discussion/how-to-set-max-outstanding-disk-requests-to-new-lower-value
#https://community.broadcom.com/vmware-cloud-foundation/discussion/set-queue-depth-to-all-the-devices
#https://community.broadcom.com/vmware-cloud-foundation/discussion/how-to-set-max-outstanding-disk-requests-to-new-lower-value
#https://support.purestorage.com/bundle/m_howtos_for_vmware_solutions/page/Solutions/VMware_Platform_Guide/How-To_s_for_VMware_Solutions/Virtual_Volume_How_To_s/topics/task/t_updating_the_protocol_endpoint_no_of_outstanding_ios.html
https://support.purestorage.com/bundle/m_howtos_for_vmware_solutions/page/Solutions/VMware_Platform_Guide/How-To_s_for_VMware_Solutions/Virtual_Volume_How_To_s/topics/task/t_setting_the_nfnic_queue_depth_parameter.html
https://support.purestorage.com/bundle/m_howtos_for_vmware_solutions/page/Solutions/VMware_Platform_Guide/How-To_s_for_VMware_Solutions/Virtual_Volume_How_To_s/topics/task/t_updating_the_protocol_endpoint_no_of_outstanding_ios.html
https://www.google.com/search?q=get+haba+queue+depth+parameters+esxcli+powercli&rlz=1C1GCEA_enBR1151BR1151&oq=get+haba+queue+depth+parameters+esxcli+powercli&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIHCAEQIRiPAjIHCAIQIRiPAtIBCTExMjM0ajBqMagCALACAA&sourceid=chrome&ie=UTF-8
https://www.google.com/search?q=how+eap+works+vsphere&sca_esv=cf2b8f1401e73d56&rlz=1C1GCEA_enBR1151BR1151&ei=tWEzaZuoLruu1sQP1OyOsQw&ved=0ahUKEwjb1r6txKeRAxU7l5UCHVS2I8YQ4dUDCBE&uact=5&oq=how+eap+works+vsphere&gs_lp=Egxnd3Mtd2l6LXNlcnAiFWhvdyBlYXAgd29ya3MgdnNwaGVyZTIFECEYoAEyBRAhGKABMgUQIRigAUikJlCvE1iXJHABeAGQAQCYAZQBoAGYCKoBAzAuOLgBA8gBAPgBAZgCCaAC1QjCAgoQABiwAxjWBBhHwgIGEAAYFhgewgIHECEYoAEYCpgDAIgGAZAGCJIHAzEuOKAH6RyyBwMwLji4B84IwgcHMC41LjMuMcgHJA&sclient=gws-wiz-serp
https://www.google.com/search?q=change+qlnativefc+ql2xmaxqdepth%3D128+esxcli+v2+powercli&sca_esv=cf2b8f1401e73d56&ei=uWgzaZmYENOP5OUPpb-OmQ8&ved=0ahUKEwjZ2NOFy6eRAxXTB7kGHaWfI_MQ4dUDCBE&uact=5&oq=change+qlnativefc+ql2xmaxqdepth%3D128+esxcli+v2+powercli&gs_lp=Egxnd3Mtd2l6LXNlcnAiNmNoYW5nZSBxbG5hdGl2ZWZjIHFsMnhtYXhxZGVwdGg9MTI4IGVzeGNsaSB2MiBwb3dlcmNsaUjwVFCEEVi0UnAJeAGQAQCYAcIBoAGfE6oBBDEuMTe4AQPIAQD4AQGYAgagAt8CwgIKEAAYsAMY1gQYR8ICBBAhGBXCAgcQIRigARgKmAMAiAYBkAYIkgcDNC4yoAf4LLIHAzAuMrgHzALCBwUxLjQuMcgHDA&sclient=gws-wiz-serp


.AUTHOR
    Juliano Alves de Brito Ribeiro (find me at julianoalvesbr@live.com or https://github.com/julianoabr or https://youtube.com/@powershellchannel)
.VERSION
    0.3

Wisdom Bestows Well-Being
3 My son, do not forget my teaching,
    but keep my commands in your heart,
2 for they will prolong your life many years
    and bring you peace and prosperity.
3 Let love and faithfulness never leave you;
    bind them around your neck,
    write them on the tablet of your heart.
4 Then you will win favor and a good name
    in the sight of God and man.
5 Trust in the Lord with all your heart
    and lean not on your own understanding;
6 in all your ways submit to him,
    and he will make your paths straight.

#>

Clear-Host

#VALIDATE MODULE
$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Host "Vmware.VimAutomation.Core module is already loaded up" -ForegroundColor White -BackgroundColor DarkGreen
    
}#if validate module
else{
    
    Write-Host -NoNewline "Vmware.VimAutomation.Core is not loaded" -ForegroundColor DarkBlue -BackgroundColor White
    Write-Host -NoNewline " I need this module to work correctly" -ForegroundColor DarkCyan -BackgroundColor White
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop -Verbose
    
}#else validate module

#Function to Pause Script
function Pause-PSScript
{

   Read-Host 'Press [ENTER] to Continue' | Out-Null

}#end of function pause script


#VALIDATE IF OPTION IS NUMERIC
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric

Function Welcome-ToScript{

    $remoteSrvConnected = ($Env:CLIENTNAME)
    $localSrvConnected = ($env:COMPUTERNAME)
    $localUsrConnected = ($env:USERNAME)
	$rdpSessionName = ($env:SESSIONNAME)

    Write-Host "Welcome $localUsrConnected" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "You're connected to: $localSrvConnected" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "You're connected from: $remoteSrvConnected" -ForegroundColor White -BackgroundColor DarkBlue
	Write-Host "You're RDP Session is: $rdpSessionName" -ForegroundColor White -BackgroundColor DarkRed
}


function DisplayStart-Sleep ($totalSeconds)
{

$currentSecond = $totalSeconds

while ($currentSecond -gt 0) {
    
    Write-Host "Script is running. Wait more $currentSecond seconds..." -ForegroundColor White -BackgroundColor DarkGreen
    
    Start-Sleep -Seconds 1 # Pause for 1 second
    
    $currentSecond--
    }

Write-Host "Countdown concluded!. Let's Continue..." -ForegroundColor White -BackgroundColor DarkBlue

}#end of Function Display Start-Sleep


#FUNCTION CONNECT TO VCENTER
function Connect-vCenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Menu','Auto')]
        $methodToConnect = 'Menu',

        [Parameter(Mandatory=$true,
                   Position=1)]
        [System.String[]]$vCenterServerList, 
                
        [Parameter(Mandatory=$false,
                   Position=2)]
        [System.String]$dnsSuffix,
        
        [Parameter(Mandatory=$false,
                   Position=3)]
        [System.Boolean]$LastConnectedServers = $false,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [System.String]$connectionProtocol,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateSet('80','443')]
        [System.String]$port = '443'
    )

#VALIDATE IF YOU ARE CONNECTED TO ANY VCENTER 
if ((Get-Datacenter) -eq $null)
    {
        Write-Host "You're not connected to any vCenter Server" -ForegroundColor White -BackgroundColor DarkMagenta
    }#enf of IF
else{
        
        $previousvCenterConnected = $global:DefaultVIServer.Name

        Write-Host "You're connected to vCenter:$previousvCenterConnected" -ForegroundColor White -BackgroundColor Green
        
        Write-Host -NoNewline "I will disconnected you before continue." -ForegroundColor White -BackgroundColor Red
            
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

}#end of else validate if you are connected. 


if ($methodToConnect -eq 'Auto'){
        
    foreach ($vCenterServer in $vCenterServerList){
            
        $Script:workingServer = ""
        
        $Script:workingServer = $vCenterServer + '.' + $suffix

        $vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $Port -WarningAction Continue -ErrorAction Stop

   }#end of foreach vcenter list
       
}#end of If Method to Connect
else{
        
    $workingLocationNum = ""
        
    $tmpWorkingLocationNum = ""
        
    $Script:WorkingServer = ""
        
    $iterator = 0

    #MENU SELECT VCENTER
    foreach ($vCenterServer in $vCenterServerList){
	   
        $vcServerValue = $vCenterServer
	    
        Write-Output "            [$iterator].- $vcServerValue ";	
	            
        $iterator++	
                
        }#end foreach	
                
            Write-Output "            [$iterator].- Exit Script";

            while(!(isNumeric($tmpWorkingLocationNum)) ){
	                
                $tmpWorkingLocationNum = Read-Host "Type the VCSA Number that you wish to connect"
                
            }#end of while

                $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($iterator-1))  ){
	                
                    $Script:WorkingServer = $vCenterServerList[$WorkingLocationNum]
                
                }#end of IF
                else{
            
                    Write-Host "Exit selected or Invalid Number Typed. End of Script." -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Stop -Verbose
  
    
    }#end of Else Method to Connect

}#End of Function Connect to vCenter


function Create-ClusterList
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]$extvcClusterList
                
     )

$vCClusterList = @()

$vCClusterList = $extvcClusterList

$tmpWorkingClusterNum = ""
        
$Script:WorkingCluster = ""
        
$i = 0

        #CREATE CLUSTER MENU LIST
        foreach ($vCCluster in $vCClusterList){
	   
            $vCClusterValue = $vCCluster
	    
        Write-Output "            [$i].- $vCClusterValue ";	
	    
        $i++	
        
        }#end foreach	
        
        Write-Output "            [$i].- Exit this script ";

        while(!(isNumeric($tmpWorkingClusterNum)) ){
	    
            $tmpWorkingClusterNum = Read-Host "Type the Vcenter Cluster Number that you want to Adjust Round Robin"
        
        }#end of while

            $workingClusterNum = ($tmpWorkingClusterNum / 1)

        if(($workingClusterNum -ge 0) -and ($workingClusterNum -le ($i-1))  ){
	        
            $Script:WorkingCluster = $vCClusterList[$workingClusterNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else      

}#end of Function Create Cluster List

function Create-ESXiHostList
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]$extESXiHostList
                
     )

$esxiHostList = @()

$esxiHostList = $extESXiHostList

$tmpWorkingESXiHostNum = ""
        
$Script:WorkingESXiHost = ""
        
$i = 0

        #CREATE HOST MENU LIST
        foreach ($esxiHost in $esxiHostList){
	   
            $esxiHostValue = $esxiHost
	    
        Write-Output "            [$i].- $esxiHostValue ";	
	    
        $i++	
        
        }#end foreach	
        
        Write-Output "            [$i].- Exit this script ";

        while(!(isNumeric($tmpWorkingESXiHostNum)) ){
	    
            $tmpWorkingESXiHostNum = Read-Host "Type the Number of ESXi Host that you want to adjust MAX QUEUE DEPTH"
        
        }#end of while

            $workingESXiHostNum = ($tmpWorkingESXiHostNum / 1)

        if(($workingESXiHostNum -ge 0) -and ($workingESXiHostNum -le ($i-1))  ){
	        
            $Script:WorkingESXiHost = $esxiHostList[$workingESXiHostNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else      

}#end of Function Create ESXi Host List


################## Main script logic ##############################

Welcome-ToScript

Write-Host "`n"

#DEFINE VCENTER LIST
$vcServerList = @();

#ADD OR REMOVE VCs        
$vcServerList = ('server1','server2''server3') | Sort-Object

#SELECT TYPE OF CONNECTIONS
Do
{
 
 $tmpMethodToConnect = Read-Host -Prompt "Type (Menu) if you want to choose the vCenter to connect to.. 
 Type (Auto) if you want to type the name of the vCenter you will connect to."

    if ($tmpMethodToConnect -notmatch "^(?:menu\b|auto\b)"){
    
        Write-Host "You entered an invalid word. Please enter only (menu) or (auto)." -ForegroundColor White -BackgroundColor Red
    
    }
    else{
    
        Write-Host "You typed a valid word. I will proceed. =D" -ForegroundColor White -BackgroundColor DarkBlue
    
    }
    
}While ($tmpMethodToConnect -notmatch "^(?:menu\b|auto\b)")#end of while choose method to connect


if ($tmpMethodToConnect -match "^\bauto\b$"){

    [System.String]$tmpVC = Read-Host "Enter the vCenter hostname you want to connect to."

    $tmpSuffix = ""

    [System.String]$tmpSuffix = Read-Host "Enter the suffix of the vCenter you want to connect to."

    if ($tmpSuffix -like $null){
        
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -port 443 -Verbose
            
    }#end of IF
    else{
    
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -dnsSuffix $tmpSuffix -port 443 -Verbose
    
    }#end of Else
    

}#end of IF
else{

    Connect-vCenterServer -vCenterServerList $vcServerList -methodToConnect Menu -port 443 -Verbose

}#end of Else

#call function to create cluster list
Write-Output "`n"

Write-Host "Select Cluster Number to Proceed" -ForegroundColor DarkBlue -BackgroundColor White

Write-Output "`n"

$tmpvCClusterList = @()
        
$tmpvCClusterList = (VMware.VimAutomation.Core\Get-Cluster | Select-Object -ExpandProperty Name| Sort-Object)

Create-ClusterList -extvcClusterList $tmpvCClusterList

#call function to create host list
Write-Output "`n"

Write-Host "Select ESXi Host to Adjust HBA Lun Queue Depth" -ForegroundColor DarkBlue -BackgroundColor White

Write-Output "`n"
        
$tmpESXiHostList = @()
        
$tmpESXiHostList = (Vmware.VimAutomation.Core\Get-cluster -Name $WorkingCluster | Vmware.VimAutomation.Core\Get-VMHost | Select-Object -ExpandProperty Name| Sort-Object)

Create-ESXiHostList -extESXiHostList $tmpESXiHostList

Pause-PSScript

#put host in maintenance mode
#https://knowledge.broadcom.com/external/article/323119
#Put Host in Maintenance Mode
[System.String]$maintenanceReason = 'Adjust Lun Queue Depth on HBA'

$esxiHostOBJ = Vmware.VimAutomation.Core\Get-VMHost -Name $WorkingESXiHost -Verbose

Vmware.VimAutomation.Core\Set-VMHost -VMHost $esxiHostOBJ -State Maintenance -Evacuate:$true -Reason $maintenanceReason -Verbose

Pause-PSScript

#create esxcli shell
$esxcli = Get-EsxCli -VMhost $WorkingESXiHost -V2 -Verbose

#get hba driver name
[System.String]$esxiHBADriverName = ($esxcli.storage.core.adapter.list.Invoke() | Where-Object -FilterScript {$_.linkstate -eq 'link-up'} | Select-Object -Property Driver).Driver[0]

#Switch to change HBA LUN QUEUE DEPTH VALUE
switch ($esxiHBADriverName)
{
    'qlnativefc' {
        
        #get value of lun queue depth
        $ListArgs = $esxcli.system.module.parameters.list.CreateArgs()
        
        $ListArgs.module = 'qlnativefc' #Replace 'lpfc' with your HBA module name
        
        $esxcli.system.module.parameters.list.Invoke($ListArgs)

        $lunQueueDepthValue = ($parameters | Where-Object {$_.Name -eq 'ql2xmaxqdepth'}).Value

        
        if ($lunQueueDepthValue -eq '128')
        {
            
            Write-Host "Nothing to do here" -ForegroundColor White -BackgroundColor DarkBlue

        }#end of IF
        else
        {
            
            Write-Host "I have to correct the value to 128" 

            # Set the HBA module parameter (e.g., for Emulex lpfc)
            #only works on esxcli v1
            #$esxcli.system.module.parameters.set($true, "qlnativefc", "ql2xmaxqdepth=128")
            
            #Description : Description: Maximum queue depth to report for target devices.
            #Name        : ql2xmaxqdepth
            #Type        : int
            #Value       : 128       

            #create args to invoke - hash table
            $setArgs = $esxcli.system.module.parameters.list.CreateArgs()
            $setArgs.module = 'qlnativefc'
            $setArgs.parameterstring = 'ql2xmaxqdepth=128'
                        
            $esxcli.system.module.parameters.set.Invoke($setArgs)

            #view if value was changed
            $esxcli.system.module.parameters.list.Invoke(@{module = 'qlnativefc'}) | Where-Object -FilterScript {$PSItem.Name -eq 'ql2xmaxqdepth'}

        }#end of Elsege
       
    
    }#end of Qlogic 
    'lpfc' {
        
        #get value of lun queue depth
        $ListArgs = $esxcli.system.module.parameters.list.CreateArgs()
        
        $ListArgs.module = 'lpfc' # Replace 'lpfc' with your HBA module name
        
        $esxcli.system.module.parameters.list.Invoke($ListArgs)

        $lunQueueDepthValue = ($parameters | Where-Object {$_.Name -eq 'lpfc_lun_queue_depth'}).Value

        if ($lunQueueDepthValue -eq '128')
        {
            
            Write-Host "Nothing to do here" -ForegroundColor White -BackgroundColor DarkBlue

        }#end of IF
        else
        {
            
            Write-Host "I have to correct the value to 128"

            # Set the HBA module parameter (e.g., for Emulex lpfc)
            #only works on esxcli V1
            #$esxcli.system.module.parameters.set($true, "lpfc", "lpfc_lun_queue_depth=128")


            #create args to invoke - hash table
            $setArgs = $esxcli.system.module.parameters.list.CreateArgs()
            $setArgs.module = 'lpfc'
            $setArgs.parameterstring = 'lpfc_lun_queue_depth=128'
                        
            $esxcli.system.module.parameters.set.Invoke($setArgs)

            #view if value was changed
            $esxcli.system.module.parameters.list.Invoke(@{module = 'lpfc'}) | Where-Object -FilterScript {$PSItem.Name -eq 'lpfc_lun_queue_depth'}



        }#end of Else
      
    
    }#end of Emulex
    'nfnic' {
        
        #get value of lun queue depth
        $ListArgs = $esxcli.system.module.parameters.list.CreateArgs()
        
        $ListArgs.module = 'lpfc' # Replace 'lpfc' with your HBA module name
        
        $esxcli.system.module.parameters.list.Invoke($ListArgs)

        $lunQueueDepthValue = ($parameters | Where-Object {$_.Name -eq 'lun_queue_depth_per_path'}).Value

        if ($lunQueueDepthValue -eq '128')
        {
            
            Write-Host "Nothing to do here" -ForegroundColor White -BackgroundColor DarkBlue

        }#end of IF
        else
        {
            
            Write-Host "I have to correct the value to 128"

            # Set the HBA module parameter (e.g., for Emulex lpfc)
            #works only on esxcli V1
            #$esxcli.system.module.parameters.set($true, "nfnic", "lun_queue_depth_per_path=128")


            #create args to invoke - hash table
            $setArgs = $esxcli.system.module.parameters.list.CreateArgs()
            $setArgs.module = 'nfnic'
            $setArgs.parameterstring = 'lun_queue_depth_per_path=128'
                        
            $esxcli.system.module.parameters.set.Invoke($setArgs)

            #view if value was changed
            $esxcli.system.module.parameters.list.Invoke(@{module = 'nfnic'}) | Where-Object -FilterScript {$PSItem.Name -eq 'lun_queue_depth_per_path'}


        }#end of Else
    
    }#end of Cisco Native 
    'bfa'{
        
        #get value of lun queue depth
        $ListArgs = $esxcli.system.module.parameters.list.CreateArgs()
        
        $ListArgs.module = 'lpfc' # Replace 'lpfc' with your HBA module name
        
        $esxcli.system.module.parameters.list.Invoke($ListArgs)

        $lunQueueDepthValue = ($parameters | Where-Object {$_.Name -eq 'bfa_lun_queue_depth'}).Value

        if ($lunQueueDepthValue -eq '128')
        {
            
            Write-Host "Nothing to do here" -ForegroundColor White -BackgroundColor DarkBlue

        }#end of IF
        else
        {
            
            Write-Host "I have to correct the value to 128"

          # Set the HBA module parameter (e.g., for Emulex lpfc)
          #only works on V1 esxcli
          #$esxcli.system.module.parameters.set($true, "bfa", "bfa_lun_queue_depth=128")


            #create args to invoke - hash table
            $setArgs = $esxcli.system.module.parameters.list.CreateArgs()
            $setArgs.module = 'bfa'
            $setArgs.parameterstring = 'bfa_lun_queue_depth=128'
                        
            $esxcli.system.module.parameters.set.Invoke($setArgs)

            #view if value was changed
            $esxcli.system.module.parameters.list.Invoke(@{module = 'bfa'}) | Where-Object -FilterScript {$PSItem.Name -eq 'bfa_lun_queue_depth'}

        }#end of Else
    
    }#end of Brocade
    Default {
    
        Write-Host "Invalid Option. Please Try Again" -ForegroundColor White -BackgroundColor Red
    
    }#end of Default
}#end of Switch

Pause-PSScript

[System.String]$reasonToreboot = 'Change LUN Queue Depth on HBA'

VMWare.VimAutomation.Core\Restart-VMHost -VMHost $WorkingESXiHost -Reason $reasonToreboot -Confirm:$true -RunAsync -Verbose

Pause-PSScript


#for test purpose only
#$vmHost = 'tb-b6-vca-hyper-aa35.host.intranet'

#Change No of outstanding IOs with competing worlds to 128
$dsNameList = @()

$dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $WorkingESXiHost | 
Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($PSItem.ExtensionData.Summary.MultipleHostAccess) -and ($psitem.Name -like 'DS_*') -and ($psitem.Name -notlike '*CLUSTERED*')} | Select-Object -ExpandProperty Name | Sort-Object)

[System.String]$newMaxIOValue = '128'

foreach ($dsName in $dsNameList)
{
    
    $dsObj = Get-datastore -Name $dsName

    $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent.DiskName
    
    $esxObj = Get-VMHost -Name $WorkingESXiHost

    $esxcli = Get-EsxCli -VMHost $esxObj -V2
    
    #For Test Purpose Only
    #$dsNAA = 'naa.60000970000597900012533030304230'

    $dsNAAObj = $esxcli.storage.core.device.list.Invoke() | Where {$_.Device -match $dsNAA}
    
    if($dsNAAObj.NoofoutstandingIOswithcompetingworlds -ne $newMaxIOValue){

        $objSetValue = $esxcli.storage.core.device.set.CreateArgs()

        $objSetValue.device = $dsNAAObj.Device

        $objSetValue.schednumreqoutstanding = $newMaxIOValue

        $esxcli.storage.core.device.set.Invoke($objSetValue)
          
        #get new value
        $objGetValue = $esxcli.storage.core.device.list.CreateArgs()

        $objGetValue.device = $dsNAAObj.Device

        $esxcli.storage.core.device.list.Invoke($objGetValue) | Select Device,NoofoutstandingIOswithcompetingworlds

            Write-Host "LUN with Name: $dsName and NAA: $dsNAA on Host: $vmHost has outstanding IO value set to 128" -ForegroundColor White -BackgroundColor Green

        }#end of IF

        else{

            Write-Host "LUN with Name: $dsName and NAA: $dsNAA on Host: $vmHost has already outstanding IO value set to 128" -ForegroundColor White -BackgroundColor DarkBlue

        }#end of Else


}#end of ForEach

Pause-PSScript

$esxiHostOBJ = Vmware.VimAutomation.Core\Get-VMHost -Name $WorkingESXiHost -Verbose

Vmware.VimAutomation.Core\Set-VMHost -VMHost $esxiHostOBJ -State Connected -Confirm:$true -Verbose

Write-Host "End of Script" -ForegroundColor White -BackgroundColor DarkBlue