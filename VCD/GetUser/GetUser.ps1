##################################################################################################################
# Version = 2019.01.05
#
# Created by :  Marwan Hammad
#
# This script can Get the Task Owner	
#
##################################################################################################################
#
##################################################################################################################

#################### Params ####################

#UserName do not forget @system
$username='@system'
#password
$password=''

#The target org containing all the vCD containing all the vApp/VM we want to import
$TaskID=''

#The name of the log file you need
$logfile="_TaskID.log"


#### VCD Site ######
#API URL	
$vcdHost=''
#vCloud API version
$apiver = "31.0"

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

#Report 
$ReportFolder = $exportFolder+'Report\'
if(!(test-path $ReportFolder)){
	Write-Host (Get-Date).ToString() "= creating LOGS directory"
	$Rlog=New-Item -ItemType directory -force -Path $ReportFolder
}else{
	Write-Host (Get-Date).ToString() "= LOGS directory already exist"
}

$ID = get-date -Format "yyyyMMddXHHmm".ToString()

$ReportFileCSV=$ReportFolder + $ID + $ReportFile


############################################################
#

$start1=Start-Transcript (($logFolder)+($log)) -noclobber


Write-Host (Get-Date).ToString() "= The API URL $vcdHost is selected" -ForegroundColor Green
Write-Host (Get-Date).ToString() "= The API Version $apiver is selected" -ForegroundColor Green



#################MAIN###########################################

Write-Host (Get-Date).ToString() "= Beginning of the script"
Write-Host (Get-Date).ToString() "= Script Version = 2019.03.24"

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
		exit 1
	}

	$TaskURL=$baseurl+'/task/'+$TaskID
	Write-Host (Get-Date).ToString() "= Get Task ID info: $TaskID " -ForegroundColor Green
	$responseTASK=Invoke-RestMethod -Uri $TaskURL -Headers $headers -Method Get -ContentType $ContentType
	
	$UserURL=$responseTASK.Task.User.href
	Write-Host (Get-Date).ToString() "= Get User info " -ForegroundColor Green
	$responseUser=Invoke-RestMethod -Uri $UserURL -Headers $headers -Method Get -ContentType $ContentType
	
	
	$TaskOperation= $responseTASK.Task.operation
	$OrgName=$responseTASK.Task.Organization.name
	$StartTime= $responseTASK.Task.startTime
	$EndTime= $responseTASK.Task.endTime
	$Taskstatus=$responseTASK.Task.status
	$TaskOwner=$responseUser.User.name
	
	$View = @()
	   $Item = new-object PSObject -Property @{
	   TaskID= $TaskID
	   TaskOperation = $TaskOperation
	   OrgName = $OrgName
	   StartTime= $StartTime
	   EndTime= $EndTime
	   Taskstatus= $Taskstatus
	   TaskOwner=$TaskOwner
       }

   $View += $Item

	
	Write-Host (Get-Date).ToString() "= Task Owner: $TaskOwner" -ForegroundColor Yellow
	
	$View | format-list
	
Stop-Transcript