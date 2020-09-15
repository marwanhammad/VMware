

function Get-VCDToken($vcdHost,$apiver,$username,$password){
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : The Site $site is selected" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : The API URL $vcdHost is selected" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : The API Version $apiver is selected" -ForegroundColor Green

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
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Authenticating $username against $vcdHost"
	$loginurl = "https://$vcdHost/api/sessions"
	try{
		$Webheaders = Invoke-WebRequest -Uri $loginurl -Headers $headers -Method POST 
		$headers +=@{ "x-vcloud-authorization" = $Webheaders.Headers["x-vcloud-authorization"]}
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : User $username authenticated"
	}catch{
		$err=$_.Exception
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Error authenticating $username : aborting with error $err "
		exit 1
	}
	return $headers
}


#$responseExtnetwork=Invoke-RestMethod -Uri $ExtnetworkURL -Headers $headers -Method POST -body $xmlExtNetwork -ContentType $ContentType
					 #Post-vCloud $ExtnetworkURL $headers POST $xmlExtNetwork $ContentType
Function Check-vCD-Task($TaskURL){
	$timeout=300
        if ($TaskURL) {          # and we have a task href in the document returned

            Write-Host -ForegroundColor Green (Get-Date).ToString()"$ScriptIdentifier : Task submitted successfully, waiting for result"

            while($timeout -gt 0) {
                $taskxml = Invoke-RestMethod -Uri $TaskURL -Method 'Get' -Headers $Headers -TimeoutSec 5        # Get/refresh our task status
                switch ($taskxml.Task.status) {
                    "success" { Write-Host -ForegroundColor Green (Get-Date).ToString() "$ScriptIdentifier : Task completed successfully"; return $true; break }
                    "running" { Write-Host -ForegroundColor Yellow (Get-Date).ToString() "$ScriptIdentifier : Task running" }
                    "error" { Write-Host -ForegroundColor Red (Get-Date).ToString() "$ScriptIdentifier : Error running task"; return $false; break }
                    "canceled" { Write-Host -ForegroundColor Red (Get-Date).ToString() "$ScriptIdentifier : Task was cancelled"; return $false; break }
                    "aborted" { Write-Host -ForegroundColor Red (Get-Date).ToString() "$ScriptIdentifier : Task was aborted"; return $false; break }
                    "queued" { Write-Host -ForegroundColor Yellow (Get-Date).ToString() "$ScriptIdentifier : queued" }
                    "preRunning" { Write-Host -ForegroundColor Yellow (Get-Date).ToString() "$ScriptIdentifier : preRunning" }
                } # switch on current task status
                $timeout -= 5                                           # Decrease our timeout
                Start-Sleep -s 5                                        # Pause 1 second
            } # Timeout expired
            Write-Host -ForegroundColor Yellow (Get-Date).ToString() "$ScriptIdentifier :Task timeout reached (task may still be in progress)"
            return $false
        } else {
            Write-Host -ForegroundColor Red (Get-Date).ToString() "$ScriptIdentifier : Invalid Task URL "
        }
} 


Function getIDfromUrl($url){
    $arrayURL = [System.Uri]$url
    $ID=$arrayURL.Segments[($arrayURL.Segments.Count)-1]								
    return $ID.ToString()
}


Function Get-PVDCINFO ($headers ,$baseurl, $PVDCName ,$StorageProfile){
	$PVDCsURL = $baseurl +'/admin'
	Write-Host -ForegroundColor Green (Get-Date).ToString() "$ScriptIdentifier : Get PVDCs List "
	$responsePVDCs= Invoke-RestMethod -Uri $PVDCsURL -Headers $headers -Method GET -WebSession $MYSESSION
	$PVDCsList= $responsePVDCs.VCloud.ProviderVdcReferences.ProviderVdcReference
	##return 
	$Script:PVDCURL = ($PVDCsList | where-object {$_.name -eq $PVDCName }).href
	
	Write-Host -ForegroundColor Green (Get-Date).ToString() "$ScriptIdentifier : Get PVDC Info : $PVDCName "
	$responsePVDC= Invoke-RestMethod -Uri $PVDCURL -Headers $headers -Method GET -WebSession $MYSESSION
	$NetworkPoolList = $responsePVDC.ProviderVdc.NetworkPoolReferences.NetworkPoolReference
	
	$Script:NetworkPoolURL= ($NetworkPoolList | where-object {$_.name -like "*$PVDCName*"  }).href
	if ($NetworkPoolURL.count -eq '0'){ $Script:NetworkPoolURL = $NetworkPoolList[0]}
	
	$StorageProfilesList = $responsePVDC.ProviderVdc.StorageProfiles.ProviderVdcStorageProfile
	
	$Script:StorageProfileURL= ($StorageProfilesList | where-object {$_.name -eq $StorageProfile  }).href
}
