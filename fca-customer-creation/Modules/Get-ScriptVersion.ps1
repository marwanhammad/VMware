#################### DESCRIPTION ####################
#
# Get Script Version from Script header
#
################################################
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
	