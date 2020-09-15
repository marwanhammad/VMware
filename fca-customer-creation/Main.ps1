<#	
	.NOTES
	===========================================================================
	 Created on:   	2019-09-16
	 Created by:   	Marwan Hammad, Ereen Thabet
 	 Organization: 	OCB FCA SE Team
	 Filename:
	---------------------------------------------------------------------------
	v1.0.0	---	Initial Creation								---	2019-09-16
	v1.0.1	---	beta release 					                ---	2019-11-05
	===========================================================================
	.DESCRIPTION
		 FCA SE External Customer Creation (Main)
		 ============================================================================
		 
		 ============================================================================
#>

##################################################################################################################
#--------------------------------------------------------------------------
#---  Reading arguments                                            	    ---
#--------------------------------------------------------------------------
param(
[Parameter(Mandatory=$True)] [string] $CustomerFile
)

#################### Params ####################
#The name of the log file you need
$logfile="_FCASECustomerCreation.log"
$ScriptIdentifier='[Main]'

################# LOG & LOCATION ###########################################
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




# Get Script Version from Script header
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
	


################Script Body ####################

#Print Script version	
Write-Host (Get-Date).ToString() "$ScriptIdentifier : Script version: $(Get-ScriptVersion)" -ForegroundColor Green

##### Import Module ##########
$ModulesLocation = $WorkingDirectory+'Modules\'
$Modules = @(Get-ChildItem -Path $ModulesLocation'*.ps1')

foreach ($Module in $Modules){
	try{
		$Modulename =$Module.name
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : ImportModule $Modulename" -ForegroundColor Green
		$ModulePath= $ModulesLocation + $Modulename
		Import-module $ModulePath -Force
		
	}catch{
			Write-Host (Get-Date).ToString() "$ScriptIdentifier : Error Importing Model" -ForegroundColor Red
			Exit-function
	}
}	

###Import Customer XML
	$CustomerLocation = $WorkingDirectory+'Customers-info\' + $CustomerFile
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import customer file $CustomerLocation" -ForegroundColor Green
	$Customer = [Xml] (Get-Content $CustomerLocation  -ErrorVariable ProcessError -ErrorAction SilentlyContinue) 
	if ($ProcessError){
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Error Importing customer file  $CustomerLocation" -ForegroundColor Red
		Exit-function
	}
###Import Sites customizations
	$SelectedSiteName=$Customer.customer.site
	$CustomizationsLocation = $WorkingDirectory+'SiteInfo\' + $SelectedSiteName + '.ini'
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Site Name  $SelectedSiteName" -ForegroundColor Green
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Import site file $CustomizationsLocation" -ForegroundColor Green
	$Customizations = Get-IniFile $CustomizationsLocation -ErrorVariable ProcessError -ErrorAction SilentlyContinue
	if ($ProcessError){
		Write-Host (Get-Date).ToString() "$ScriptIdentifier : Error Importing site file  $CustomizationsLocation" -ForegroundColor Red
		Exit-function
	}

###TEMP_IPs

	#Import-module  D:\Scripts\OCBOPS\fca-customer-creation\Scripts\IPAM.ps1 -Force
	$ScriptIdentifier='[Main]'
	#TO_BE_remved
	$AdminUplink='100.64.118.7'
	$CSSASubnet='10.227.64.8/29'
	$InetUplink='100.64.1.173'
	
####
$ScriptLocation = $WorkingDirectory+'Scripts\'
Import-module  ($ScriptLocation + 'PESG.ps1') -Force
$ScriptIdentifier='[Main]'
Write-Host (Get-Date).ToString() "$ScriptIdentifier "	
	
Import-module  ($ScriptLocation + 'VCD.ps1') -Force 
$ScriptIdentifier='[Main]'
Write-Host (Get-Date).ToString() "$ScriptIdentifier "

Stop-Transcript