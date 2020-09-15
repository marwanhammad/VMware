##################################################################################################################
# Version = 2019.01.27
$Scriptversion = '2019.01.27'
#
# Created by : Marwan Hammad
# 
# Enabling Changed Block Tracking (CBT) on virtual machines
#
########################################################################
#Ref: https://kb.vmware.com/s/article/1031873

#--------------------------------------------------------------------------
# ------ 				Input arguments                            	    ---
#--------------------------------------------------------------------------
####vCenter 
$vCenterIP = ""	
###Script is using the same Windows login

#VM Name ex: 'VM1','VM2'
$VMslist=''
#,'obitedhs-vdl012.data.edh','obitedhs-vdl005.data.edh','obitedhs-vdl018.data.edh'


#------------------------
###Log Function
$Logfile='_Enabling .txt'
$logFolder = '.\Logs\'
if(!(test-path $logFolder)){
	Write-Host (Get-Date).ToString() "= creating LOGS directory"
	$flog=New-Item -ItemType directory -force -Path $logFolder
}else{
	Write-Host (Get-Date).ToString() "= LOGS directory already exist"
}
$logdate = get-date -Format "yyyyMMdd.hhmmss"
$log=$logFolder+$logdate+$logfile

Start-Transcript -Append -path $log

#### Import PowerCLI module & Check VMware PowerCLI version
####	$VMW_PowerCLI = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {($_.DisplayName -Match "PowerCLI")}
#### Loading VMware Module
####	Write-Host (Get-Date).ToString() "= VMware PowerCLI module loading..." -ForegroundColor Green
####	if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)){
####	  if ($VMW_PowerCLI.VersionMajor -lt "6"){
####			Write-Host (Get-Date).ToString() "= VMware PowerCLI module Add-PsSnapin..." -ForegroundColor Green
####			add-pssnapin VMware.VimAutomation.Core
####		}else{
####			Write-Host (Get-Date).ToString() "= VMware PowerCLI module Import-Module..." -ForegroundColor Green
####			Import-Module VMware.VimAutomation.Core
####		}
####	}
####

###PowerCli connection to vCenter"
try{
	Write-Host (Get-Date).ToString() "= PowerCli connection to vCenter" -ForegroundColor Green
	# Connect-VIServer $vCenterIP -User $vCenterUser -Password $vCenterPass
	Connect-VIServer $vCenterIP
	Write-Host (Get-Date).ToString() "= PowerCli connected to vCenter" -ForegroundColor Green
}catch{
		Write-Host (Get-Date).ToString() "= Issue connection to vCenter with PowerCli" -ForegroundColor Red
		Stop-Transcript
		exit 2
}
#------------------------
########Script##############
Write-Host (Get-Date).ToString() "= Script version = $Scriptversion" -ForegroundColor Yellow


Foreach ($VM in $VMslist){
	if (!($VM -eq '')){
		# Get VM
		Write-Host (Get-Date).ToString() "= Selected VM: $VM "  -ForegroundColor Green	
		$VMView = Get-vm $vm | get-view
		$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
		# enable ctk
		$vmConfigSpec.changeTrackingEnabled = $true
		Write-Host (Get-Date).ToString() "= Update CBT for VM: $VM "  -ForegroundColor Green		
		$VMView.reconfigVM($vmConfigSpec)
		Write-Host (Get-Date).ToString() "= Take new Snapshot"  -ForegroundColor Yellow
		$snap=New-Snapshot $vm -Name "EnableCBT"
		Write-Host (Get-Date).ToString() "= Remove Snapshot"  -ForegroundColor Yellow
		$snap | Remove-Snapshot -confirm:$false
	}
}

Write-Host (Get-Date).ToString() "= PowerCli Disconnected from vCenter" -ForegroundColor Green	
Disconnect-VIServer * -Force -Confirm:$false

Stop-Transcript