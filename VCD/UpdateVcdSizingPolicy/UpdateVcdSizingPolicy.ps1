<#	
	.NOTES
	===========================================================================
	 Created on:   	2022-03-09
	 Created by:   	Marwan Hammad
 	 Organization: 	
	 Filename:		UpdateVcdSizingPolicy.ps1
	---------------------------------------------------------------------------
	v1.0.0	---	Initial Creation								---	2022-03-09
	===========================================================================
	.DESCRIPTION
		 ============================================================================
		 	Update vCloud VMs sizing policy
				Make sure that api version 34.0 is supported in the traget v
		 ============================================================================
	.EXAMPLES
	PS C:\> .\UpdateVcdSizingPolicy.ps1 -vcdHost '' -tenant '' -username '' -password '' -csvFile ''
#>

#--------------------------------------------------------------------------
#---  Reading arguments                                            	   ---
#--------------------------------------------------------------------------
param (
    [Parameter (Mandatory=$true)]
        # Org Username object
        [string]$username,
	[Parameter (Mandatory=$true)]
        # Org Name object
        [string]$tenant,	
    [Parameter (Mandatory=$true)]
        # Org Username password object
        [string]$password,
	[Parameter (Mandatory=$true)]
        # vCloud FQDN object
        [string]$vcdHost,
	[Parameter (Mandatory=$true)]
        # csv file name
        [string]$csvFile		
)

$username =$username +'@'+ $tenant
##vCloud API version
$apiver = "34.0"

#--------------------------------------------------------------------------
#---  Save LOGs in current Location                                	   ---
#--------------------------------------------------------------------------

#Log file name
$logfile="_UpdateVcdSizingPolicy.log"
$ScriptIdentifier='[UpdateVcdSizingPolicy]'
#Folder that contains the script and export
$Location=Get-Location
$WorkingDirectory=$Location.Path+"\"  #with the \ at the end

#Log with Date YYMMDD_hhmmss
$logFolder = $WorkingDirectory+'Logs\'
if(!(test-path $logFolder)){
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : creating LOGS directory"
	$flog=New-Item -ItemType directory -force -Path $logFolder
}else{
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : LOGS directory already exist"
}
$logdate = get-date -Format "yyyyMMdd.hhmmss"
$log=$logdate+$logfile
###Start Loging 
$startLogging=Start-Transcript (($logFolder)+($log)) -noclobber


#--------------------------------------------------------------------------
#---  Functions                                                    	   ---
#--------------------------------------------------------------------------

function Get-ScriptVersion{
	param (
		[string]$ScPath = $SCRIPT:MyInvocation.MyCommand.Path
	)
	[int]$locateversionmain = (Select-String -Path $ScPath -pattern ".DESCRIPTION" -List -CaseSensitive).linenumber
	[int]$locateversion = $locateversionmain - 3
	$Readversion = ([System.IO.File]::ReadAllLines($ScPath))[$locateversion]
	if ($Readversion -notlike "*v*.*---*")
		{
			[int]$i = 5
			do
				{
					[int]$locateversion = $locateversionmain - $i
					$Readversion = ([System.IO.File]::ReadAllLines($ScPath))[$locateversion]
					$i += 1
					if ($Readversion -like "*v*.*---*") { break }
				}
				while ($i -lt $locateversionmain)
		}
	if ($Readversion -like "*v*.*---*")
		{
			[int]$Versionindex = $Readversion.IndexOf("v")
			$Version = $Readversion.Substring($Versionindex, ($Versionindex + 5))
			Return $Version
		}
	else
		{
			$Version = 'UNKNOWN'
			Return $Version
		}
}


function getIDfromUrl($url){
    $arrayURL = [System.Uri]$url
    $ID=$arrayURL.Segments[($arrayURL.Segments.Count)-1]								
    return $ID.ToString()
}

#--------------------------------------------------------------------------
#---  MAIN                                                       	   ---
#--------------------------------------------------------------------------

Write-Host (Get-Date).ToString() "$ScriptIdentifier : Beginning of the script"
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Script version: $(Get-ScriptVersion)" -ForegroundColor Green
Write-Host (Get-Date).ToString() "$ScriptIdentifier : The API URL $vcdHost is selected" -ForegroundColor Green
Write-Host (Get-Date).ToString() "$ScriptIdentifier : The API version $apiver is selected" -ForegroundColor Green

try{
	$ImportedVMs = Import-Csv $csvFile
}catch{
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Error reading CSV file: $csvFile"
	exit 1
}
# $ImportedVMs.'VM Name'
# $ImportedVMs.'Policy Name'
try{
#Force TLS1.2 for vCD 8.20
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}catch{
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : ignore vcd certificates errors"
}


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
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Authenticating $username against $vcdHost"
$loginurl = "https://$vcdHost/api/sessions"
try{
	#$Webheaders = Invoke-WebRequest -SkipCertificateCheck -Uri $loginurl -Headers $headers -Method POST 
	$Webheaders = Invoke-WebRequest  -Uri $loginurl -Headers $headers -Method POST 
	#$headers +=@{ "x-vcloud-authorization" = $Webheaders.Headers["x-vcloud-authorization"]}
	$headers +=@{ "x-vcloud-authorization" = $($Webheaders.Headers["x-vcloud-authorization"])}
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : User $username authenticated"
}catch{
	$err=$_.Exception
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Error authenticating $username : aborting with error $err "
	exit 1
}


# query?type=orgVdc
Write-Host (Get-Date).ToString() "$ScriptIdentifier : List all OrgVDCs "
$QueryOrgVdc = $baseurl + '/query?type=orgVdc&amp;format=references&pageSize=1024'
$responseQueryOrgVdc = Invoke-RestMethod -Uri $QueryOrgVdc -Headers $headers -Method GET -WebSession $MYSESSION

# log query
$responseQueryOrgVdc_page    = $responseQueryOrgVdc.QueryResultRecords.page
$responseQueryOrgVdc_total   = $responseQueryOrgVdc.QueryResultRecords.total
$responseQueryOrgVdc_pageSize= $responseQueryOrgVdc.QueryResultRecords.pageSize
$max_pageSize = $responseQueryOrgVdc_pageSize
Write-Host (Get-Date).ToString() "$ScriptIdentifier : OrgVDC Query results page: $responseQueryOrgVdc_page total: $responseQueryOrgVdc_total pageSize: $responseQueryOrgVdc_pageSize"
Write-Host (Get-Date).ToString() "$ScriptIdentifier : max Page size is set to: $max_pageSize"

foreach ($orgVCD in $responseQueryOrgVdc.QueryResultRecords.OrgVdcRecord){
	$orgVCDName = $orgVCD.name
	$orgVCDhref = $orgVCD.href
	
	# Get OrgVCD 
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get OrgVDC: $orgVCDName "

	$responseOrgVdc = Invoke-RestMethod -Uri $orgVCDhref -Headers $headers -Method GET -WebSession $MYSESSION
	
	$orgVCD_URN = $responseOrgVdc.Vdc.id
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : URN: $orgVCD_URN "
	
	# openAPI headers
	$openAPIheaders  = @{ "Accept" = "application/*;version=$apiver" }
	$openAPIheaders += @{ "Content-Type" = "application/json;version=$apiver" }
	$openAPIheaders += @{ "x-vcloud-authorization" = $headers['x-vcloud-authorization'] }
	
	
	# /1.0.0/vdcs/{orgVdcId}/computePolicies
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get Sizing Policies "
	$computePolicieshref = "https://"+$vcdHost+"/cloudapi/1.0.0/vdcs/"+$orgVCD_URN+"/computePolicies"
	$responsecomputePolicies = Invoke-RestMethod -Uri $computePolicieshref -Headers $openAPIheaders -Method GET -WebSession $MYSESSION
	
	$SizingPolicies = $responsecomputePolicies.values | Where-Object {$_.isSizingOnly -eq 'True'}
	
	$SizingPolicies
	
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Get VMs "
	#query?type=vm&amp;format=references
	$QueryVMS = $baseurl + '/query?type=vm&amp;format=references&pageSize=' + $max_pageSize
	$responseVMs = Invoke-RestMethod -Uri $QueryVMS -Headers $headers -Method GET -WebSession $MYSESSION
	
	# log query
    $responseVMs_page    = $responseVMs.QueryResultRecords.page
    $responseVMs_total   = $responseVMs.QueryResultRecords.total
    $responseVMs_pageSize= $responseVMs.QueryResultRecords.pageSize
    Write-Host (Get-Date).ToString() "$ScriptIdentifier : VMs Query results page: $responseVMs_page total: $responseVMs_total pageSize: $responseVMs_pageSize"

	
	$VMs = $responseVMs.QueryResultRecords.VMRecord | Where-Object {$_.href -notlike "*api/vAppTemplate*" }
	
	$Pages = [int][Math]::Ceiling($responseVMs_total/$responseVMs_pageSize)
	
	if ($Pages -gt 1 ){
		$page = 1
		do {
			$page +=1
			$QueryVMS = $baseurl + '/query?type=vm&amp;format=references&pageSize='+$max_pageSize+'&&page=' + $page
			$responseVMs = Invoke-RestMethod -Uri $QueryVMS -Headers $headers -Method GET -WebSession $MYSESSION
			# log query
			$responseVMs_page    = $responseVMs.QueryResultRecords.page
			$responseVMs_total   = $responseVMs.QueryResultRecords.total
			$responseVMs_pageSize= $responseVMs.QueryResultRecords.pageSize
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : VMs Query results page: $responseVMs_page total: $responseVMs_total pageSize: $responseVMs_pageSize"
			$VMs += $responseVMs.QueryResultRecords.VMRecord | Where-Object {$_.href -notlike "*api/vAppTemplate*" }
			
		}while (!($page -eq $Pages))
	}
	
	$VMs
	
	foreach ($VM in $VMs){
		 = $VM.href
		$VMname = $VM.name
		$current_vmSizingPolicyId  = $VM.vmSizingPolicyId
		$current_vmSizingPolicyURN = "urn:vcloud:vdcComputePolicy:" + $VM.vmSizingPolicyId
		$current_vmSizingPolicyName= ($SizingPolicies | Where-Object {$_.id -eq $current_vmSizingPolicyURN}).name
		
		$target_vmSizingPolicyName = ($ImportedVMs | Where-Object {$_.'VM Name' -eq $VM.name}).'Policy Name'
		$target_vmSizingPolicy     = $SizingPolicies | Where-Object {$_.Name -eq $target_vmSizingPolicyName}
		$target_vmSizingPolicyURN  = $target_vmSizingPolicy.id
		

		if(($current_vmSizingPolicyURN -eq $target_vmSizingPolicyURN) -and ($target_vmSizingPolicyURN -ne $null)){
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Skip VM: $VMname ,Sizing policy $current_vmSizingPolicyName"
		}else{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Update VM: $VMname from: $current_vmSizingPolicyName to: $target_vmSizingPolicyName"
			$responseVM = Invoke-RestMethod -Uri $VMhref -Headers $headers -Method GET -WebSession $MYSESSION
			
			##Update XML
			# $xmlAdminOrg.SetAttribute("name",$targetOrg)
			
			$responseVM.Vm.ComputePolicy.VmSizingPolicy.SetAttribute("href","https://"+$vcdHost+"/cloudapi/1.0.0/vdcComputePolicies/" + $target_vmSizingPolicyURN)
			$responseVM.Vm.ComputePolicy.VmSizingPolicy.SetAttribute("id",$target_vmSizingPolicyURN)
			$responseVM.Vm.ComputePolicy.VmSizingPolicy.SetAttribute("name",$target_vmSizingPolicyName)
			
			#$myFile = 'tempsomefile.xml'
			#$responseVM.Save($myFile)
			#$var = Get-Content $myFile
			
			$ContentType = "application/vnd.vmware.vcloud.vm+xml;version="+$apiver
			$updateVMhref = $VMhref + "/action/reconfigureVm"
			$UpdateVM = Invoke-RestMethod -Method Post -Uri $updateVMhref -Body $responseVM -ContentType $ContentType -Headers $headers
		}
	}
}
Stop-Transcript
