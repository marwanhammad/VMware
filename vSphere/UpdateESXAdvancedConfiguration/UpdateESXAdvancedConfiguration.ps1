##################################################################################################################
# Version = 2018.12.30
$Scriptversion = '2018.12.30'
#
# Created by : Marwan Hammad
# 
# Update vMotion VMK IPs
#
########################################################################

#--------------------------------------------------------------------------
# ------ 				Input arguments                            	    ---
#--------------------------------------------------------------------------
####vCenter 
$vCenterIP = ""	
#UserName do not forget @ domain name
$vCenterUser = ""
#password
$vCenterPass=''
#ClusterList:  ex: 'C1','C2' if empty, takes all Cluster in vCenter
$Cluster=''
#ESX Server
$ESXSever=''
#Advanced Configuration Name
$AdvancedConfigurationName='NFS.TcpipHeapSize'
#New Value
$AdvancedConfigurationValue='32'
# 'true' for restarting vpxa after apling the new configration ,'false' for no restarting vpxa
$RestartVPXA= $false
# Wait time after restarting vpxa, '0' is accepted input
$WaitTime = '0'

#------------------------
###Log Function
$Logfile='_UpdateESXAdvancedConfiguration.txt'
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
	Connect-VIServer $vCenterIP -User $vCenterUser -Password $vCenterPass
	Write-Host (Get-Date).ToString() "= PowerCli connected to vCenter" -ForegroundColor Green
}catch{
		Write-Host (Get-Date).ToString() "= Issue connection to vCenter with PowerCli" -ForegroundColor Red
		Stop-Transcript
		exit 2
}
#------------------------
########Script##############
Write-Host (Get-Date).ToString() "= Script version = $Scriptversion" -ForegroundColor Yellow

# Get ESXList
if(!($ESXSever -eq '')){
Write-Host (Get-Date).ToString() "= Selected ESX: $ESXSever "
$ESXiList=@()
$ESXiList=Get-VMHost $ESXSever
}elseif($Cluster -eq ''){
	Write-Host (Get-Date).ToString() "= Get all Clusters in vCenter"
	$ClusterList=(Get-Cluster).Name
	# Get ESXList
	$ESXiList=@()
	foreach ($Cluster in $ClusterList){
		Write-Host (Get-Date).ToString() "= Get ESXs list on cluster $Cluster" -ForegroundColor Yellow
		$ESXiList+=Get-Cluster $Cluster| Get-VMHost | sort Name
	}
}else{
	Write-Host (Get-Date).ToString() "= Selected Cluster: $Cluster "
	$ClusterList = $Cluster
	# Get ESXList
	$ESXiList=@()
	foreach ($Cluster in $ClusterList){
		Write-Host (Get-Date).ToString() "= Get ESXs list on cluster $Cluster" -ForegroundColor Yellow
		$ESXiList+=Get-Cluster $Cluster| Get-VMHost | sort Name
	}
}

#----------
###Execute per ESX
foreach ($ESXi in $ESXiList){
	$VMHostName=$ESXi.name
	$VMHost = Get-VMHost $VMHostName
	
	Write-Host (Get-Date).ToString() "= Selected ESX server: $VMHostName " -ForegroundColor Yellow
	Write-Host (Get-Date).ToString() "= Get Advanced Configuration: $AdvancedConfigurationName" -ForegroundColor Yellow
	$CurrentValue=($VMHost |  Get-AdvancedSetting -Name $AdvancedConfigurationName).Value
	if ($CurrentValue -eq $AdvancedConfigurationValue){
		Write-Host (Get-Date).ToString() "= ESX $VMHostName has the required $AdvancedConfigurationName Value $CurrentValue" -ForegroundColor Green
	}else{
		Write-Host (Get-Date).ToString() "= Update Advanced Configuration: $AdvancedConfigurationName from $CurrentValue to $AdvancedConfigurationValue" -ForegroundColor Cyan
	#	$Update=$VMHost | Get-AdvancedSetting -Name $AdvancedConfigurationName | Set-AdvancedSetting -Value $AdvancedConfigurationValue -Confirm:$false
		if ($RestartVPXA){
			Write-Host (Get-Date).ToString() "= Restart VPXA for : $VMHost " -ForegroundColor Cyan
			$Restart=$VMHost| Get-VMHostService | where {$_.Key -eq "vpxa"} | Restart-VMHostService -Confirm:$false -ErrorAction SilentlyContinue
			start-sleep $WaitTime
		}
	}
	
	

}


Write-Host (Get-Date).ToString() "= PowerCli Disconnected from vCenter" -ForegroundColor Green	
Disconnect-VIServer * -Force -Confirm:$false

Stop-Transcript