#Requires -Version 3
#Requires -Modules VMware.VimAutomation.Cloud, @{ModuleName="VMware.VimAutomation.Cloud";ModuleVersion="6.3.0.0"}
##################################################################################################################
# Version = 2018.09.02
#
# Created by : Marwan Hammad
#
# This script generate HTML report about customer PESG configuration
#
##################################################################################################################


##------------------------------##
##			Read-Input			##
##------------------------------##

do{
	$vCenter=read-host "Enter vCenter name(VCAN/EPP)"
	switch ($vCenter) {
		VCAN {
			$nsxManagerFQDN = "10.19.249.20"
			$NSXusername="admin"
			$NSXpassword='7$3HxEZ+4G'
			$valid=$true
		}
		EPP {
			$nsxManagerFQDN = "10.19.249.21"
			$NSXusername="admin"
			$NSXpassword='7$3HxEZ+4G'
			$valid=$true
		}
		default {
		Write-Host -ForeGroundColor Red "Invalid vCenter name $($INPUT.Cust.vCenter) "
		"Invalid vCenter name Accepted values are VCAN/EPP" 
		$valid=$false
		}
	}
}until($valid)

do{
	$CustName=read-host "Enter Cust name(ex. FCA_VDR_Cust)"
	if (!($CustName)){
		write-host -ForeGroundColor Red "empty CustName"
		$valid=$false
	}else{
		$valid=$true
	}
}until($valid)

if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()



#############Report-Parameters####################
$ImagePath = ".\a.png"
$ReportFile=$($CustName)+'.html'
$Logfile=".\log.txt"

######Functions#######
Function  ADDPESG{
$Edge=$Script:Edge
$PESG=$Script:PESG
$data = [ordered]@{
ID                 =$PESG      
ClusterName		   =($Edge.edge.appliances.appliance | where {($_.highAvailabilityIndex -match "0")}).resourcePoolName
DatastoreName 	   =($Edge.edge.appliances.appliance | where {($_.highAvailabilityIndex -match "0")}).datastoreName  
FolderName		   =($Edge.edge.appliances.appliance | where {($_.highAvailabilityIndex -match "0")}).vmFolderName 
Tenant			   =$Edge.edge.tenant
Nic0     		   ="vNic_0"  
Name0       	   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_0")}).name     
NetType0 	   	   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_0")}).type
PortgroupName0     =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_0")}).portgroupName 
NicIP0			   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_0")}).addressGroups.addressGroup.primaryAddress -join ','
NicSubnet0		   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_0")}).addressGroups.addressGroup.subnetPrefixLength -join ','
Nic1     		   ="vNic_1"         
Name1       	   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_1")}).name     
NetType1		   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_1")}).type
PortgroupName1     =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_1")}).portgroupName
NicIP1			   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_1")}).addressGroups.addressGroup.primaryAddress -join ','
NicSubnet1		   =($Edge.edge.vnics.vnic | where {($_.label -match "vNic_1")}).addressGroups.addressGroup.subnetPrefixLength   -join ','
RouterId		   =$Edge.edge.features.routing.routingGlobalConfig.routerId
OSPF			   =$Edge.edge.features.routing.ospf.enabled
Ospfvnic		   =$Edge.edge.features.routing.ospf.ospfInterfaces.ospfInterface.vnic
AreaId			   =$Edge.edge.features.routing.ospf.ospfInterfaces.ospfInterface.areaId
helloInterval	   =$Edge.edge.features.routing.ospf.ospfInterfaces.ospfInterface.helloInterval	
deadInterval	   =$Edge.edge.features.routing.ospf.ospfInterfaces.ospfInterface.deadInterval	
priority		   =$Edge.edge.features.routing.ospf.ospfInterfaces.ospfInterface.priority		
BGP				   =$Edge.edge.features.routing.bgp.enabled
BGPlocalAS		   =$Edge.edge.features.routing.bgp.localAS
BGPipAddress	   =$Edge.edge.features.routing.bgp.bgpNeighbours.bgpNeighbour.ipAddress      -join ','
BGPremoteAS		   =$Edge.edge.features.routing.bgp.bgpNeighbours.bgpNeighbour.remoteAS       -join ','
BGPweight		   =$Edge.edge.features.routing.bgp.bgpNeighbours.bgpNeighbour.weight         -join ','
BGPholdDownTimer   =$Edge.edge.features.routing.bgp.bgpNeighbours.bgpNeighbour.holdDownTimer  -join ','
BGPkeepAliveTimer  =$Edge.edge.features.routing.bgp.bgpNeighbours.bgpNeighbour.keepAliveTimer -join ','

}
New-Object -TypeName PSObject -Property $data
}

Function  ADDINPUTS{
$INPUT=$Script:INPUT
$data = [ordered]@{
	vCenter  =$INPUT.Cust.vCenter
	FullName =$INPUT.Cust.FullName
	OrgVdc   =$INPUT.Cust.OrgVdc
	ADMIN    =$INPUT.Enabled.ADMIN
	INET     =$INPUT.Enabled.INET
	IPVPN    =$INPUT.Enabled.IPVPN
	INETIP   =$INPUT.IP.INET
	ADMINIP  =$INPUT.IP.ADMIN
	CSSAGWIP =$INPUT.IP.CSSAGW
	Subnet   =$INPUT.IP.Subnet
}
New-Object -TypeName PSObject -Property $data
}

###API-Parameters###
#[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#Convert username and password to basic auth
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($NSXusername + ":" + $NSXpassword))

##########GetFull-Edge-list#########33
#$XMLFile=".\VCANXML.XML"
#[xml]$FullPESGlist = Get-Content -Path $XMLFile -ErrorAction Stop

	$edgesURL="https://$nsxManagerFQDN/api/4.0/edges?pageSize=1024"
	write-host "$edgesURL"
	"edgesURL: $edgesURL" | out-file -filepath $Logfile -append -width 200

	[xml]$FullPESGlist=Invoke-RestMethod -Uri $edgesURL -Method GET -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}

########filter cust edge#######
$CustPESGlist=($FullPESGlist.pagedEdgeList.edgePage.edgeSummary | where {($_.name -match "^$CustName")}).objectId
write-host -ForeGroundColor Green $CustPESGlist


###########HTML Report#############
$fragments = @()
#add graphic file in the document.
$ImageBits =  [Convert]::ToBase64String((Get-Content $ImagePath -Encoding Byte))
$ImageFile = Get-Item $ImagePath
$ImageType = $ImageFile.Extension.Substring(1) #strip off the leading .
$ImageTag = "<Img src='data:image/$ImageType;base64,$($ImageBits)' Alt='$($ImageFile.Name)' style='float:left' width='120' height='120' hspace=10>"
$fragments+= $ImageTag

$fragments+= "<br><br>"
## Header
$fragments+= "<H1>$($CustName)</H1>"
$fragments+= "<H2>$(get-date)</H2>"

#$fragments+= "<H2>INPUTS</H2>"
#$fragments+= ADDINPUTS  | ConvertTo-Html -Fragment -As List

####list Cust edge on Report####
$fragments+= "<H2>PESG LIST</H2>"
ForEach ($PESG in $CustPESGlist){
$PESGConfig=$FullPESGlist.pagedEdgeList.edgePage.edgeSummary | where {($_.objectId -eq "$PESG")}
$PESGname=$PESGConfig.name
$fragments+= "<H3>	--	$PESGname</H3>"
}

####ADD edge Setting to Report####
ForEach ($PESG in $CustPESGlist){
$PESGConfig=$FullPESGlist.pagedEdgeList.edgePage.edgeSummary | where {($_.objectId -eq "$PESG")}
$PESGname=$PESGConfig.name
$fragments+= "<H2>$PESGname</H2>"
If($PESG -ne ''){
	$edgeURL="https://$nsxManagerFQDN/api/4.0/edges/$($PESG)"
    write-host "$edgeURL"
	"edgeURL: $edgeURL" | out-file -filepath $Logfile -append -width 200
	[xml]$Edge=Invoke-RestMethod -Uri $edgeURL -Method GET -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}
	$NatTable=$Edge.edge.features.nat.natrules.natRule | select action , vnic ,originalAddress , translatedAddress, enabled 

}
$fragments+= ADDPESG  | ConvertTo-Html -Fragment -As List
if ($NatTable){
$fragments+= " NatTable "
$fragments+= $NatTable  | ConvertTo-Html -Fragment 
}
}

$fragments+= "<p class='footer'>$(get-date)</p>"

$convertParams = @{ 
  head = @"
 <Title>$($INPUT.Cust.FullName)</Title>
<style>
body { background-color:#E5E4E2;
       font-family:Monospace;
       font-size:10pt; }
td, th { border:0px solid black; 
         border-collapse:collapse;
         white-space:pre; }
th { color:white;
     background-color:black; }
table, tr, td, th { padding: 2px; margin: 0px ;white-space:pre; }
tr:nth-child(odd) {background-color: lightgray}
table { width:95%;margin-left:5px; margin-bottom:20px;}
h1 {
 font-family:Tahoma;
 color:#6D7B7D;
}
h2 {
 font-family:Tahoma;
 color:#6D7B7D;
}
h3 {
 font-family:Tahoma;
 color:#6D7B8D;
 font-size:8pt;
}
.alert {
 color: red; 
 }
.footer 
{ color:green; 
  margin-left:10px; 
  font-family:Tahoma;
  font-size:8pt;
  font-style:italic;
}
</style>
"@
 body = $fragments
}

convertto-html @convertParams | out-file $ReportFile


<#
($edgetest | Get-NsxEdgeInterface -index 0).portgroupName
$EdgeGet=Invoke-RestMethod -Uri $RoutingURL -Method GET -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}
#>