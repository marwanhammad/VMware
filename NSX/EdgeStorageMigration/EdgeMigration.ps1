<#	
	.NOTES
	===========================================================================
	 Created on:   	2020-02-10
	 Created by:   	Marwan Hammad
	 Filename:		EdgeMigration.ps1
	---------------------------------------------------------------------------
	v1.0.0	---	Initial Creation								---	2020-02-10
	===========================================================================
	.DESCRIPTION
		 ============================================================================
		 	Storage Migration for PESG Appliances & update NSX with the new location
		 ============================================================================
#>

##################################################################################################################
#--------------------------------------------------------------------------
#---   Parameters   			                                        ---
#--------------------------------------------------------------------------

$vCenterFQDN = ""
$vCenterUser = ""
$vCenterPass=''
$nsxManagerFQDN = ""
$NSXusername="admin"
$NSXpassword=''
$SourceDatastore=''
$DestinationDatastore=''


################# Save LOGs in current LOCATION ################
#Log file name
$logfile="_ESGMigration.log"
$ScriptIdentifier='[ESGMigration]'
#Folder that contains the script and export
$Location=Get-Location
$WorkingDirectory=$Location.Path+"\"  #with the \ at the end

#Log with Date YYMMDD_hhmmss
$logFolder = $WorkingDirectory+'Logs\'
if(!(test-path $logFolder)){
	Write-Host (Get-Date).ToString() "= creating LOGS directory"
	$flog=New-Item -ItemType directory -force -Path $logFolder
}else{
	Write-Host (Get-Date).ToString() "= LOGS directory already exist"
}
$logdate = get-date -Format "yyyyMMdd.hhmmss"
$log=$logdate+$logfile
###Start Loging 
$startLogging=Start-Transcript (($logFolder)+($log)) -noclobber

###NSX API-Parameters###
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
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
#Convert username and password to basic auth
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($NSXusername + ":" + $NSXpassword))
$NSXHeaders = @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}

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
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerCli connection to vCenter : $vCenterFQDN" -ForegroundColor Green
		Connect-VIServer $vCenterFQDN -User $vCenterUser -Password $vCenterPass
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : PowerCli connected to vCenter" -ForegroundColor Green
	}catch{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Issue connection to vCenter with PowerCli" -ForegroundColor Green
			Stop-Transcript
			exit 1
	}
	
#----------------------------------------------------------------------------
#---  Functions			                                   				  ---
#----------------------------------------------------------------------------
function ValidateEdgeLocation($AppliancesInfo){
$AppliancesCount=$AppliancesInfo.appliances.appliance.Count
	$ApplianceInfo =$AppliancesInfo.appliances.appliance |  Where-Object {$_.highAvailabilityIndex -eq '0'} 
	$ApplianceVMname=  $ApplianceInfo.vmName
	if(	($ApplianceInfo.resourcePoolId  -eq    $ApplianceInfo.configuredResourcePool.id) -and
		($ApplianceInfo.datastoreId 	-eq	   $ApplianceInfo.configuredDataStore.id)    -and
		#($ApplianceInfo.hostId		    -eq    $ApplianceInfo.configuredHost.id )        -and
		($ApplianceInfo.vmFolderId      -eq    $ApplianceInfo.configuredVmFolder.id )
		){
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : VM $ApplianceVMname matched NSX configuration" -ForegroundColor Green
		}else{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : VM $ApplianceVMname  doesn't match NSX configuration" -ForegroundColor Yellow
			return 0
		}

if ($AppliancesCount -eq '2'){
	$ApplianceInfo =$AppliancesInfo.appliances.appliance |  Where-Object {$_.highAvailabilityIndex -eq '1'} 
	$ApplianceVMname=  $ApplianceInfo.vmName
	if(	($ApplianceInfo.resourcePoolId  -eq    $ApplianceInfo.configuredResourcePool.id) -and
		($ApplianceInfo.datastoreId 	-eq	   $ApplianceInfo.configuredDataStore.id)    -and
		#($ApplianceInfo.hostId		    -eq    $ApplianceInfo.configuredHost.id )        -and
		($ApplianceInfo.vmFolderId      -eq    $ApplianceInfo.configuredVmFolder.id )
		){
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : VM $ApplianceVMname matched NSX configuration" -ForegroundColor Green
		}else{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : VM $ApplianceVMname doesn't match NSX configuration" -ForegroundColor Yellow
			
			return 0 
		}
		
}

Return 1

}

function MigrateAppliance ($EdgeName,$AppliancesURL,$Index){
	$EdgeVMName = $EdgeName + "-" + $Index
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Migrate VM : $EdgeVMName" -ForegroundColor Yellow
	try{
		$MoveEdgeVM = Get-VM $EdgeVMName | Move-VM -Datastore $DestinationDatastore
		$UpdateNSX= '1'
	}catch{
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Issue Migrate VM : $EdgeVMName " -ForegroundColor Red 
		$UpdateNSX= '0'
	}
	
	#Get Appliance Info
	$ApplianceURL = $AppliancesURL + "/" + $Index
	$Appliance=Invoke-RestMethod -Uri $ApplianceURL -Method Get -Headers $NSXHeaders		
	
	#Update configuredDataStore ID  $AppliancesInfo.appliances.appliance.configuredDataStore.id
	$Appliance.selectNodes('//appliance/configuredDataStore/id[text()]')|%{$_.'#text' = ($_.'#text' -replace $SourceDatastoreID,$Appliance.appliance.datastoreId)}
	$Appliance.selectNodes('//appliance/configuredDataStore/name[text()]')|%{$_.'#text' = ($_.'#text' -replace $SourceDatastore,$Appliance.appliance.datastoreName)}
	if ( ($Appliance.appliance.configuredDataStore.name -eq $DestinationDatastore) -and ($Appliance.appliance.configuredDataStore.id -eq $DestinationDatastoreID) -and ($UpdateNSX -eq '1') ){
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Update Appliance $Index " -ForegroundColor Yellow
		$Update=Invoke-RestMethod -Uri $ApplianceURL -Method PUT -Body $Appliance -Headers $NSXHeaders	
	}else{
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Skip NSX Update For Appliance $EdgeVMName " -ForegroundColor Red
	}
}


#----------------------------------------------------------------------------
#---  Main          	                                   				  ---
#----------------------------------------------------------------------------

#Get datastors ID
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get Datastores ID" -ForegroundColor Green
$SourceDatastoreID= (Get-datastore $SourceDatastore).ExtensionData.MoRef.Value
$DestinationDatastoreID= (Get-datastore $DestinationDatastore).ExtensionData.MoRef.Value
if (!($SourceDatastoreID)){
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Can't find datastore: $SourceDatastore " -ForegroundColor Red
	Stop-Transcript
	exit 1
}
if (!($DestinationDatastoreID)){
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Can't find datastore: $DestinationDatastore " -ForegroundColor Red
	Stop-Transcript
	exit 1
}

#Get All Edges located in Source Datastore
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get Edges info" -ForegroundColor Green
$EdgesURL= "https://" + $nsxManagerFQDN + "/api/4.0/edges/?pageSize=1024"
$EdgesInfo=Invoke-RestMethod -Uri $EdgesURL -Method Get -Headers $NSXHeaders
$EdgesList= $EdgesInfo.pagedEdgeList.edgePage.edgeSummary 
$TotalCount=$EdgesInfo.pagedEdgeList.edgePage.pagingInfo.totalCount -as[int]
if ($TotalCount -gt '1024'){
	$EdgesURL= "https://" + $nsxManagerFQDN + "/api/4.0/edges/?pageSize=1024&startIndex=1024"
	$EdgesInfoPage2=Invoke-RestMethod -Uri $EdgesURL -Method Get -Headers $NSXHeaders
	$EdgesList+= $EdgesInfoPage2.pagedEdgeList.edgePage.edgeSummary
}

Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get Edges info location in SourceDatastore: $SourceDatastore" -ForegroundColor Green
$EdgesList= $EdgesList | Where-Object {$_.appliancesSummary.dataStoreMoidOfActiveVse -eq $SourceDatastoreID}
$EdgesList= $EdgesList| where-object {$_.edgetype -eq 'gatewayServices'}

$EdgesListCount= $EdgesList.objectId.count

if ($EdgesListCount -eq '0'){
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Datastore  $SourceDatastore doen't have any edge to migrate" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Exit script nothing to do" -ForegroundColor Green
	Stop-Transcript
	exit 1
}

Write-Host (Get-Date).ToString() "$ScriptIdentifier : datastore $SourceDatastore has $EdgesListCount Edges to migrate" -ForegroundColor Green


#Migrate Edge
Foreach ($Edge in $EdgesList){
$EdgeName = $Edge.name
$EdgeID = $Edge.ObjectID

$AppliancesURL= "https://" + $nsxManagerFQDN + "/api/4.0/edges/" +  $EdgeID +"/appliances"
$AppliancesInfo=Invoke-RestMethod -Uri $AppliancesURL -Method Get -Headers $NSXHeaders

if ($AppliancesInfo){
	$valid = ValidateEdgeLocation $AppliancesInfo
	
		if ($valid -eq '0'){
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Skip Migration for Edge: $EdgeName " -ForegroundColor Yellow
		}elseif($valid -eq '1'){
						
			#Migrate First VM
			MigrateAppliance $EdgeName $AppliancesURL '0'
			
			#Migrate second VM if exist
			$AppliancesCount=$AppliancesInfo.appliances.appliance.Count
			if ($AppliancesCount -eq '2'){
			
				MigrateAppliance $EdgeName $AppliancesURL '1'
			
			}
			
			
		}
}else{
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Can't get Edge info: $EdgeName " -ForegroundColor Yellow
}

}

Stop-Transcript