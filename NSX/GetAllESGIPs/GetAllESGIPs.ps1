##################################################################################################################
# Version = 2018.12.06
#
# Created by : Marwan Hammad
#
# List all IPS configured on NSX EDGE to CSV
#
#
##################################################################################################################


##------------------------------##
##			Read-Input			##
##------------------------------###
# 



	


$nsxManagerFQDN = ""
$NSXusername="admin"
$NSXpassword=''
$CSV1=''
$valid=$true




$CSV2=(Get-Date -Format "yyyyMMdd.hhmmss").ToString()

$CSV='.\'+$CSV1 +'_'+ $CSV2 + '.csv'

if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()



#############Report-Parameters####################

$Logfile=".\templog.txt"
'----------------------------------------------------' | out-file -filepath $Logfile -append -width 200
"vCenter: $CSV1" | out-file -filepath $Logfile -append -width 200
"Date   : $CSV2" | out-file -filepath $Logfile -append -width 200


$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($NSXusername + ":" + $NSXpassword))


	$edgesURL="https://$nsxManagerFQDN/api/4.0/edges?pageSize=1024"
	write-host "$edgesURL"
	"edgesURL: $edgesURL" | out-file -filepath $Logfile -append -width 200

	[xml]$FullPESGlist=Invoke-RestMethod -Uri $edgesURL -Method GET -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}

########filter cust edge#######
$CustPESGlist=($FullPESGlist.pagedEdgeList.edgePage.edgeSummary ).objectId

	$edgesURL="https://$nsxManagerFQDN/api/4.0/edges?pageSize=1024&startIndex=1024"
	write-host "$edgesURL"
	"edgesURL: $edgesURL" | out-file -filepath $Logfile -append -width 200

	[xml]$FullPESGlist=Invoke-RestMethod -Uri $edgesURL -Method GET -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}
	
	$CustPESGlist+=($FullPESGlist.pagedEdgeList.edgePage.edgeSummary ).objectId

write-host -ForeGroundColor Green $CustPESGlist

$AllIPs = @()
####ADD edge Setting to Report####
ForEach ($PESG in $CustPESGlist){
$PESGConfig=$FullPESGlist.pagedEdgeList.edgePage.edgeSummary | where {($_.objectId -eq "$PESG")}
$PESGname=$PESGConfig.name
$fragments+= "<H2>$PESGname</H2>"
If($PESG -ne ''){
	$edgeURL="https://$nsxManagerFQDN/api/4.0/edges/$($PESG)"
    write-host "Export Edge IP: $edgeURL"
	"edgeURL: $edgeURL" | out-file -filepath $Logfile -append -width 200
	$Edge=Invoke-RestMethod -Uri $edgeURL -Method GET -Headers @{'Content-Type'='application/xml';'Authorization' = "Basic $auth"}
	$primaryAddress=$Edge.edge.vnics.vnic.addressGroups.addressGroup.primaryAddress
	foreach($Addres in $primaryAddress){
		$NewIP = new-object PSObject -Property @{
		EdgeName=$Edge.edge.name
		Addres=$Addres
		}
		$AllIPs += $NewIP
	}
	
}

}

$AllIPs | Export-CSV -Path $CSV -NoType -Append
