<#	
	.NOTES
	===========================================================================
	 Created on:   	2019-09-16 
	 Created by:   	Marwan Hammad, Ereen Thabet
 	 Organization: 	OCB FCA SE Team
	 Filename:
	---------------------------------------------------------------------------

	v1.0.0	---	Initial Creation								---	2018-08-06
	v1.0.1	---	Read customer inputs from json file			    ---	2018-11-15
	v1.0.2  ---	Add Org			                                ---	2018-11-16
	v1.0.3  ---	Add Users	                                    ---	2018-11-16
	v1.0.4  ---	Add Org VDC                                     ---	2018-11-20
	v1.0.5  ---	Add OrgVDC Edge                                 ---	2018-11-25
	v2.0.0	---	Change Script structure 			            ---	2019-09-16
	v2.0.1	---	Read inputs from Customer.xml and site.ini      ---	2019-09-16
	v2.0.2	---	Update authentication function                  ---	2019-09-17
	v2.0.3	--- Add Org                                         ---	2019-09-18
	v2.0.4	--- Add OrgNetwork                                  ---	2019-09-19
	v2.0.5	--- Add Inet Edge Creation                          --- 2019-10-30
	v2.0.6	--- Add  Direct Admin OrgNetwork                    --- 2019-10-31
	v2.0.7	--- Update External Network                         --- 2019-11-01
	
	
	===========================================================================
	.DESCRIPTION
		 FCA SE External Customer Creation (Main)
		 ============================================================================
		 
		 ============================================================================
#>

#################### Params ####################
$ScriptIdentifier='[VCD]'

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

######Advanced Params########
$TerminateIfOrgExist=$false
$TerminateIfOrgVDCExist=$false
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

$ScriptIdentifier='[VCD][ExternalNetwork]'
########################## Get All External Networks from vCD ############################
$ExtnetworksURL = $baseurl + "/admin/extension/externalNetworkReferences"

Try{
	$responseExtnetworks=Invoke-RestMethod -Uri $ExtnetworksURL -Headers $headers -Method GET 
	#$AdminExternalNetwork = $responseExtnetworks.VMWExternalNetworkReferences.ExternalNetworkReference  | where {$_.Name -eq  $AdminExtNetName }
	#$AdminExternalNetwork.Name
	#$InetExternalNetwork = $responseExtnetworks.VMWExternalNetworkReferences.ExternalNetworkReference  | where {$_.Name -eq  $InetExtNetName }
	#$InetExternalNetwork.Name

}catch{
    Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
    if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
	Exit-function
}


###################### Admin Extnetwork ######################
$XMLLocation = $WorkingDirectory+'Templates\ExternalNetwork.xml'
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
$ExternalNetworkTemplate = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)
$vDSID=$Customizations.VCD.vDSID
$CSSASubnet=$CSSASubnet
$InternalSubnet=($CSSASubnet -split "\/")[1]
$IPs=Get-IPs $CSSASubnet
         
##For External Network 
$AdminNetmask=ConvertTo-IPv4MaskString $InternalSubnet
$AdminStartAddress=$IPs[0]
$AdminEndAddress=$IPs[-2]
$AdminGateway=$IPs[-1]
#############Global Inputs##################
$OrgName = $Customer.customer.OrgName
$OrgFullName = $Customer.customer.FullName
$AdminLW_Name = $OrgName + $Customizations.AdminPESG.LSWName 
$AdminPortGroup = Get-VirtualPortGroup | where{$_.Name -like "*$vDSID-*$OrgName*_ADMIN*" }
$AdminExtNetName =$OrgName+$Customizations.AdminVCD.ExtNetName

$VCServerRef=$Customizations.VCD.VCServerRef




########################## Edit XML file for ADMIN External Network Creation #######################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Updating XML ADMIN External Network file" -ForegroundColor Green
$AdminxmlExtNetwork = $ExternalNetworkTemplate 
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "VCServerRef",  $VCServerRef
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "ExtNetName",  $AdminExtNetName
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "Gatewayedit", $AdminGateway
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "Netmaskedit", $AdminNetmask
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "StartAddressedit", $AdminStartAddress
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "EndAddressedit", $AdminEndAddress
$AdminxmlExtNetwork = $AdminxmlExtNetwork -replace "MoRefedit" , $AdminPortGroup.Key
##################################### Call Create EXternal Network API #################
$ContentType="application/vnd.vmware.admin.vmwexternalnet+xml"
$ExtnetworkURL = $baseurl + "/admin/extension/externalnets"

Try{
	$AdminExternalNetwork = $responseExtnetworks.VMWExternalNetworkReferences.ExternalNetworkReference  | where {$_.Name -eq  $AdminExtNetName }
	if ( $AdminExternalNetwork.count -eq '0' ){
	    Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating Admin External Network :$AdminExtNetName" -ForegroundColor Green
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating External Network :$AdminGateway / $AdminNetmask" -ForegroundColor Green
		$responseExtnetwork=Invoke-RestMethod -Uri $ExtnetworkURL -Headers $headers -Method POST -body $AdminxmlExtNetwork -ContentType $ContentType
		$TaskURL=$responseExtnetwork.VMWExternalNetwork.Tasks.Task.href
        Check-vCD-Task $TaskURL
	}else {
		 Write-Host (Get-Date).ToString() "$ScriptIdentifier : Admin External Network already exist:$AdminExtNetName" -ForegroundColor Yellow
	}
	
}catch{
    Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
    if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
	Exit-function
}




####################### INET Network #########################
$InetLW_Name = $OrgName + $Customizations.InetPESG.LSWName	   
$InetPortGroup = Get-VirtualPortGroup | where{$_.Name -like "*$vDSID-*$OrgName*_INET*" }
$InetExtNetName =$OrgName + $Customizations.InetVCD.ExtNetName

########################## Edit XML file for INET External Network Creation #######################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Updating INET External Network   XML file" -ForegroundColor Green
$InetGateway = $Customizations.InetVCD.Gateway
$InetNetmask =  $Customizations.InetVCD.Netmask
$InetStartAddress = $Customizations.InetVCD.StartAddress
$InetEndAddress = $Customizations.InetVCD.EndAddress
$InetxmlExtNetwork = $ExternalNetworkTemplate
$InetxmlExtNetwork = $InetxmlExtNetwork -replace "VCServerRef",  $VCServerRef
$InetxmlExtNetwork = $InetxmlExtNetwork -replace "ExtNetName",  $InetExtNetName
$InetxmlExtNetwork = $InetxmlExtNetwork -replace "Gatewayedit", $InetGateway
$InetxmlExtNetwork = $InetxmlExtNetwork-replace "Netmaskedit", $InetNetmask
$InetxmlExtNetwork = $InetxmlExtNetwork -replace "StartAddressedit", $InetStartAddress
$InetxmlExtNetwork = $InetxmlExtNetwork -replace "EndAddressedit", $InetEndAddress
$InetxmlExtNetwork = $InetxmlExtNetwork -replace "MoRefedit" , $InetPortGroup.Key
##################################### Call Create EXternal Network API #################
Try{

    $InetExternalNetwork = $responseExtnetworks.VMWExternalNetworkReferences.ExternalNetworkReference  | where {$_.Name -eq  $InetExtNetName }
	if ( $InetExternalNetwork.count -eq '0' ){
	    Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating INET External Network :$InetExtNetName" -ForegroundColor Green
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating INET External Network :$InetGateway / $InetNetmask" -ForegroundColor Green
		$responseExtnetwork=Invoke-RestMethod -Uri $ExtnetworkURL -Headers $headers -Method POST -body $InetxmlExtNetwork -ContentType $ContentType
		$TaskURL=$responseExtnetwork.VMWExternalNetwork.Tasks.Task.href
        Check-vCD-Task $TaskURL 
	}
	else{
	
	     Write-Host (Get-Date).ToString() "$ScriptIdentifier : Inet External Network already exist:$InetExtNetName" -ForegroundColor Yellow
	}
}catch{
    Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
    if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
	Exit-function
}
     
  
$ScriptIdentifier='[VCD][Org]'	  
###Create Org #####

###Get ORG List
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get Org List"
$OrgListURL= $baseurl + "/org"
$responseOrgList=Invoke-RestMethod -Uri $OrgListURL -Headers $headers -Method GET -WebSession $MYSESSION
$OrgList=$responseOrgList.OrgList.Org
$OrgURL = ($OrgList |where-object { $_.name -eq $OrgName}).href 

	##if Org exist
if ($OrgURL.count -eq '1'){
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Org already exist :$OrgName" -ForegroundColor Yellow
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get existing one :$OrgName" -ForegroundColor Yellow
	If($TerminateIfOrgExist){ Exit-function }
	$OrgID= getIDfromUrl $OrgURL
	$OrgAdminURL = $baseurl + '/admin/org/' + $OrgID
	$responseOrg=Invoke-RestMethod -Uri $OrgAdminURL -Headers $headers -Method GET -WebSession $MYSESSION
}else{
	$XMLLocation = $WorkingDirectory+'Templates\OrgTemplate.xml'
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
	$xmltemplateOrg = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)
	$OrgXml = $xmltemplateOrg
	$OrgXml = $OrgXml -replace "Org_Name", $OrgName
	$OrgXml = $OrgXml -replace "Org_Description", $Customer.customer.Description
	$OrgXml = $OrgXml -replace "Org_FullName", $OrgFullName
	$OrgXml = $OrgXml -replace "Can_Subscribe", "true"
	$NewOrgURL = $baseurl + "/admin/orgs"
	$ContentType="application/vnd.vmware.admin.organization+xml"
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating Org :$OrgName" -ForegroundColor Green
	Try{
		$responseOrg = Invoke-RestMethod -Uri $NewOrgURL -Headers $headers -Method POST -body $OrgXml -ContentType $ContentType
		$OrgAdminURL = $responseOrg.AdminOrg.href
	}catch{
		Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
		if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
		Exit-function
	}
}

<####Create User###
$UsersList= $Customer.customer.Users.User
$CreateUsersURL = $OrgAdminURL +'/users'
$ContentType="application/vnd.vmware.admin.user+xml"
foreach ( $User in $UsersList){
	if ( $User.UserType -eq 'Local'){
	
		$XMLLocation = $WorkingDirectory+'Templates\UserTemplate.xml'
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
		$UserXML = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)
	
		$xmlUser = $UserXML
		$xmlUser = $xmlUser -replace "User_Name", $User.Name
		$xmlUser = $xmlUser -replace "User_FullName", $User.FullName
		$xmlUser = $xmlUser -replace "User_Email", $User.EmailAddress
		$xmlUser = $xmlUser -replace "User_Telephone", $User.Telephone
		$xmlUser = $xmlUser -replace "VCDUser_Role", $Customizations.VCD.VCDUserRole
		$xmlUser = $xmlUser -replace "User_Password", $User.Password
			
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating New User :$User.Name" -ForegroundColor Green
		Try{
			$responseUser = Invoke-RestMethod -Uri $CreateUsersURL -Headers $headers -Method POST -body $xmlUser -ContentType $ContentType	
		}catch{
			Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
			if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
			#Exit-function
		}
	}
}
#>

$responseExtnetworks=Invoke-RestMethod -Uri $ExtnetworksURL -Headers $headers -Method GET
$AdminExternalNetwork = $responseExtnetworks.VMWExternalNetworkReferences.ExternalNetworkReference  | where {$_.Name -eq  $AdminExtNetName }
$AdminExternalNetworkHref = $AdminExternalNetwork.href
$InetExternalNetwork = $responseExtnetworks.VMWExternalNetworkReferences.ExternalNetworkReference  | where {$_.Name -eq  $InetExtNetName }
$InetExternalNetworkHref = $InetExternalNetwork.href

$ScriptIdentifier='[VCD][OrgVDC]'
#Existing OrgVDCs
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get Existing OrgVDC List"
$ExistOrgVDCList=$responseOrg.Org.Link | where {$_.href -like "*/vdc/*"}
	
###Create OrgVDC
$OrgVDCsList= $Customer.customer.OrgVDCs.OrgVDC
Foreach ( $OrgVDC in $OrgVDCsList  ){
	$OrgVDCName=$OrgVDC.Name
	$OrgVDCURL = ($ExistOrgVDCList |where-object { $_.name -eq $OrgVDCName}).href 
	
	##if OrgVDC exist
	if ($OrgVDCURL.count -eq '1'){
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : OrgVDC already exist :$OrgVDCName" -ForegroundColor Yellow
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get existing one :$OrgVDCName" -ForegroundColor Yellow
		If($TerminateIfOrgVDCExist){ Exit-function }
		$OrgVDCAdminURL = $OrgVDCURL
		$responseOrgVDC=Invoke-RestMethod -Uri $OrgVDCAdminURL -Headers $headers -Method GET -WebSession $MYSESSION
	}else{
		$XMLLocation = $WorkingDirectory+'Templates\OrgVDCTemplate.xml'
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
		$xmltemplateOrg = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)
		
		$PVDCName = $OrgVDC.ProviderVDC
		$StorageProfile = $OrgVDC.StorageProfile.name
		
		$GETPVDCINFO	= Get-PVDCINFO $headers $baseurl $PVDCName $StorageProfile
		
		
		$OrgVDCCPUGuaranteed = [int]$OrgVDC.cpu.Guaranteed / 100
		$OrgVDCMemoryGuaranteed = [int]$OrgVDC.Memory.Guaranteed /100
		$OrgVDCcpuLimit = [int]$OrgVDC.cpu.Limit * 1000
		$OrgVDCMemoryLimit = [int]$OrgVDC.Memory.Limit * 1024
		$OrgVDCcpuSpeed = [int]$OrgVDC.cpu.Speed * 1000
		
		$xmlVDC = $xmltemplateOrg
		$xmlVDC = $xmlVDC -replace "OrgvDC_Name", $OrgVDCName
		$xmlVDC = $xmlVDC -replace "Org_VDC_Description", $OrgVDC.Description
		$xmlVDC = $xmlVDC -replace "OrgvDC_AllocationVApp", $OrgVDC.AllocationModel
		$xmlVDC = $xmlVDC -replace "OrgvDC_Cpu_Allocated", $OrgVDCcpuLimit
		$xmlVDC = $xmlVDC -replace "OrgvDC_Cpu_Limit", $OrgVDCcpuLimit
		$xmlVDC = $xmlVDC -replace "OrgvDC_Memory_Allocated", $OrgVDCMemoryLimit
		$xmlVDC = $xmlVDC -replace "OrgvDC_Memory_Limit", $OrgVDCMemoryLimit
		$xmlVDC = $xmlVDC -replace "OrgvDC_Storage_Limit", $OrgVDC.StorageProfile.Limit
		$xmlVDC = $xmlVDC -replace "StorageProfile_URL", $StorageProfileURL
		$xmlVDC = $xmlVDC -replace "OrgVDCMemory_Guaranteed", $OrgVDCMemoryGuaranteed
		$xmlVDC = $xmlVDC -replace "OrgVDCPU_Guaranteed", $OrgVDCCPUGuaranteed
		$xmlVDC = $xmlVDC -replace "OrgvDC_CPU_Speed", $OrgVDCcpuSpeed
		$xmlVDC = $xmlVDC -replace "NetworkPool_URL", $NetworkPoolURL
		$xmlVDC = $xmlVDC -replace "PVDC_Name", $PVDCName 
		$xmlVDC = $xmlVDC -replace "PVDC_URL",   $PVDCURL
		
		$NewOrgVDCURL = $OrgAdminURL + "/vdcsparams"
		$ContentType="application/vnd.vmware.admin.createVdcParams+xml"
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating OrgVDC :$OrgVDCName" -ForegroundColor Green
		Try{
			$responseOrgVDC = Invoke-RestMethod -Uri $NewOrgVDCURL -Headers $headers -Method POST -body $xmlVDC -ContentType $ContentType
			$TaskURL=$responseOrgVDC.AdminVDC.Tasks.Task.href
			$OrgVDC_ID =   $responseOrgVDC.AdminVdc.href
		    $separator = "/"
		    $option = [System.StringSplitOptions]::RemoveEmptyEntries
		    [array] $OrgvDCurn = $OrgVDC_ID.Split($separator,$option)
		    $OrgVDCID = $OrgvDCurn[5]
			#$OrgVDCID
			
			$TaskStatus = Check-vCD-Task $TaskURL
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Task Status:$TaskStatus " -ForegroundColor Yellow
			if ( $TaskStatus -eq "true" ){
			
			$ScriptIdentifier='[VCD][vEdge]'
			###Create Edges
			$EdgesList= $OrgVDC.Edges.Edge
				Foreach ( $Edge in $EdgesList  ){
					$VSE_Name = $Edge.name
					$XMLLocation = $XMLLocation = $WorkingDirectory+'Templates\OrgVDCEdgeTemplate.xml'
					Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
					$xmltemplateEdge = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)
					Try{
							
							$responseExtnetworkInfo=Invoke-RestMethod -Uri $InetExternalNetworkHref -Headers $headers -Method GET
							$VSE_Gateway = $responseExtnetworkInfo.VMWExternalNetwork.Configuration.IpScopes.IpScope.Gateway
							$VSE_Netmask  = $responseExtnetworkInfo.VMWExternalNetwork.Configuration.IpScopes.IpScope.Netmask
							$separator = "/"
							$option = [System.StringSplitOptions]::RemoveEmptyEntries
							[array] $extneturn = $InetExternalNetworkHref.Split($separator,$option)
							$extnetid = $extneturn[6]
							
							$xmlVSE = $xmltemplateEdge
							$xmlVSE = $xmlVSE -replace "VSE_Name", $VSE_Name
							$xmlVSE = $xmlVSE -replace "VSE_Description", $VSE_Name
							$xmlVSE = $xmlVSE -replace "VSE_Gateway", $VSE_Gateway
							$xmlVSE = $xmlVSE -replace "VSE_Netmask", $VSE_Netmask
							$xmlVSE = $xmlVSE -replace "ExternalNetwork_UUID", $extnetid
							############################################################################
							$method="POST"
							#################################### Content Type #########################
							$contenttype="application/vnd.vmware.admin.edgeGateway+xml"
				
							$EdgeURL = $baseurl +"/admin/vdc/$OrgVDCID/edgeGateways"
							##################################### Call Create VSE API #################
							$responseEdge = Invoke-RestMethod -Uri $EdgeURL  -Headers $headers -Method POST -body $xmlVSE -ContentType $ContentType
							$TaskURL= $responseEdge.EdgeGateway.Tasks.Task.href
							$TaskStatus = Check-vCD-Task $TaskURL
							
							
							
		
					}catch{
							Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
							if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
							Exit-function
					}
				}
				
				$ScriptIdentifier='[VCD][OrgNetwork]'
				################## Create Org Network ####################################################			
				$responseExtnetworkInfo=Invoke-RestMethod -Uri $AdminExternalNetworkHref -Headers $headers -Method GET
				$AdminOrgNetwork_Gateway = $responseExtnetworkInfo.VMWExternalNetwork.Configuration.IpScopes.IpScope.Gateway
				$AdminOrgNetwork_Netmask  = $responseExtnetworkInfo.VMWExternalNetwork.Configuration.IpScopes.IpScope.Netmask
				$AdminOrgNetwork_StartAddress =  $responseExtnetworkInfo.VMWExternalNetwork.Configuration.IpScopes.IpScope.IpRanges.IpRange.StartAddress
				$AdminOrgNetwork_EndAddress =  $responseExtnetworkInfo.VMWExternalNetwork.Configuration.IpScopes.IpScope.IpRanges.IpRange.EndAddress
				$separator = "/"
				$option = [System.StringSplitOptions]::RemoveEmptyEntries
				[array] $extneturn = $AdminExternalNetworkHref.Split($separator,$option)
				$Adminextnetid = $extneturn[6]
				
				
				$XMLLocation = $XMLLocation = $WorkingDirectory+'Templates\OrgVdcNetwork.xml'
				Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import XML file $XMLLocation" -ForegroundColor Green
				$xmltemplateOrgNetwork = (Get-Content $XMLLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue)
				$OrgNetworksList= $OrgVDC.OrgNetworks.OrgNetwork
				Foreach ( $OrgNetwork in $OrgNetworksList  ){
					$OrgNetwork_Name = $OrgNetwork.name
					
					$xmlOrgNet = $xmltemplateOrgNetwork
					$xmlOrgNet = $xmlOrgNet -replace "OrgNet_Name", $OrgNetwork_Name
					$xmlOrgNet = $xmlOrgNet -replace "OrgNet_Description", $OrgNetwork_Name
					$xmlOrgNet = $xmlOrgNet -replace "OrgNet_Gateway", $AdminOrgNetwork_Gateway
					$xmlOrgNet = $xmlOrgNet -replace "OrgNet_Netmask", $AdminOrgNetwork_Netmask
					$xmlOrgNet = $xmlOrgNet -replace "OrgNet_StartAddress", $AdminOrgNetwork_StartAddress
					$xmlOrgNet = $xmlOrgNet -replace "OrgNet_EndAddress", $AdminOrgNetwork_EndAddress
					$xmlOrgNet = $xmlOrgNet -replace "ExternalNetworkID", $Adminextnetid
					$ContentType = "application/vnd.vmware.vcloud.orgVdcNetwork+xml"
					$CreateOrgNetURL = $baseurl +"/admin/vdc/$OrgVDCID/networks"
					Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating 	Org Network :$OrgNetwork_Name " -ForegroundColor Green
					Try{
						$responseOrgNetwork = Invoke-RestMethod -Uri $CreateOrgNetURL -Headers $headers -Method POST -body $xmlOrgNet -ContentType $ContentType	
					}catch{
						Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
						if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
						#Exit-function
					}
				}
				
				
			}
			
		}catch{
			Write-Warning ("Invoke-vCloud Exception: $($_.Exception.Message)")
			if ( $_.Exception.ItemName ) { Write-Warning ("Failed Item: $($_.Exception.ItemName)") }
			#Exit-function
		}
	}

}
	###Get ORGVDC List

	
	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	