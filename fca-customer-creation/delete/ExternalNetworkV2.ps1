<#	
	.NOTES
	===========================================================================
	 Created on:   	2019-09-16 13:00
	 Created by:   	Marwan Hammad, Ereen Thabet
 	 Organization: 	OCB FCA SE Team
	 Filename:
	---------------------------------------------------------------------------

	v1.0.0	---	Initial Creation											---	2018-08-06
	v1.0.1	---	Fix Script Version bug and change the UCS Plugins			---	2018-12-06
	===========================================================================
	.DESCRIPTION
		 FCA SE External Customer Creation (Main)
		 ============================================================================
		 
		 ============================================================================
#>

#################### Params ####################
$ScriptIdentifier='[ExtNetwork]'

$site=$Customizations.VCD.name
#VCD API URL	
$vcdHost=$Customizations.VCD.vcdHost
#vCloud API version
$apiver = $Customizations.VCD.apiver
#UserName do not forget @system
$username= $Customizations.VCD.username
#password
$password= $Customizations.VCD.password
##
$baseurl = "https://$vcdHost/api"
################Script Body ####################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Script version: $(Get-ScriptVersion)" -ForegroundColor Green
####PowerCli connection to vCenter" To_BE_deleted -->>PESG.ps1
$vCenterIP = $Customizations.vCenter.vCenterIP
$vCenterUser = $Customizations.vCenter.vCenterUser
$vCenterPass=$Customizations.vCenter.vCenterPass
	try{
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerCli connection to vCenter : $vCenterIP" -ForegroundColor Green
		Connect-VIServer $vCenterIP -User $vCenterUser -Password $vCenterPass
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerCli connected to vCenter" -ForegroundColor Green
	}catch{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Issue connection to vCenter with PowerCli" -ForegroundColor Green
			Stop-Transcript
			exit 1
	}

###Call VCD token function
$headers = Get-VCDToken $vcdHost $apiver $username $password
###################### Admin Extnetwork ######################
$XMLLocation = $WorkingDirectory+'Templates\ExternalNetwork.xml'
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
$ExternalNetworkTemplate = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)

$vDSID=$Customizations.VCD.vDSID

$CSSASubnet=$CSSASubnet
$InternalSubnet=($CSSASubnet -split "\/")[1]
$IPs=Get-IPs $CSSASubnet
         
##For External Network 
$Netmask=ConvertTo-IPv4MaskString $InternalSubnet
$StartAddress=$IPs[0]
$EndAddress=$IPs[-2]
$Gateway=$IPs[-1]
###############################
$OrgName = $Customer.customer.FullName
$LW_Name = $OrgName + $Customizations.AdminPESG.LSWName 
$PortGroup = Get-VirtualPortGroup | where{$_.Name -like "*$vDSID*$LW_Name*" }
$ExtNetName =$OrgName+$Customizations.AdminVCD.ExtNetName
$VCServerRef=$Customizations.VCD.VCServerRef



########################## Edit XML file for ADMIN External Network Creation #######################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Updating XML ADMIN External Network file" -ForegroundColor Green
$xmlExtNetwork = $ExternalNetworkTemplate 
$xmlExtNetwork = $xmlExtNetwork -replace "VCServerRef",  $VCServerRef
$xmlExtNetwork = $xmlExtNetwork -replace "ExtNetName",  $ExtNetName
$xmlExtNetwork = $xmlExtNetwork -replace "Gatewayedit", $Gateway
$xmlExtNetwork = $xmlExtNetwork-replace "Netmaskedit", $Netmask
$xmlExtNetwork = $xmlExtNetwork -replace "StartAddressedit", $StartAddress
$xmlExtNetwork = $xmlExtNetwork -replace "EndAddressedit", $EndAddress
$xmlExtNetwork = $xmlExtNetwork -replace "MoRefedit" , $PortGroup.Key
##################################### Call Create EXternal Network API #################
$ContentType="application/vnd.vmware.admin.vmwexternalnet+xml"
$ExtnetworkURL = $baseurl + "/admin/extension/externalnets"
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating External Network :$ExtNetName" -ForegroundColor Green
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating External Network :$Gateway / $Netmask" -ForegroundColor Green
Try{
	$responseExtnetwork=Invoke-RestMethod -Uri $ExtnetworkURL -Headers $headers -Method POST -body $xmlExtNetwork -ContentType $ContentType
}catch{
    Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
    if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
	Exit-function
}
$TaskURL=$responseExtnetwork.VMWExternalNetwork.Tasks.Task.href
Check-vCD-Task $TaskURL



####################### INET Network #########################
$LW_Name = $OrgName + $Customizations.InetPESG.LSWName	   
$PortGroup = Get-VirtualPortGroup | where{$_.Name -like "*45*$LW_Name*" }
$ExtNetName =$OrgName + $Customizations.InetVCD.ExtNetName
########################## Edit XML file for INET External Network Creation #######################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Updating INET External Network   XML file" -ForegroundColor Green
$Gateway = $Customizations.InetVCD.Gateway
$Netmask =  $Customizations.InetVCD.Netmask
$StartAddress = $Customizations.InetVCD.StartAddress
$EndAddress = $Customizations.InetVCD.EndAddress
$xmlExtNetwork = $ExternalNetworkTemplate
$xmlExtNetwork = $xmlExtNetwork -replace "VCServerRef",  $VCServerRef
$xmlExtNetwork = $xmlExtNetwork -replace "ExtNetName",  $ExtNetName
$xmlExtNetwork = $xmlExtNetwork -replace "Gatewayedit", $Gateway
$xmlExtNetwork = $xmlExtNetwork-replace "Netmaskedit", $Netmask
$xmlExtNetwork = $xmlExtNetwork -replace "StartAddressedit", $StartAddress
$xmlExtNetwork = $xmlExtNetwork -replace "EndAddressedit", $EndAddress
$xmlExtNetwork = $xmlExtNetwork -replace "MoRefedit" , $PortGroup.Key
##################################### Call Create EXternal Network API #################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating External Network :$ExtNetName" -ForegroundColor Green
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating External Network :$Gateway / $Netmask" -ForegroundColor Green
Try{
	$responseExtnetwork=Invoke-RestMethod -Uri $ExtnetworkURL -Headers $headers -Method POST -body $xmlExtNetwork -ContentType $ContentType
}catch{
    Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
    if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
	Exit-function
}
$TaskURL=$responseExtnetwork.VMWExternalNetwork.Tasks.Task.href
Check-vCD-Task $TaskURL       
