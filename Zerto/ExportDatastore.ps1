#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# ZVM Server
$ZVMServer = "localhost"

# Get Credentials for ZVM API
$Credentials = Get-Credential -Message "Please enter Username and Password for ZVM $($ZVMServer)" -UserName $env:USERNAME
$username = $Credentials.UserName
$password = $Credentials.GetNetworkCredential().Password
#-----------------------------------------------------------[IgnoreCertificate]----------------------------------------------------
 [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
 
#-----------------------------------------------------------[Functions]------------------------------------------------------------

function getxZertoSession ($zvm, $userName, $password) {
    $xZertoSessionURL = $zvm+"session/add"
    $authInfo = ("{0}:{1}" -f $userName,$password)
    $authInfo = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
    $authInfo = [System.Convert]::ToBase64String($authInfo)
    $headers = @{Authorization=("Basic {0}" -f $authInfo)}
	#keep-alive = true
    $body = '{"AuthenticationMethod": "1"}'
    $contentType = "application/json"
    $xZertoSessionResponse = Invoke-WebRequest –UseBasicParsing -Uri $xZertoSessionURL -Headers $headers -Method POST -Body $body -ContentType $contentType
    return @{"x-zerto-session"=$xZertoSessionResponse.headers.get_item("x-zerto-session")}
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Build Zerto REST API Url
$BaseURL = "https://" + $ZVMServer + ":9669/v1/"

# Get Zerto Session Header for Auth
$ZertoSession = getxZertoSession "$($BaseURL)" $username $password

# Exist

###List VPG
$ZertoVPGsURL = $BaseURL + "vpgs"
$VPGSettingsIdentifier = Invoke-RestMethod -Method Get -Uri $ZertoVPGsURL  -TimeoutSec 100  -ContentType "application/json" -Headers $ZertoSession

# List VMs
$ZertoVMsURL = $BaseURL + "vms"
$VMSettingsIdentifier = Invoke-RestMethod -Method Get -Uri $ZertoVMsURL  -TimeoutSec 100  -ContentType "application/json" -Headers $ZertoSession

# List datastores
$ZertoDatastoresURL = $BaseURL + "datastores"
$Datastores = Invoke-RestMethod -Method Get -Uri $ZertoDatastoresURL  -TimeoutSec 100  -ContentType "application/json" -Headers $ZertoSession

# $VMToExport
$VMToExport=@()


Foreach ($VPG in $VPGSettingsIdentifier){

	$VPGID = $VPG.vpgidentifier
	$VPGVMCount = $VPG.VmsCount
	$VPGJSON = 
	"{
	""VpgIdentifier"":""$VPGID""
	}"
	################################################
	# Posting the VPG JSON Request to the API to get a settings ID (like clicking edit on a VPG in the GUI)
	################################################
	# URL to Edit VPG settings
	$EditVPGURL = $BaseURL+"vpgSettings"
	# POST
	Try 
	{
		$VPGSettingsID = Invoke-RestMethod -Method POST -Uri $EditVPGURL -Body $VPGJSON -ContentType "application/json" -Headers $ZertoSession 
		$ValidVPGSettingsID = $True
	}
	Catch 
	{
		$ValidVPGSettingsID = $False
		$_.Exception.ToString()
		$error[0] | Format-List -Force
	}
	
	if ($ValidVPGSettingsID -eq $True){
		$VPGSettingsURL = $BaseURL+"vpgSettings/"+$VPGSettingsID
		$VPGSettings = Invoke-RestMethod -Method GET -Uri $VPGSettingsURL -ContentType "application/json"-Headers $ZertoSession
		
		# Getting VPG Settings
		$VPGName = $VPGSettings.Basic.Name
		# Getting VM IDs in VPG
		$VPGVMIDs = $VPGSettings.VMs.VmIdentifier
		
		foreach ($VMID in $VPGVMIDs){
			$VMSetting =$VMSettingsIdentifier | Where-Object {$_.VMIdentifier -eq $VMID}
			
			$VMSettingsURL = $baseURL+"vpgSettings/"+$VPGSettingsID+"/vms/"+$VMID
			$VMSettings = Invoke-RestMethod -Method GET -Uri $VMSettingsURL -ContentType "application/json" -Headers $ZertoSession 
						
			$RecoverySiteDatastoreName = ($Datastores | where-object {$_.DatastoreIdentifier -eq $VMSettings.Recovery.DatastoreIdentifier }).DatastoreName
			
			$Line = new-object PSObject
			$Line | Add-Member -MemberType NoteProperty -Name "VPGName" -Value $VPGName
			$Line | Add-Member -MemberType NoteProperty -Name "VPGID" -Value $VPGID
			$Line | Add-Member -MemberType NoteProperty -Name "VMName" -Value $VMSetting.VmName
			$Line | Add-Member -MemberType NoteProperty -Name "SourceSite" -Value $VMSetting.SourceSite
			$Line | Add-Member -MemberType NoteProperty -Name "TargetSite" -Value $VMSetting.TargetSite
			$Line | Add-Member -MemberType NoteProperty -Name "RecoveryHostName" -Value $VMSetting.RecoveryHostName
			$Line | Add-Member -MemberType NoteProperty -Name "Status" -Value $VMSetting.Status
			$Line | Add-Member -MemberType NoteProperty -Name "RecoverySiteDatastore" -Value $RecoverySiteDatastoreName
			$VMToExport += $Line
		}
	}
}	
	
$VMToExport | Sort-Object VPGName,VMName | Export-CSV $CSVExportFile -NoTypeInformation -Force




