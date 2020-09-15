##################################################################################################################
# Version = 2018.10.18
#
# Created by : Marwan Hammad
# 
#
# VMK Inventory
#
########################################################################

####vCenter 
$vCenterIP = ""
#UserName do not forget @ domain name
$vCenterUser = ""
#password
$vCenterPass=''
##don't remove .csv
$OutputFile=''

######################
# Import PowerCLI module & Check VMware PowerCLI version
	$VMW_PowerCLI = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {($_.DisplayName -Match "PowerCLI")}
# Loading VMware Module
	Write-Output "VMware PowerCLI module loading..." 

	if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)){
	  if ($VMW_PowerCLI.VersionMajor -lt "6"){
			Write-Output "VMware PowerCLI module Add-PsSnapin..." 
			add-pssnapin VMware.VimAutomation.Core
		}else{
			Write-Output "VMware PowerCLI module Import-Module..." 
			Import-Module VMware.VimAutomation.Core
		}
	}

###PowerCli connection to vCenter"
	try{
		Write-Output "PowerCli connection to vCenter"

		Connect-VIServer $vCenterIP -User $vCenterUser -Password $vCenterPass
		Write-Output "PowerCli connected to vCenter"
	}catch{
			Write-Output -ForeGroundColor Red "Issue connection to vCenter with PowerCli"
			
			exit 1
	}


$ClusterList=(Get-Cluster).Name
Write-Host (Get-Date).ToString() "= Get Cluster List"


foreach ($Cluster in $ClusterList){
	Write-Host (Get-Date).ToString() "= Get ESXs list on cluster $Cluster" -ForegroundColor Yellow
	$ESXiList=Get-Cluster $Cluster| Get-VMHost | sort Name
	foreach ($ESXi in $ESXiList){
		$VMHost=$ESXi.name
		Write-Host (Get-Date).ToString() "= Get VMkernel Info for $VMHost" -ForegroundColor Green
		$VMKList = Get-VMHostNetworkAdapter -VMHost $VMHost -VMKernel |  Export-Csv $OutputFile -Append
		

	}
}	
	
Disconnect-VIServer * -Force -Confirm:$false
