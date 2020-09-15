##################################################################################################################
# Version = 2019.08.30
#
# Created by :  Marwan Hammad
#
# This script Get L2VPN tunel ID from vcd edge
#
##################################################################################################################
#
##################################################################################################################

#################### Params ####################

#VCD API URL	
$vcdHost=''
#vCloud API version
$apiver = "27.0"
#UserName do not forget @OrgName
$username=''
#password
$password=''
#OrgVDCName
$OrgVDC=''
#EdgeName
$EdgeName = ''
#The name of the log file you need
$logfile="_TunnelIdInfo.log"

################# LOG & LOCATION ###########################################

#Folder that contains the script and export
$Location=Get-Location
$exportFolder=$Location.Path+"\"  #with the \ at the end

#Log with Date YYMMDD_hhmmss
$logFolder = $exportFolder+'Logs\'
if(!(test-path $logFolder)){
	Write-Host (Get-Date).ToString() "= creating LOGS directory"
	$flog=New-Item -ItemType directory -force -Path $logFolder
}else{
	Write-Host (Get-Date).ToString() "= LOGS directory already exist"
}
$logdate = get-date -Format "yyyyMMdd.hhmmss"
$log=$logdate+$logfile


############################################################
#retrieve the ORG name

$start1=Start-Transcript (($logFolder)+($log)) -noclobber


Write-Host (Get-Date).ToString() "= The API URL $vcdHost is selected" -ForegroundColor Green
Write-Host (Get-Date).ToString() "= The API Version $apiver is selected" -ForegroundColor Green


##########################Functions#############################


#This function returns the vapp xml

#################MAIN###########################################

Write-Host (Get-Date).ToString() "= Beginning of the script"
Write-Host (Get-Date).ToString() "= Script Version = 2018.12.29"

###Configure REST authentication
			add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
#Start-Transcript -Append -NoClobber -Path $exportFolder"LogVapp.log"

#Force TLS1.2 for vCD 8.20
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$servicePoint = [System.Net.ServicePointManager]::FindServicePoint("https://$vcdHost/api/1.5") 
$ServicePoint.ConnectionLimit = 100


####GET VCD TOKEN			
    #create api request auth
    $baseurl = "https://$vcdHost/api"
    $auth = $username +':' + $password
    $Encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
    $EncodedPassword = [System.Convert]::ToBase64String($Encoded)
			


    #create headers for auth
    $headers = @{ "Accept" = "application/*+xml;version=$apiver" }
    $headers += @{ "Authorization" = "Basic $($EncodedPassword)" }

    #first auth
	Write-Host (Get-Date).ToString() "= Authenticating $username against $vcdHost"
	$loginurl = "https://$vcdHost/api/sessions"
	try{
		$Webheaders = Invoke-WebRequest -Uri $loginurl -Headers $headers -Method POST 
		$headers +=@{ "x-vcloud-authorization" = $Webheaders.Headers["x-vcloud-authorization"]}
		Write-Host (Get-Date).ToString() "= User $username authenticated"
	}catch{
		$err=$_.Exception
		Write-Host (Get-Date).ToString() "= Error authenticating $username : aborting with error $err "
		#exit 1
	}
	

function getIDfromUrl($url){
    $arrayURL = [System.Uri]$url
    $ID=$arrayURL.Segments[($arrayURL.Segments.Count)-1]								
    return $ID.ToString()
}
	
###Get ORG List
Write-Host (Get-Date).ToString() "= Get Org List"
$OrgListURL= $baseurl + "/org"
$responseOrgList=Invoke-RestMethod -Uri $OrgListURL -Headers $headers -Method GET -WebSession $MYSESSION
Write-Host (Get-Date).ToString() "= Get Org INFO"
$OrgURL=($responseOrgList.OrgList.Org).href

$responseOrg=Invoke-RestMethod -Uri $OrgURL -Headers $headers -Method GET -WebSession $MYSESSION
Write-Host (Get-Date).ToString() "= Get OrgVDC INFO : $OrgVDC"
$OrgVDCURL= ($responseOrg.Org.Link | where-object {$_.href -like '*vdc*' -and $_.name -eq $OrgVDC}).href

$responseVDC=Invoke-RestMethod -Uri $OrgVDCURL -Headers $headers -Method GET -WebSession $MYSESSION
Write-Host (Get-Date).ToString() "= Get Edges List"
$EdgeListURL = ($responseVDC.Vdc.Link |Where-Object {$_.rel -eq 'nsx' } ).href
  
$responseEdges=Invoke-RestMethod -Uri $EdgeListURL -Headers $headers -Method GET -WebSession $MYSESSION
Write-Host (Get-Date).ToString() "= Get Edge INFO : $EdgeName"
$SelectedEdgeid= ($responseEdges.edgeSummaries.edgeSummary | where-object {$_.name -eq  $EdgeName}).id
$EdgeURL = 'https://'+ $vcdHost +'/network/edges/'+ $SelectedEdgeid
$responseEdge=Invoke-RestMethod -Uri $EdgeURL -Headers $headers -Method GET -WebSession $MYSESSION
Write-Host (Get-Date).ToString() "= Get tunnelIdInfo INFO"

$TrunkPort = $responseEdge.edge.vnics.vnic | where-object {$_.type -eq 'trunk'}
$tunnelIdInfo=$TrunkPort.subInterfaces.subInterface | select logicalSwitchName,tunnelId
$tunnelIdInfo
Stop-Transcript