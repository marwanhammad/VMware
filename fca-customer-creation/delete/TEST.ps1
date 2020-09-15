<#	
	.NOTES
	===========================================================================
	 Created on:   	2019-09-16 13:00
	 Created by:   	Marwan Hammad, Ereen Thabet
 	 Organization: 	OCB FCA SE Team
	 Filename:
	---------------------------------------------------------------------------
	v1.0.0	---	Initial Creation											---	2018-08-06
	v1.0.2	---	Fix Script Version bug and change the UCS Plugins			---	2018-12-06
	===========================================================================
	.DESCRIPTION
		 FCA SE External Customer Creation (Main)
		 ============================================================================
		 
		 ============================================================================
#>

$ScriptIdentifier ='[TEST]'

Write-Host (Get-Date).ToString() "$ScriptIdentifier : TEST Script version: $(Get-ScriptVersion)" -ForegroundColor Green

$A= $Customer.customer.FullName

$B= $Customizations.vcd.name

Write-Host (Get-Date).ToString() "$ScriptIdentifier : $A" -ForegroundColor Green
Write-Host (Get-Date).ToString() "$ScriptIdentifier : $B" -ForegroundColor Green