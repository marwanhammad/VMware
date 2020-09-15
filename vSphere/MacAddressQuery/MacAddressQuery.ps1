##################################################################################################################
# Version = 2018.12.30
$Scriptversion = '2018.01.30'
#
# Created by : Marwan Hammad
# 
#
########################################################################

#--------------------------------------------------------------------------
# ------ 				Input arguments                            	    ---
#--------------------------------------------------------------------------

####vCenter 
$EPPvCenterIP = "10.19.249.13"	
#UserName do not forget @ domain name
$EPPvCenterUser = "svc_ocp_epp_vc@vsphere.local"
#password
$EPPvCenterPass='yk7!8w!$6S'


#------------------------
###Log Function
$Logfile='_MacAddressQuery.txt'
$logFolder = '.\Logs\'
if(!(test-path $logFolder)){
	Write-Host (Get-Date).ToString() "= creating LOGS directory"
	$flog=New-Item -ItemType directory -force -Path $logFolder
}else{
	Write-Host (Get-Date).ToString() "= LOGS directory already exist"
}
$logdate = get-date -Format "yyyyMMdd.hhmmss"
$log=$logFolder+$logdate+$logfile
#----
$ExportFile=$logFolder+$logdate+'_mac.csv'



Start-Transcript -Append -path $log

 #Import PowerCLI module & Check VMware PowerCLI version
	$VMW_PowerCLI = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {($_.DisplayName -Match "PowerCLI")}
 #Loading VMware Module
	Write-Host (Get-Date).ToString() "= VMware PowerCLI module loading..." -ForegroundColor Green
	if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)){
	  if ($VMW_PowerCLI.VersionMajor -lt "6"){
			Write-Host (Get-Date).ToString() "= VMware PowerCLI module Add-PsSnapin..." -ForegroundColor Green
			add-pssnapin VMware.VimAutomation.Core
		}else{
			Write-Host (Get-Date).ToString() "= VMware PowerCLI module Import-Module..." -ForegroundColor Green
			Import-Module VMware.VimAutomation.Core
		}
	}






###PowerCli connection to vCenter"
try{
	Write-Host (Get-Date).ToString() "= PowerCli connection to vCenter" -ForegroundColor Green
	Connect-VIServer $EPPvCenterIP -User $EPPvCenterUser -Password $EPPvCenterPass
	Write-Host (Get-Date).ToString() "= PowerCli connected to EPP vCenter" -ForegroundColor Green
}catch{
		Write-Host (Get-Date).ToString() "= Issue connection to vCenter with PowerCli" -ForegroundColor Red
		Stop-Transcript
		exit 2
}
#------------------------

$ClusterList = Get-Cluster
foreach ($cluster in $ClusterList){
	$clusterName =$cluster.Name
	Write-Host (Get-Date).ToString() "= $clusterName" -ForegroundColor Green
	$MACList = Get-Cluster $clusterName | Get-VM |Get-NetworkAdapter | Select-Object Parent,Name,MacAddress

	$MACList | Export-CSV -Path $ExportFile -NoType -Append

}
Write-Host (Get-Date).ToString() "= PowerCli disconnected from EPP vCenter" -ForegroundColor Green
Disconnect-VIServer * -Force -Confirm:$false

Stop-Transcript
