


$vCenterIP = ""	
$vCenterUser = ""
$vCenterPass=''
$OutputFile=""

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
	
	
$OutputFile='.\'+$OutputFile
Write-host " Get Cluster List"
$D= Get-Cluster
$D.Name
foreach($cluster in $D){
#$A= Get-VMHost -Location $cluster
$clusterName=$cluster.Name
Write-host " Get ESX list in Cluster $clusterName"
Get-Cluster $clusterName | Get-VMhost | Get-VMHostHBA -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}} | Sort VMhost,Device |  Export-Csv $OutputFile -Append
	
}
 
 #Get-Cluster  | Get-VMhost | Get-VMHostHBA -Type FibreChannel | Select Cluster,VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}} | Sort Cluster,VMhost,Device |  Export-Csv $OutputFile -Append
