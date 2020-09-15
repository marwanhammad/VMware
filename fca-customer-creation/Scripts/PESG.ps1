<#	
	.NOTES
	===========================================================================
	 Created on:   	2019-09-16
	 Created by:   	Marwan Hammad, Ereen Thabet
 	 Organization: 	OCB FCA SE Team
	 Filename:
	---------------------------------------------------------------------------
	v1.0.0	---	Initial Creation								---	2018-03-19
	v1.0.1	---	Push Routing by API calls			            ---	2018-05-12
	v1.0.2  --- Bug fix / failed to power on ESG                ---	2018-05-28
	v1.0.2  --- Add log function        		                ---	2018-06-05
	v1.0.3  --- Create routing Function							---	2018-06-05
	v2.0.0	---	Change Script structure 			            ---	2019-09-16	
	v2.0.1	---	Read inputs from Customer.xml and site.ini      ---	2019-09-16
	v2.0.2	---	Add Admin PESG                                  ---	2019-09-18
	v2.0.3  --- Add INET  PESG                                  ---	2019-09-20
	v2.0.4  --- Update routing Function 						---	2019-09-20
	===========================================================================
	.DESCRIPTION
		 FCA SE External Customer Creation (Main)
		 ============================================================================
		 
		 ============================================================================
#>

#################### Params ####################
$ScriptIdentifier='[PESG]'


##Get Site info form ini
$vCenterIP = $Customizations.vCenter.vCenterIP
$vCenterUser = $Customizations.vCenter.vCenterUser
$vCenterPass=$Customizations.vCenter.vCenterPass
$nsxManagerFQDN = $Customizations.NSX.nsxManagerFQDN
$NSXusername=$Customizations.NSX.NSXusername
$NSXpassword=$Customizations.NSX.NSXpassword




################Script Body ####################
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Script version: $(Get-ScriptVersion)" -ForegroundColor Green

###Location of the powerNSX module
	$powerNSX=$WorkingDirectory+"Modules\powernsx-master\PowerNSX.psm1"	

<# Import PowerCLI module & Check VMware PowerCLI version
	$VMW_PowerCLI = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where {($_.DisplayName -Match "PowerCLI")}
# Loading VMware Module
	Write-Output "VMware PowerCLI module loading..." 
	"VMware PowerCLI module loading..."| out-file -filepath $Logfile -append -width 200
	if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)){
	  if ($VMW_PowerCLI.VersionMajor -lt "6"){
			Write-Output "VMware PowerCLI module Add-PsSnapin..." 
			add-pssnapin VMware.VimAutomation.Core
		}else{
			Write-Output "VMware PowerCLI module Import-Module..." 
			Import-Module VMware.VimAutomation.Core
		}
		}
#>
####Importing powerNSX module
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : ImportModel PowerNSX" -ForegroundColor Green
	Import-Module $powerNSX
	

###PowerCli connection to vCenter"
	try{
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerCli connection to vCenter : $vCenterIP" -ForegroundColor Green
		Connect-VIServer $vCenterIP -User $vCenterUser -Password $vCenterPass
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerCli connected to vCenter" -ForegroundColor Green
	}catch{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Issue connection to vCenter with PowerCli" -ForegroundColor Green
			Stop-Transcript
			exit 1
	}

####PowerNSX connection to the NSX manager"
	try{
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerNSX connection to the NSX manager" -ForegroundColor Green
		Connect-NsxServer -NsxServer $nsxManagerFQDN -Username $NSXusername -Password $NSXpassword -DisableVIAutoConnect
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerNSX connected to the NSX manager" -ForegroundColor Green
	}catch{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Issue connecting to the NSX manager with PowerNSX" -ForegroundColor Red
			Stop-Transcript
			exit 1
	}
###API-Parameters###

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#Convert username and password to basic auth
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($NSXusername + ":" + $NSXpassword))	


	
##Create Admin	PESG
#$Customizations 
#$Customer
		
#####PESG-Parameters####
	$PESGName = $Customer.customer.OrgName + $Customizations.AdminPESG.PESGName
	$Tenant=$Customer.customer.Tenant
	$EdgeDatastore=get-datastore $Customizations.AdminPESG.EdgeDatastore
	$EdgeCluster= get-cluster $Customizations.AdminPESG.EdgeCluster
	$EdgeFolder = Get-Folder $Customizations.AdminPESG.EdgeFolder
  ###Uplink
	$UplinkName =  $Customer.customer.OrgName + $Customizations.AdminPESG.UplinkName
	$UplinkNetwork = Get-NsxLogicalSwitch $Customizations.AdminPESG.UplinkNetwork
	$UplinkIP=$AdminUplink
	$UplinkSubnet=$Customizations.AdminPESG.UplinkSubnet
  ###Internal
	$InternalName =  $Customer.customer.OrgName + $Customizations.AdminPESG.InternalName
	$LSWName =$Customer.customer.OrgName + $Customizations.AdminPESG.LSWName
	$NsxTransportZone =$Customizations.AdminPESG.NsxTransportZone
	### Get-IPs
	$CSSASubnet=$CSSASubnet
	$IPs=Get-IPs $CSSASubnet
	$InternalIP=$IPs[-1]
	$InternalSubnet=($CSSASubnet -split "\/")[1]
	
	
	##For External Network  
		$CSSANetMask=$InternalSubnet
		$CSSAStartIP=$IPs[0]
		$CSSAEndIP=$IPs[-2]

#############Routing-Parameters####################
	$routerId=$AdminUplink
  ##BGP 
	$BGPlocalAS=$Customizations.AdminPESG.BGPlocalAS
	$BGPremoteAS=$Customizations.AdminPESG.BGPremoteAS
	$BGPNeighbour1=$Customizations.AdminPESG.BGPNeighbour1
  ##if empty,ONLY 1 BGP Neighbour will added
	$BGPNeighbour2=''
  ##true to enable OSPF, false to disable OSPF
	$OSPFenabled=$Customizations.AdminPESG.OSPFenabled
	$IntercoVXLAN=''
	
	###Call New PESG
	$edge=NewPESG $PESGName $Tenant $EdgeDatastore $EdgeCluster $EdgeFolder $UplinkName $UplinkNetwork $UplinkIP $InternalName $InternalIP $InternalSubnet $LSWName $NsxTransportZone $UplinkSubnet
	
If($PESGID -ne ''){
	$edgeURL="https://$nsxManagerFQDN/api/4.0/edges/$($PESGID)"
	$RoutingURL="$edgeURL/routing/config"
    Write-Host (Get-Date).ToString() "$ScriptIdentifier : RoutingURL : $RoutingURL" -ForegroundColor Green
	#Call Routing Function
	$retXML=Routing $routerId $BGPlocalAS $BGPremoteAS $BGPNeighbour1 $BGPNeighbour2 $OSPFenabled $IntercoVXLAN
	$RoutingPush=Invoke-RestMethod -Uri $RoutingURL -Method PUT -Body $retXML -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}
	$PESGID=''
}

######
##Create INET PESG
#####PESG-Parameters####
	$PESGName = $Customer.customer.OrgName + $Customizations.InetPESG.PESGName
	$Tenant=$Customer.customer.Tenant
	$EdgeDatastore=get-datastore $Customizations.InetPESG.EdgeDatastore
	$EdgeCluster= get-cluster $Customizations.InetPESG.EdgeCluster
	$EdgeFolder = Get-Folder $Customizations.InetPESG.EdgeFolder
  ###Uplink
	$UplinkName =  $Customer.customer.OrgName + $Customizations.InetPESG.UplinkName
	$UplinkNetwork = get-vdportgroup $Customizations.InetPESG.UplinkNetwork
	$UplinkIP=$InetUplink
	$UplinkSubnet=$Customizations.InetPESG.UplinkSubnet
  ###Internal
	$InternalName =  $Customer.customer.OrgName + $Customizations.InetPESG.InternalName
	$InternalIP=$Customizations.InetPESG.InternalIP
	$InternalSubnet=$Customizations.InetPESG.InternalSubnet
	$LSWName = $Customer.customer.OrgName + $Customizations.InetPESG.LSWName
	$NsxTransportZone = $Customizations.InetPESG.NsxTransportZone

#############Routing-Parameters####################
	$routerId=$InetUplink
  ##BGP 
	$BGPlocalAS = $Customizations.InetPESG.BGPlocalAS
	$BGPremoteAS = $Customizations.InetPESG.BGPremoteAS
	$BGPNeighbour1 = $Customizations.InetPESG.BGPNeighbour1
  ##if empty,ONLY 1 BGP Neighbour will added
	$BGPNeighbour2= $Customizations.InetPESG.BGPNeighbour2
  ##true to enable OSPF, false to disable OSPF
	$OSPFenabled= $Customizations.InetPESG.OSPFenabled
	$IntercoVXLAN= $Customizations.InetPESG.IntercoVXLAN

	
	###Call New PESG
	$edge=NewPESG $PESGName $Tenant $EdgeDatastore $EdgeCluster $EdgeFolder $UplinkName $UplinkNetwork $UplinkIP $InternalName $InternalIP $InternalSubnet $LSWName $NsxTransportZone $UplinkSubnet

If($PESGID -ne ''){
	$edgeURL="https://$nsxManagerFQDN/api/4.0/edges/$($PESGID)"
	$RoutingURL="$edgeURL/routing/config"
    Write-Host (Get-Date).ToString() "$ScriptIdentifier : RoutingURL : $RoutingURL" -ForegroundColor Green
	#Call Routing Function
	$retXML=Routing $routerId $BGPlocalAS $BGPremoteAS $BGPNeighbour1 $BGPNeighbour2 $OSPFenabled $IntercoVXLAN
	$RoutingPush=Invoke-RestMethod -Uri $RoutingURL -Method PUT -Body $retXML -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}
	$PESGID=''
}

