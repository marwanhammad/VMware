This script created for automate External customer creation cycle.

===========================================================================
	Created on:   		2019-11-04
	Created by:   		Marwan Hammad, Ereen Thabet
	Last Modification:	
	Status: 			Initial script development/InDev
 	Organization: 		OCB FCA SE Team
	-------------------------------------------------------------------
	v1.0.0	---	Initial Creation							---	2019-11-04
===========================================================================
-----------------------	 Root folder description:   -----------------------
===========================================================================
project_root/
	│
	├── Main.ps1 		# main Script file. "customer requirements entered in XML format"
	├── Scripts/ 		# Project source code.
	├── Modules/		# All Modules and functions required for the script.
	├── README
	├── Logs/		# Logs directory for script execution.
	├── Templates/ 		# vCloud XML Template for object creation.
	├── Customers-info/     # Customer requirements in <CustName>.xm
	├── SiteInfo/    	#vCloud site customization in <SiteName>.ini

===========================================================================
-----------------------   Script covering points:   -----------------------
===========================================================================
	- Logical Switch.
	- PESG.
	- Dynamic routing configuration.
	- External network.
	- Org.
	- OrgVDC / Multi OrgVDCs
    - Org VDC Inet Edge as Advanced
	- Direct OrgNetwork for Admin.

===========================================================================
------- Points Out of script scope for External customer creation: --------
===========================================================================
	- NSS integration.
	- Active Org access via WAF.
	- BGP configuration in Lan devices / global admin PSEG. "Use a predefined IPs"
	- IPAM reservation.