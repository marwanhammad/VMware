function Exit-function { 
 
       #Param( 
       #[Parameter(Mandatory = $true)] 
       #[array] $Subnets 
       #) 
	Write-Host (Get-Date).ToString() "$ScriptIdentifier : Script Terminated" -ForegroundColor Red
	
	exit 5
}