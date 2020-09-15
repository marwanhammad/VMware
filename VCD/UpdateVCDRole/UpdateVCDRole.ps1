<#	
	.NOTES
	===========================================================================
	 Created on:   	2019-11-19 
	 Created by:   	Marwan Hammad
	 Filename:      UdateRole.ps1
	---------------------------------------------------------------------------
	v1.0.0	---	Initial Creation								---	2019-11-19
	v1.0.1  --- Skip System Org									--- 2019-11-25
	===========================================================================
	.DESCRIPTION
		 Add Rights to existing Role
		 ============================================================================
		 
		 ============================================================================
#>
################### Params ####################

#VCD API URL	
$vcdHost=''
#vCloud API version
$apiver = ""
#UserName do not forget @system
$username='@system'
#password
$password=''
#Organization name, case and space sensitive, leave blank to update all orgs
$orgName=''
#Role name
$roleName = ""
#The name of the log file you need
$logfile="_UpdateRole.log"

#rights to add
$regex="Organization vDC: VM-VM Affinity Edit"

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
$start1=Start-Transcript (($logFolder)+($log)) -noclobber

Write-Host (Get-Date).ToString() "= The Site $site is selected" -ForegroundColor Green
Write-Host (Get-Date).ToString() "= The API URL $vcdHost is selected" -ForegroundColor Green
Write-Host (Get-Date).ToString() "= The API Version $apiver is selected" -ForegroundColor Green


##########################Functions#############################

function getIDfromUrl($url){
    $arrayURL = [System.Uri]$url
    $ID=$arrayURL.Segments[($arrayURL.Segments.Count)-1]								
    return $ID.ToString()
}

function ExportXMLfile($retXML,$exportFile){
	$retXML.Save($exportFile)
	#Change the encoding to "default"
	Get-Content -Encoding UTF8 $exportFile | Out-File -Encoding default -FilePath "$($exportFile)a"
	Remove-Item -Force $exportFile
	Rename-Item "$($exportFile)a" $exportFile
}

function Get-ScriptVersion
	{
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

Function AddRights($responseRole,$rightsToAdd){


        #Build the XML to PUT
        [System.Xml.XmlDocument]$XML=New-Object System.Xml.XmlDocument
        $Null=@(
		$Role=$XML.CreateElement("Role")
		$Role.SetAttribute("xmlns","http://www.vmware.com/vcloud/v1.5")
		$Role.SetAttribute("name",$responseRole.Role.name)
		
		($Role.AppendChild($XML.CreateElement("Description"))).AppendChild(($XML.CreateTextNode($responseRole.Role.Description)))
		
		
        $orgRightsXML =$XML.CreateElement("RightReferences")
        
        #Adding all the previous orgs except those to ADd (in order not to add them twice)
        foreach($right in $responseRole.Role.RightReferences.RightReference){
            if(-not($rightsToAdd.name.Contains($right.name))){
            #Append to the XML file
                $orgRightsXML.AppendChild($orgRightsXML.OwnerDocument.ImportNode($right,$true))
            }
	    
        }
        #Add those to Add
        foreach($rightToAdd in $rightsToAdd){
            $orgRightsXML.AppendChild($orgRightsXML.OwnerDocument.ImportNode($rightToAdd,$true))
        }
		$Role.AppendChild($orgRightsXML)
        $XML.AppendChild($Role)
		)
		return $XML

}


#################MAIN###########################################

Write-Host (Get-Date).ToString() "= Beginning of the script"
Write-Host (Get-Date).ToString() "= Script version: $(Get-ScriptVersion)" -ForegroundColor Green

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



#####Get admin view
$resource = "/admin"
$Adminurl = $baseurl + $resource
try{
$responseAdmin = Invoke-RestMethod -Uri $Adminurl -Headers $headers -Method GET 
}catch{
    $err=$_.Exception
    Write-Host "Error : aborting with error $err "
    exit 1
}
#Get the list of rights
$AllrightsList=$responseAdmin.VCloud.RightReferences	
$OrgList=$responseAdmin.VCloud.OrganizationReferences.OrganizationReference

if(!($AllrightsList)) { Write-Host (Get-Date).ToString() "= Can't get Rights List";exit 7}
if(!($OrgList)) 	  { Write-Host (Get-Date).ToString() "= Can't get Org List";exit 7}

if($orgName){$OrgList=$OrgList | where-object{$_.name -eq $orgName}}

foreach ($Org in $OrgList){
	
	$orgURL=$Org.href
	$orgName=$org.name
	if($orgURL -and $orgName -ne 'System'){
		try{
			Write-Host (Get-Date).ToString() "Getting the org $orgName"
			$responseOrg=Invoke-RestMethod -Uri $orgURL -Headers $headers  -Method GET 
        }catch{
            $err=$_.Exception
            Write-Host (Get-Date).ToString() "Error : Aborting, issue retrieving org with error $err "
            #exit 1
        }
	$Role= $responseOrg.AdminOrg.RoleReferences.RoleReference | where-object {$_.name -eq $roleName}
	$RoleURL= $Role.href
	$RoleName2 =$Role.Name
	
		try{
			Write-Host (Get-Date).ToString() "Getting the Role $RoleName2"
			[xml]$responseRole = Invoke-RestMethod -Uri $RoleURL -Headers $headers -Method GET 
			
		}catch{
	    $err=$_.Exception
            Write-Host (Get-Date).ToString() "Error : getting the right of the org with error $err "
            #exit 1
        }
	
	#Get the rights to Add
        $rightsToAdd=@()
        foreach($right in $AllrightsList.RightReference){
            if(($right.name -match $regex) -and ($responseOrg) ){
                $rightsToAdd+=$right
            }
        }
	
	# $responseRole.Role.RightReferences.RightReference
	##Build XML
	$NewRights = AddRights $responseRole $rightsToAdd 
	}
	
	if ($NewRights.Role.RightReferences.RightReference.name.Count -eq $responseRole.Role.RightReferences.RightReference.Count){
		Write-Host (Get-Date).ToString() "Org $orgName has the new Rights nothing to do"
	}else{
		##Post new Rughts
		$Rolename=$responseRole.role.name
		Write-Host (Get-Date).ToString() "Update Rights for Org: $orgName Role: $Rolename " -ForegroundColor Green
		$ContentType="application/vnd.vmware.admin.role+xml"
		[xml]$responseRole = Invoke-RestMethod -Uri $RoleURL -Headers $headers -Method PUT -body $NewRights -ContentType $ContentType
		
	}
}

Stop-Transcript

