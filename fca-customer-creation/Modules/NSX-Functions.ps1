##Create Routing XML file
function Routing($routerId,$BGPlocalAS,$BGPremoteAS,$BGPNeighbour1,$BGPNeighbour2,$OSPFenabled,$IntercoVXLAN){
[System.Xml.XmlDocument]$retXML=New-Object System.Xml.XmlDocument
    $Null = @(
        $routingXML=$retXML.CreateElement("routing")
		#<routing>
			<#version>6</version>
			<enabled>true</enabled#>
			#($routingXML.AppendChild($retXML.CreateElement("version"))).AppendChild(($retXML.CreateTextNode("6")))
			($routingXML.AppendChild($retXML.CreateElement("enabled"))).AppendChild(($retXML.CreateTextNode("true")))
			<#routingGlobalConfig>
				<routerId>100.64.3.12</routerId>
				<ecmp>false</ecmp>
				<logging>
					<enable>false</enable>
					<logLevel>info</logLevel>
				</logging>
				<ipPrefixes>
					<ipPrefix>
						<name>Interco VXLAN</name>
						<ipAddress>100.64.100.0/24</ipAddress>
					</ipPrefix>
				</ipPrefixes>
			</routingGlobalConfig#>
			$GlobalConfig=$retXML.CreateElement("routingGlobalConfig")
			($GlobalConfig.AppendChild($retXML.CreateElement("routerId"))).AppendChild(($retXML.CreateTextNode("$routerId")))
			($GlobalConfig.AppendChild($retXML.CreateElement("ecmp"))).AppendChild(($retXML.CreateTextNode('false')))
			$log=$retXML.CreateElement("logging")
			($log.AppendChild($retXML.CreateElement("enable"))).AppendChild(($retXML.CreateTextNode("false")))
			($log.AppendChild($retXML.CreateElement("logLevel"))).AppendChild(($retXML.CreateTextNode("info")))
			$GlobalConfig.AppendChild($log)
						
		If($OSPFenabled -eq 'true'){	
			$ipPrefixesXML=$retXML.CreateElement("ipPrefixes")
			$ipPrefixXML=$retXML.CreateElement("ipPrefix")
			($ipPrefixXML.AppendChild($retXML.CreateElement("name"))).AppendChild(($retXML.CreateTextNode('Interco VXLAN')))
			($ipPrefixXML.AppendChild($retXML.CreateElement("ipAddress"))).AppendChild(($retXML.CreateTextNode("$IntercoVXLAN")))
			$ipPrefixesXML.AppendChild($ipPrefixXML)
			$GlobalConfig.AppendChild($ipPrefixesXML)
		}	
							
			$routingXML.AppendChild($GlobalConfig)
			<#staticRouting>
				<staticRoutes/>
			</staticRouting#>
			
			$staticXML=$retXML.CreateElement("staticRouting")
			$RoutesXML=$retXML.CreateElement("staticRoutes")
			$staticXML.AppendChild($RoutesXML)
			$routingXML.AppendChild($staticXML)
			
			#<ospf>
			$ospfXML=$retXML.CreateElement("ospf")
				#<enabled>true</enabled>
			($ospfXML.AppendChild($retXML.CreateElement("enabled"))).AppendChild(($retXML.CreateTextNode("$OSPFenabled")))

				<#ospfAreas>
					<ospfArea>
						<areaId>20</areaId>
						<type>normal</type>
						<authentication>
							<type>none</type>
						</authentication>
					</ospfArea>
				</ospfAreas#>

			$ospfAreasXML=$retXML.CreateElement("ospfAreas")
			$ospfAreaXML=$retXML.CreateElement("ospfArea")
			($ospfAreaXML.AppendChild($retXML.CreateElement("areaId"))).AppendChild(($retXML.CreateTextNode("20")))
			($ospfAreaXML.AppendChild($retXML.CreateElement("type"))).AppendChild(($retXML.CreateTextNode("normal")))
			$authenticationXML=$retXML.CreateElement("authentication")
			($authenticationXML.AppendChild($retXML.CreateElement("type"))).AppendChild(($retXML.CreateTextNode("none")))
			$ospfAreaXML.AppendChild($authenticationXML)
			$ospfAreasXML.AppendChild($ospfAreaXML)
			$ospfXML.AppendChild($ospfAreasXML)				
				
				<#ospfInterfaces>
					<ospfInterface>
						<vnic>1</vnic>
						<areaId>20</areaId>
						<helloInterval>10</helloInterval>
						<deadInterval>40</deadInterval>
						<priority>128</priority>
						<cost>1</cost>
						<mtuIgnore>false</mtuIgnore>
					</ospfInterface>
				</ospfInterfaces#>
				
			$ospfInterfacesXML=$retXML.CreateElement("ospfInterfaces")
			$ospfInterfaceXML=$retXML.CreateElement("ospfInterface")
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("vnic"))).AppendChild(($retXML.CreateTextNode("1")))
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("areaId"))).AppendChild(($retXML.CreateTextNode("20")))
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("helloInterval"))).AppendChild(($retXML.CreateTextNode("10")))
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("deadInterval"))).AppendChild(($retXML.CreateTextNode("40")))
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("priority"))).AppendChild(($retXML.CreateTextNode("128")))
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("cost"))).AppendChild(($retXML.CreateTextNode("1")))
			($ospfInterfaceXML.AppendChild($retXML.CreateElement("mtuIgnore"))).AppendChild(($retXML.CreateTextNode("false")))
			$ospfInterfacesXML.AppendChild($ospfInterfaceXML)
			$ospfXML.AppendChild($ospfInterfacesXML)	
				
				<#redistribution>
					<enabled>false</enabled>
					<rules/>
				</redistribution#>
				$OSPFredistributionXML=$retXML.CreateElement("redistribution")
				($OSPFredistributionXML.AppendChild($retXML.CreateElement("enabled"))).AppendChild(($retXML.CreateTextNode("false")))
				($OSPFredistributionXML.AppendChild($retXML.CreateElement("rules")))
				$ospfXML.AppendChild($OSPFredistributionXML)
				<#gracefulRestart>true</gracefulRestart>
				<defaultOriginate>false</defaultOriginate>	
			</ospf#>
			($ospfXML.AppendChild($retXML.CreateElement("gracefulRestart"))).AppendChild(($retXML.CreateTextNode("true")))
			($ospfXML.AppendChild($retXML.CreateElement("defaultOriginate"))).AppendChild(($retXML.CreateTextNode("false")))
			 $routingXML.AppendChild($ospfXML)
			<#bgp>
				<enabled>true</enabled>
				<localAS>65000</localAS>
				<localASNumber>65000</localASNumber>
				<bgpNeighbours#>
				
				$bgpXML=$retXML.CreateElement("bgp")
				($bgpXML.AppendChild($retXML.CreateElement("enabled"))).AppendChild(($retXML.CreateTextNode("true")))
				($bgpXML.AppendChild($retXML.CreateElement("localAS"))).AppendChild(($retXML.CreateTextNode("$BGPlocalAS")))
				($bgpXML.AppendChild($retXML.CreateElement("localASNumber"))).AppendChild(($retXML.CreateTextNode("$BGPlocalAS")))
				$bgpNeighboursXML=$retXML.CreateElement("bgpNeighbours")
				$bgpNeighbourXML=$retXML.CreateElement("bgpNeighbour")
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("ipAddress"))).AppendChild(($retXML.CreateTextNode("$BGPNeighbour1")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("remoteAS"))).AppendChild(($retXML.CreateTextNode("$BGPremoteAS")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("remoteASNumber"))).AppendChild(($retXML.CreateTextNode("$BGPremoteAS")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("weight"))).AppendChild(($retXML.CreateTextNode("60")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("holdDownTimer"))).AppendChild(($retXML.CreateTextNode("180")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("keepAliveTimer"))).AppendChild(($retXML.CreateTextNode("60")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("bgpFilters")))
				$bgpNeighboursXML.AppendChild($bgpNeighbourXML)
					<#bgpNeighbour>
						<ipAddress>100.64.3.252</ipAddress>
						<remoteAS>65068</remoteAS>
						<remoteASNumber>65068</remoteASNumber>
						<weight>60</weight>
						<holdDownTimer>180</holdDownTimer>
						<keepAliveTimer>60</keepAliveTimer>
						<bgpFilters/>
					</bgpNeighbour>
					<bgpNeighbour>
						<ipAddress>100.64.3.253</ipAddress>
						<remoteAS>65068</remoteAS>
						<remoteASNumber>65068</remoteASNumber>
						<weight>60</weight>
						<holdDownTimer>180</holdDownTimer>
						<keepAliveTimer>60</keepAliveTimer>
						<bgpFilters/>
					</bgpNeighbour>
				</bgpNeighbours#>
				If($BGPNeighbour2 -ne ''){
				$bgpNeighbourXML=$retXML.CreateElement("bgpNeighbour")
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("ipAddress"))).AppendChild(($retXML.CreateTextNode("$BGPNeighbour2")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("remoteAS"))).AppendChild(($retXML.CreateTextNode("$BGPremoteAS")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("remoteASNumber"))).AppendChild(($retXML.CreateTextNode("$BGPremoteAS")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("weight"))).AppendChild(($retXML.CreateTextNode("60")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("holdDownTimer"))).AppendChild(($retXML.CreateTextNode("180")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("keepAliveTimer"))).AppendChild(($retXML.CreateTextNode("60")))
				($bgpNeighbourXML.AppendChild($retXML.CreateElement("bgpFilters")))
				$bgpNeighboursXML.AppendChild($bgpNeighbourXML)
				}
				$bgpXML.AppendChild($bgpNeighboursXML)
				<#redistribution>
					<enabled>true</enabled>
					<rules>
						<rule>
							<id>0</id>
							<prefixName>Interco VXLAN</prefixName>
							<from>
								<ospf>true</ospf>
								<bgp>false</bgp>
								<static>false</static>
								<connected>true</connected>
							</from>
							<action>deny</action>
						</rule#>
				$redistributionXML=$retXML.CreateElement("redistribution")
				($redistributionXML.AppendChild($retXML.CreateElement("enabled"))).AppendChild(($retXML.CreateTextNode("true")))
				$rulesXML=$retXML.CreateElement("rules")
			If($OSPFenabled -eq 'true'){
				
				$ruleXML=$retXML.CreateElement("rule")
				($ruleXML.AppendChild($retXML.CreateElement("id"))).AppendChild(($retXML.CreateTextNode("0")))
				($ruleXML.AppendChild($retXML.CreateElement("prefixName"))).AppendChild(($retXML.CreateTextNode("Interco VXLAN")))
				$fromXML=$retXML.CreateElement("from")
				($fromXML.AppendChild($retXML.CreateElement("ospf"))).AppendChild(($retXML.CreateTextNode("true")))
				($fromXML.AppendChild($retXML.CreateElement("bgp"))).AppendChild(($retXML.CreateTextNode("false")))
				($fromXML.AppendChild($retXML.CreateElement("static"))).AppendChild(($retXML.CreateTextNode("false")))
				($fromXML.AppendChild($retXML.CreateElement("connected"))).AppendChild(($retXML.CreateTextNode("true")))
				$ruleXML.AppendChild($fromXML)
				($ruleXML.AppendChild($retXML.CreateElement("action"))).AppendChild(($retXML.CreateTextNode("deny")))
				$rulesXML.AppendChild($ruleXML)
			}
						<#rule>
							<id>1</id>
							<from>
								<ospf>true</ospf>
								<bgp>false</bgp>
								<static>false</static>
								<connected>false</connected>
							</from>
							<action>permit</action>
						</rule>
					</rules>
				</redistribution#>
				$ruleXML=$retXML.CreateElement("rule")
			If($OSPFenabled -eq 'true'){
				($ruleXML.AppendChild($retXML.CreateElement("id"))).AppendChild(($retXML.CreateTextNode("1")))
			}else{
				($ruleXML.AppendChild($retXML.CreateElement("id"))).AppendChild(($retXML.CreateTextNode("0")))
			}
				$fromXML=$retXML.CreateElement("from")
				($fromXML.AppendChild($retXML.CreateElement("bgp"))).AppendChild(($retXML.CreateTextNode("false")))
				($fromXML.AppendChild($retXML.CreateElement("static"))).AppendChild(($retXML.CreateTextNode("false")))
			If($OSPFenabled -eq 'true'){
				($fromXML.AppendChild($retXML.CreateElement("connected"))).AppendChild(($retXML.CreateTextNode("false")))
				($fromXML.AppendChild($retXML.CreateElement("ospf"))).AppendChild(($retXML.CreateTextNode("true")))
			}else{
				($fromXML.AppendChild($retXML.CreateElement("connected"))).AppendChild(($retXML.CreateTextNode("true")))
				($fromXML.AppendChild($retXML.CreateElement("ospf"))).AppendChild(($retXML.CreateTextNode("false")))
			}
				$ruleXML.AppendChild($fromXML)
				($ruleXML.AppendChild($retXML.CreateElement("action"))).AppendChild(($retXML.CreateTextNode("permit")))
				$rulesXML.AppendChild($ruleXML)
				<#gracefulRestart>true</gracefulRestart>
				<defaultOriginate>false</defaultOriginate>
			</bgp#>
			$redistributionXML.AppendChild($rulesXML)
			
			$bgpXML.AppendChild($redistributionXML)
			($bgpXML.AppendChild($retXML.CreateElement("gracefulRestart"))).AppendChild(($retXML.CreateTextNode("true")))
			($bgpXML.AppendChild($retXML.CreateElement("defaultOriginate"))).AppendChild(($retXML.CreateTextNode("false")))
			$routingXML.AppendChild($bgpXML)
		#</routing>
$retXML.AppendChild($routingXML)
)
return $retXML
}

function NewPESG($PESGName,$Tenant,$EdgeDatastore,$EdgeCluster,$EdgeFolder,$UplinkName,$UplinkNetwork,$UplinkIP,$InternalName,$InternalIP,$InternalSubnet,$LSWName,$NsxTransportZone,$UplinkSubnet){
#New Logical Switches
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating Logical Switche : $LSWName" -ForegroundColor Green	
	$LSW = Get-NsxTransportZone $NsxTransportZone | New-NsxLogicalSwitch -name $LSWName -ControlPlaneMode HYBRID_MODE
	#$LSW | Select-Object name,vdnId
	$Temp= $LSW | Select-Object name,vdnId
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Logical Switche ID : $Temp" -ForegroundColor Green
	
#Interfaces

	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Preparing Interface Uplink setting : $UplinkName" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Preparing Interface Uplink setting : $UplinkIP / $UplinkSubnet" -ForegroundColor Green
	$Uplink   = New-NsxEdgeInterfaceSpec -index 0 -name $UplinkName   -Type uplink   -Connected $UplinkNetwork -PrimaryAddress $UplinkIP   -SubnetPrefixLength $UplinkSubnet
	
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Preparing Interface Internal setting : $InternalName" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Preparing Interface Internal setting : $InternalIP / $InternalSubnet" -ForegroundColor Green
	$Internal = New-NsxEdgeInterfaceSpec -index 1 -name $InternalName -Type internal -Connected $LSW           -PrimaryAddress $InternalIP -SubnetPrefixLength $InternalSubnet
	

#Creating Provider Edges

	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Creating Provider Edges : $PESGName " -ForegroundColor Green
<#Check#>
	$TryNumber=0	
	do{
	$temp = $PESGName -replace '_',''
<#Check#><#-ErrorAction SilentlyContinue#>		$PESG = New-NsxEdge -name $temp -Datastore $EdgeDatastore -Cluster $EdgeCluster -Interface $Uplink,$Internal -Tenant $Tenant -Password 'P@ssw0rd12345' -EnableSSH -EnableHa -HaDeadTime 9 -VMFolder $EdgeFolder -AutoGenerateRules -FwLoggingEnabled -FwDefaultPolicyAllow  -ErrorVariable ProcessError -ErrorAction SilentlyContinue
	$TryNumber=$TryNumber+1
		If($TryNumber -gt 3){
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : PESG creation failed for 3 Times, Script Execution failed"	 -ForeGroundColor RED
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Check vCenter Error before run the script again"	 -ForeGroundColor Yellow
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Delete the created logical switch for this EDGE"	 -ForeGroundColor Yellow
			Stop-Transcript
			exit 0
		}
	IF($ProcessError){
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : PESG creation failed, waiting 2 Mins for the next retry TryNumber $TryNumber"	 -ForeGroundColor RED
			sleep 120
		}
	}while($ProcessError)
<#Check#>
	
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Renaming PESG" -ForegroundColor Green
	$PESG.name = $PESGName
	$PESG.fqdn = 'NSX-'+$PESG.id
	$PESG | Set-NsxEdge -Confirm:$false
	$Script:PESGID=$PESG.id
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : PESG ID : $PESGID" -ForegroundColor Green
	
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : -------------appliancesSummary----------------" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Tenant		 	$Tenant			" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : EdgeDatastore	 	$EdgeDatastore	 	" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : EdgeCluster	 	$EdgeCluster		" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : EdgeFolder	 	$EdgeFolder		" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : UplinkNetwork	 	$UplinkNetwork		" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : NsxTransportZone	$NsxTransportZone " -ForegroundColor Green
}


function Get-IPs { 
 
        Param( 
        [Parameter(Mandatory = $true)] 
        [array] $Subnets 
        ) 
 
foreach ($subnet in $subnets) 
    { 
         
        #Split IP and subnet 
        $IP = ($Subnet -split "\/")[0] 
        $SubnetBits = ($Subnet -split "\/")[1] 
         
        #Convert IP into binary 
        #Split IP into different octects and for each one, figure out the binary with leading zeros and add to the total 
        $Octets = $IP -split "\." 
        $IPInBinary = @() 
        foreach($Octet in $Octets) 
            { 
                #convert to binary 
                $OctetInBinary = [convert]::ToString($Octet,2) 
                 
                #get length of binary string add leading zeros to make octet 
                $OctetInBinary = ("0" * (8 - ($OctetInBinary).Length) + $OctetInBinary) 
 
                $IPInBinary = $IPInBinary + $OctetInBinary 
            } 
        $IPInBinary = $IPInBinary -join "" 
 
        #Get network ID by subtracting subnet mask 
        $HostBits = 32-$SubnetBits 
        $NetworkIDInBinary = $IPInBinary.Substring(0,$SubnetBits) 
         
        #Get host ID and get the first host ID by converting all 1s into 0s 
        $HostIDInBinary = $IPInBinary.Substring($SubnetBits,$HostBits)         
        $HostIDInBinary = $HostIDInBinary -replace "1","0" 
 
        #Work out all the host IDs in that subnet by cycling through $i from 1 up to max $HostIDInBinary (i.e. 1s stringed up to $HostBits) 
        #Work out max $HostIDInBinary 
        $imax = [convert]::ToInt32(("1" * $HostBits),2) -1 
 
        $IPs = @() 
 
        #Next ID is first network ID converted to decimal plus $i then converted to binary 
        For ($i = 1 ; $i -le $imax ; $i++) 
            { 
                #Convert to decimal and add $i 
                $NextHostIDInDecimal = ([convert]::ToInt32($HostIDInBinary,2) + $i) 
                #Convert back to binary 
                $NextHostIDInBinary = [convert]::ToString($NextHostIDInDecimal,2) 
                #Add leading zeros 
                #Number of zeros to add  
                $NoOfZerosToAdd = $HostIDInBinary.Length - $NextHostIDInBinary.Length 
                $NextHostIDInBinary = ("0" * $NoOfZerosToAdd) + $NextHostIDInBinary 
 
                #Work out next IP 
                #Add networkID to hostID 
                $NextIPInBinary = $NetworkIDInBinary + $NextHostIDInBinary 
                #Split into octets and separate by . then join 
                $IP = @() 
                For ($x = 1 ; $x -le 4 ; $x++) 
                    { 
                        #Work out start character position 
                        $StartCharNumber = ($x-1)*8 
                        #Get octet in binary 
                        $IPOctetInBinary = $NextIPInBinary.Substring($StartCharNumber,8) 
                        #Convert octet into decimal 
                        $IPOctetInDecimal = [convert]::ToInt32($IPOctetInBinary,2) 
                        #Add octet to IP  
                        $IP += $IPOctetInDecimal 
                    } 
 
                #Separate by . 
                $IP = $IP -join "." 
                $IPs += $IP 
 
                 
            } 
       return $IPs 
    } 
} 
