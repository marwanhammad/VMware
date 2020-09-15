#Exporting the XML
function ExportXMLfile($retXML,$exportFile){
	$retXML.Save($exportFile)
	#Change the encoding to "default"
	Get-Content -Encoding UTF8 $exportFile | Out-File -Encoding default -FilePath "$($exportFile)a"
	Remove-Item -Force $exportFile
	Rename-Item "$($exportFile)a" $exportFile
}