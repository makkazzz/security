@ECHO OFF & SETLOCAL EnableDelayedExpansion
TITLE PooPee - PooPee
COLOR 0F
CALL :SetOnce

SET long=false

SET "CurrentFolder=%~dp0"
IF "!CurrentFolder!" NEQ "!CurrentFolder: =!" (
    ECHO PooPee.bat cannot run if the current path contains spaces.
	ECHO Exiting.
    EXIT /B 1
)

:SystemInfo
CALL :ColorLine "%E%32m[*]%E%97m BASIC SYSTEM INFO"
CALL :ColorLine " %E%33m[+]%E%97m WINDOWS OS"
ECHO.   [i] Check for vulnerabilities for the OS version with the applied patches
systeminfo
ECHO.
CALL :T_Progress 2

:DateAndTime
CALL :ColorLine " %E%33m[+]%E%97m DATE and TIME"
ECHO.   [i] You may need to adjust your local date/time to exploit some vulnerability
date /T
time /T
ECHO.
CALL :T_Progress 2

:AuditSettings
CALL :ColorLine " %E%33m[+]%E%97m Audit Settings"
ECHO.   [i] Check what is being logged
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit 2>nul
ECHO.
CALL :T_Progress 1

:WEFSettings
CALL :ColorLine " %E%33m[+]%E%97m WEF Settings"
ECHO.   [i] Check where are being sent the logs
REG QUERY HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager 2>nul
ECHO.
CALL :T_Progress 1

:LAPSInstallCheck
CALL :ColorLine " %E%33m[+]%E%97m LAPS installed?"
ECHO.   [i] Check what is being logged
REG QUERY "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft Services\AdmPwd" /v AdmPwdEnabled 2>nul
ECHO.
CALL :T_Progress 1

:LSAProtectionCheck
CALL :ColorLine " %E%33m[+]%E%97m LSA protection?"
ECHO.   [i] Active if "1"
REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA" /v RunAsPPL 2>nul
CALL :T_Progress 1

:LSACredentialGuard
CALL :ColorLine " %E%33m[+]%E%97m Credential Guard?"
ECHO.   [i] Active if "1" or "2"
REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA" /v LsaCfgFlags 2>nul
ECHO.
CALL :T_Progress 1

:LogonCredentialsPlainInMemory
CALL :ColorLine " %E%33m[+]%E%97m WDigest?"
ECHO.   [i] Plain-text creds in memory if "1"
reg query HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest\UseLogonCredential 2>nul
ECHO.
CALL :T_Progress 1

:CachedCreds
CALL :ColorLine " %E%33m[+]%E%97m Number of cached creds"
ECHO.   [i] You need System-rights to extract them
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v CACHEDLOGONSCOUNT 2>nul
CALL :T_Progress 1

:UACSettings
CALL :ColorLine " %E%33m[+]%E%97m UAC Settings"
ECHO.   [i] If the results read ENABLELUA REG_DWORD 0x1, part or all of the UAC components are on
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\ /v EnableLUA 2>nul
ECHO.
CALL :T_Progress 1

:AVSettings
CALL :ColorLine " %E%33m[+]%E%97m Registered Anti-Virus(AV)"
WMIC /Node:localhost /Namespace:\\root\SecurityCenter2 Path AntiVirusProduct Get displayName /Format:List | more 
ECHO.Checking for defender whitelisted PATHS
reg query "HKLM\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths" 2>nul
CALL :T_Progress 1

:PSSettings
CALL :ColorLine " %E%33m[+]%E%97m PowerShell settings"
ECHO.PowerShell v2 Version:
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine /v PowerShellVersion 2>nul
ECHO.PowerShell v5 Version:
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine /v PowerShellVersion 2>nul
ECHO.Transcriptions Settings:
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription 2>nul
ECHO.Module logging settings:
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging 2>nul
ECHO.Scriptblog logging settings:
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging 2>nul
ECHO.
ECHO.PS default transcript history
dir %SystemDrive%\transcripts\ 2>nul
ECHO.
ECHO.Checking PS history file
dir "%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" 2>nul
ECHO.
CALL :T_Progress 3

:MountedDisks
CALL :ColorLine " %E%33m[+]%E%97m MOUNTED DISKS"
ECHO.   [i] Maybe you find something interesting
(wmic logicaldisk get caption 2>nul | more) || (fsutil fsinfo drives 2>nul)
ECHO.
CALL :T_Progress 1

:Environment
CALL :ColorLine " %E%33m[+]%E%97m ENVIRONMENT"
ECHO.   [i] Interesting information?
ECHO.
set
ECHO.
CALL :T_Progress 1

:InstalledSoftware
CALL :ColorLine " %E%33m[+]%E%97m INSTALLED SOFTWARE"
ECHO.   [i] Some weird software? Check for vulnerabilities in unknow software installed
ECHO.
dir /b "C:\Program Files" "C:\Program Files (x86)" | sort
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr InstallLocation | findstr ":\\"
reg query HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ /s | findstr InstallLocation | findstr ":\\"
IF exist C:\Windows\CCM\SCClient.exe ECHO.SCCM is installed (installers are run with SYSTEM privileges, many are vulnerable to DLL Sideloading)
ECHO.
CALL :T_Progress 2

:RemodeDeskCredMgr
CALL :ColorLine " %E%33m[+]%E%97m Remote Desktop Credentials Manager"
IF exist "%LOCALAPPDATA%\Local\Microsoft\Remote Desktop Connection Manager\RDCMan.settings" ECHO.Found: RDCMan.settings in %AppLocal%\Local\Microsoft\Remote Desktop Connection Manager\RDCMan.settings, check for credentials in .rdg files
ECHO.
CALL :T_Progress 1

:WSUS
CALL :ColorLine " %E%33m[+]%E%97m WSUS"
ECHO.   [i] You can inject 'fake' updates into non-SSL WSUS traffic (WSUXploit)
reg query HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate\ 2>nul | findstr /i "wuserver" | findstr /i "http://"
ECHO.
CALL :T_Progress 1

:RunningProcesses
CALL :ColorLine " %E%33m[+]%E%97m RUNNING PROCESSES"
ECHO.   [i] Something unexpected is running? Check for vulnerabilities
tasklist /SVC
ECHO.
CALL :T_Progress 2
ECHO.   [i] Checking file permissions of running processes (File backdooring - maybe the same files start automatically when Administrator logs in)
for /f "tokens=2 delims='='" %%x in ('wmic process list full^|find /i "executablepath"^|find /i /v "system32"^|find ":"') do (
	for /f eol^=^"^ delims^=^" %%z in ('ECHO.%%x') do (
		icacls "%%z" 2>nul | findstr /i "(F) (M) (W) :\\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO.
	)
)
ECHO.
ECHO.   [i] Checking directory permissions of running processes (DLL injection)
for /f "tokens=2 delims='='" %%x in ('wmic process list full^|find /i "executablepath"^|find /i /v "system32"^|find ":"') do for /f eol^=^"^ delims^=^" %%y in ('ECHO.%%x') do (
	icacls "%%~dpy\" 2>nul | findstr /i "(F) (M) (W) :\\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO.
)
ECHO.
CALL :T_Progress 3

:RunAtStartup
CALL :ColorLine " %E%33m[+]%E%97m RUN AT STARTUP"
ECHO.   [i] Check if you can modify any binary that is going to be executed by admin or if you can impersonate a not found binary
::(autorunsc.exe -m -nobanner -a * -ct /accepteula 2>nul || wmic startup get caption,command 2>nul | more & ^
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run 2>nul & ^
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce 2>nul & ^
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run 2>nul & ^
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce 2>nul & ^
CALL :T_Progress 2
icacls "C:\Documents and Settings\All Users\Start Menu\Programs\Startup" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
icacls "C:\Documents and Settings\All Users\Start Menu\Programs\Startup\*" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
icacls "C:\Documents and Settings\%username%\Start Menu\Programs\Startup" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
icacls "C:\Documents and Settings\%username%\Start Menu\Programs\Startup\*" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
CALL :T_Progress 2
icacls "%programdata%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
icacls "%programdata%\Microsoft\Windows\Start Menu\Programs\Startup\*" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
icacls "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
icacls "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\*" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. & ^
CALL :T_Progress 2
schtasks /query /fo TABLE /nh | findstr /v /i "disable deshab informa")
ECHO.
CALL :T_Progress 2

:AlwaysInstallElevated
CALL :ColorLine " %E%33m[+]%E%97m AlwaysInstallElevated?"
ECHO.   [i] If '1' then you can install a .msi file with admin privileges ;)
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated 2> nul
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated 2> nul
ECHO.
CALL :T_Progress 2

:NetworkShares
CALL :ColorLine "%E%32m[*]%E%97m NETWORK"
CALL :ColorLine " %E%33m[+]%E%97m CURRENT SHARES"
net share
ECHO.
CALL :T_Progress 1

:NetworkInterfaces
CALL :ColorLine " %E%33m[+]%E%97m INTERFACES"
ipconfig  /all
ECHO.
CALL :T_Progress 1

:NetworkUsedPorts
CALL :ColorLine " %E%33m[+]%E%97m USED PORTS"
ECHO.   [i] Check for services restricted from the outside
netstat -ano | findstr /i listen
ECHO.
CALL :T_Progress 1

:NetworkFirewall
CALL :ColorLine " %E%33m[+]%E%97m FIREWALL"
netsh firewall show state
netsh firewall show config
ECHO.
CALL :T_Progress 2

:ARP
CALL :ColorLine " %E%33m[+]%E%97m ARP"
arp -A
ECHO.
CALL :T_Progress 1

:NetworkRoutes
CALL :ColorLine " %E%33m[+]%E%97m ROUTES"
route print
ECHO.
CALL :T_Progress 1

:WindowsHostsFile
CALL :ColorLine " %E%33m[+]%E%97m Hosts file"
type C:\WINDOWS\System32\drivers\etc\hosts | findstr /v "^#"
CALL :T_Progress 1

:DNSCache
CALL :ColorLine " %E%33m[+]%E%97m DNS CACHE"
ipconfig /displaydns | findstr "Record" | findstr "Name Host"
ECHO.
CALL :T_Progress 1

:WifiCreds
CALL :ColorLine " %E%33m[+]%E%97m WIFI"
for /f "tokens=3,* delims=: " %%a in ('netsh wlan show profiles ^| find "Profile "') do (netsh wlan show profiles name=%%b key=clear | findstr "SSID Cipher Content" | find /v "Number" & ECHO.)
CALL :T_Progress 1

:BasicUserInfo
CALL :ColorLine "%E%32m[*]%E%97m BASIC USER INFO
ECHO.   [i] Check if you are inside the Administrators group or if you have enabled any token that can be use to escalate privileges like SeImpersonatePrivilege, SeAssignPrimaryPrivilege, SeTcbPrivilege, SeBackupPrivilege, SeRestorePrivilege, SeCreateTokenPrivilege, SeLoadDriverPrivilege, SeTakeOwnershipPrivilege, SeDebbugPrivilege
ECHO.
CALL :ColorLine " %E%33m[+]%E%97m CURRENT USER"
net user %username%
net user %USERNAME% /domain 2>nul
whoami /all
ECHO.
CALL :T_Progress 2

:BasicUserInfoUsers
CALL :ColorLine " %E%33m[+]%E%97m USERS"
net user
ECHO.
CALL :T_Progress 1

:BasicUserInfoGroups
CALL :ColorLine " %E%33m[+]%E%97m GROUPS"
net localgroup
ECHO.
CALL :T_Progress 1

:BasicUserInfoAdminGroups
CALL :ColorLine " %E%33m[+]%E%97m ADMINISTRATORS GROUPS"
REM seems to be localised
net localgroup Administrators 2>nul
net localgroup Administradores 2>nul
ECHO. 
CALL :T_Progress 1

:BasicUserInfoLoggedUser
CALL :ColorLine " %E%33m[+]%E%97m CURRENT LOGGED USERS"
quser
ECHO. 
CALL :T_Progress 1

:KerberosTickets
CALL :ColorLine " %E%33m[+]%E%97m Kerberos Tickets"
klist
ECHO. 
CALL :T_Progress 1

:CurrentClipboard
CALL :ColorLine " %E%33m[+]%E%97m CURRENT CLIPBOARD"
ECHO.   [i] Any passwords inside the clipboard?
powershell -command "Get-Clipboard" 2>nul
ECHO.
CALL :T_Progress 1

:ServiceVulnerabilities
CALL :ColorLine "%E%32m[*]%E%97m SERVICE VULNERABILITIES"
:::sysinternals external tool
::ECHO.
::CALL :ColorLine " %E%33m[+]%E%97m SERVICE PERMISSIONS WITH accesschk.exe FOR 'Authenticated users', Everyone, BUILTIN\Users, Todos and CURRENT USER"
::ECHO.   [i] If Authenticated Users have SERVICE_ALL_ACCESS or SERVICE_CHANGE_CONFIG or WRITE_DAC or WRITE_OWNER or GENERIC_WRITE or GENERIC_ALL, you can modify the binary that is going to be executed by the service and start/stop the service
::ECHO.   [i] If accesschk.exe is not in PATH, nothing will be found here
::ECHO.   [i] AUTHETICATED USERS
::accesschk.exe -uwcqv "Authenticated Users" * /accepteula 2>nul
::ECHO.   [i] EVERYONE
::accesschk.exe -uwcqv "Everyone" * /accepteula 2>nul
::ECHO.   [i] BUILTIN\Users
::accesschk.exe -uwcqv "BUILTIN\Users" * /accepteula 2>nul
::ECHO.   [i] TODOS
::accesschk.exe -uwcqv "Todos" * /accepteula 2>nul
::ECHO.   [i] %USERNAME%
::accesschk.exe -uwcqv %username% * /accepteula 2>nul
::ECHO.
::CALL :ColorLine " %E%33m[+]%E%97m SERVICE PERMISSIONS WITH accesschk.exe FOR *"
::ECHO.   [i] Check for weird service permissions for unexpected groups"
::accesschk.exe -uwcqv * /accepteula 2>nul
CALL :T_Progress 1
ECHO.

:ServiceBinaryPermissions
CALL :ColorLine " %E%33m[+]%E%97m SERVICE BINARY PERMISSIONS WITH WMIC and ICACLS"
for /f "tokens=2 delims='='" %%a in ('cmd.exe /c wmic service list full ^| findstr /i "pathname" ^|findstr /i /v "system32"') do (
    for /f eol^=^"^ delims^=^" %%b in ("%%a") do icacls "%%b" 2>nul | findstr /i "(F) (M) (W) :\\" | findstr /i ":\\ everyone authenticated users todos usuarios %username%" && ECHO.
)
ECHO.
CALL :T_Progress 1

:CheckRegistryModificationAbilities
CALL :ColorLine " %E%33m[+]%E%97m CHECK IF YOU CAN MODIFY ANY SERVICE REGISTRY"
for /f %%a in ('reg query hklm\system\currentcontrolset\services') do del %temp%\reg.hiv >nul 2>&1 & reg save %%a %temp%\reg.hiv >nul 2>&1 && reg restore %%a %temp%\reg.hiv >nul 2>&1 && ECHO.You can modify %%a
ECHO.
CALL :T_Progress 1

:UnquotedServicePaths
CALL :ColorLine " %E%33m[+]%E%97m UNQUOTED SERVICE PATHS"
ECHO.   [i] When the path is not quoted (ex: C:\Program files\soft\new folder\exec.exe) Windows will try to execute first 'C:\Program.exe', then 'C:\Program Files\soft\new.exe' and finally 'C:\Program Files\soft\new folder\exec.exe'. Try to create 'C:\Program Files\soft\new.exe'
ECHO.   [i] The permissions are also checked and filtered using icacls
for /f "tokens=2" %%n in ('sc query state^= all^| findstr SERVICE_NAME') do (
	for /f "delims=: tokens=1*" %%r in ('sc qc "%%~n" ^| findstr BINARY_PATH_NAME ^| findstr /i /v /l /c:"c:\windows\system32" ^| findstr /v /c:""""') do (
		ECHO.%%~s ^| findstr /r /c:"[a-Z][ ][a-Z]" >nul 2>&1 && (ECHO.%%n && ECHO.%%~s && icacls %%s | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%") && ECHO.
	)
)
CALL :T_Progress 2
::wmic service get name,displayname,pathname,startmode | more | findstr /i /v "C:\\Windows\\system32\\" | findstr /i /v """
ECHO.
::CALL :T_Progress 1

:PATHenvHijacking
CALL :ColorLine "%E%32m[*]%E%97m DLL HIJACKING in PATHenv variable"
ECHO.   [i] Maybe you can take advantage of modifying/creating some binary in some of the following locations
ECHO.   [i] PATH variable entries permissions - place binary or DLL to execute instead of legitimate
for %%A in ("%path:;=";"%") do ( cmd.exe /c icacls "%%~A" 2>nul | findstr /i "(F) (M) (W) :\" | findstr /i ":\\ everyone authenticated users todos %username%" && ECHO. )
ECHO.
CALL :T_Progress 1

:WindowsCredentials
CALL :ColorLine "%E%32m[*]%E%97m CREDENTIALS"
ECHO.
CALL :ColorLine " %E%33m[+]%E%97m WINDOWS VAULT"
cmdkey /list
ECHO.
CALL :T_Progress 2

:DPAPIMasterKeys
CALL :ColorLine " %E%33m[+]%E%97m DPAPI MASTER KEYS"
powershell -command "Get-ChildItem %appdata%\Microsoft\Protect" 2>nul
powershell -command "Get-ChildItem %localappdata%\Microsoft\Protect" 2>nul
CALL :T_Progress 2
CALL :ColorLine " %E%33m[+]%E%97m DPAPI MASTER KEYS"
ECHO.
ECHO.Looking inside %appdata%\Microsoft\Credentials\
ECHO.
dir /b/a %appdata%\Microsoft\Credentials\ 2>nul 
CALL :T_Progress 2
ECHO.
ECHO.Looking inside %localappdata%\Microsoft\Credentials\
ECHO.
dir /b/a %localappdata%\Microsoft\Credentials\ 2>nul
CALL :T_Progress 2
ECHO.

:UnattendedFiles
CALL :ColorLine " %E%33m[+]%E%97m Unattended files"
IF EXIST %WINDIR%\sysprep\sysprep.xml ECHO.%WINDIR%\sysprep\sysprep.xml exists. 
IF EXIST %WINDIR%\sysprep\sysprep.inf ECHO.%WINDIR%\sysprep\sysprep.inf exists. 
IF EXIST %WINDIR%\sysprep.inf ECHO.%WINDIR%\sysprep.inf exists. 
IF EXIST %WINDIR%\Panther\Unattended.xml ECHO.%WINDIR%\Panther\Unattended.xml exists. 
IF EXIST %WINDIR%\Panther\Unattend.xml ECHO.%WINDIR%\Panther\Unattend.xml exists. 
IF EXIST %WINDIR%\Panther\Unattend\Unattend.xml ECHO.%WINDIR%\Panther\Unattend\Unattend.xml exists. 
IF EXIST %WINDIR%\Panther\Unattend\Unattended.xml ECHO.%WINDIR%\Panther\Unattend\Unattended.xml exists.
IF EXIST %WINDIR%\System32\Sysprep\unattend.xml ECHO.%WINDIR%\System32\Sysprep\unattend.xml exists.
IF EXIST %WINDIR%\System32\Sysprep\unattended.xml ECHO.%WINDIR%\System32\Sysprep\unattended.xml exists.
IF EXIST %WINDIR%\..\unattend.txt ECHO.%WINDIR%\..\unattend.txt exists.
IF EXIST %WINDIR%\..\unattend.inf ECHO.%WINDIR%\..\unattend.inf exists. 
ECHO.
CALL :T_Progress 2

:SAMSYSBackups
CALL :ColorLine " %E%33m[+]%E%97m SAM and SYSTEM backups"
IF EXIST %WINDIR%\repair\SAM ECHO.%WINDIR%\repair\SAM exists. 
IF EXIST %WINDIR%\System32\config\RegBack\SAM ECHO.%WINDIR%\System32\config\RegBack\SAM exists.
IF EXIST %WINDIR%\System32\config\SAM ECHO.%WINDIR%\System32\config\SAM exists.
IF EXIST %WINDIR%\repair\SYSTEM ECHO.%WINDIR%\repair\SYSTEM exists.
IF EXIST %WINDIR%\System32\config\SYSTEM ECHO.%WINDIR%\System32\config\SYSTEM exists.
IF EXIST %WINDIR%\System32\config\RegBack\SYSTEM ECHO.%WINDIR%\System32\config\RegBack\SYSTEM exists.
ECHO.
CALL :T_Progress 3

:McAffeeSitelist
CALL :ColorLine " %E%33m[+]%E%97m McAffee SiteList.xml"
cd %ProgramFiles% 2>nul
dir /s SiteList.xml 2>nul
cd %ProgramFiles(x86)% 2>nul
dir /s SiteList.xml 2>nul
cd "%windir%\..\Documents and Settings" 2>nul
dir /s SiteList.xml 2>nul
cd %windir%\..\Users 2>nul
dir /s SiteList.xml 2>nul
ECHO.
CALL :T_Progress 2

:GPPPassword
CALL :ColorLine " %E%33m[+]%E%97m GPP Password"
cd "%SystemDrive%\Microsoft\Group Policy\history" 2>nul
dir /s/b Groups.xml == Services.xml == Scheduledtasks.xml == DataSources.xml == Printers.xml == Drives.xml 2>nul
cd "%windir%\..\Documents and Settings\All Users\Application Data\Microsoft\Group Policy\history" 2>nul
dir /s/b Groups.xml == Services.xml == Scheduledtasks.xml == DataSources.xml == Printers.xml == Drives.xml 2>nul
ECHO.
CALL :T_Progress 2

:CloudCreds
CALL :ColorLine " %E%33m[+]%E%97m Cloud Credentials"
cd "%SystemDrive%\Users"
dir /s/b .aws == credentials == gcloud == credentials.db == legacy_credentials == access_tokens.db == .azure == accessTokens.json == azureProfile.json 2>nul
cd "%windir%\..\Documents and Settings"
dir /s/b .aws == credentials == gcloud == credentials.db == legacy_credentials == access_tokens.db == .azure == accessTokens.json == azureProfile.json 2>nul
ECHO.
CALL :T_Progress 2

:AppCMD
CALL :ColorLine " %E%33m[+]%E%97m AppCmd"
IF EXIST %systemroot%\system32\inetsrv\appcmd.exe ECHO.%systemroot%\system32\inetsrv\appcmd.exe exists. 
ECHO.
CALL :T_Progress 2

:RegFilesCredentials
CALL :ColorLine " %E%33m[+]%E%97m Files in registry that may contain credentials"
ECHO.   [i] Searching specific files that may contains credentials.
ECHO.Looking inside HKCU\Software\ORL\WinVNC3\Password
reg query HKCU\Software\ORL\WinVNC3\Password 2>nul
CALL :T_Progress 2
ECHO.Looking inside HKEY_LOCAL_MACHINE\SOFTWARE\RealVNC\WinVNC4/password
reg query HKEY_LOCAL_MACHINE\SOFTWARE\RealVNC\WinVNC4 /v password 2>nul
CALL :T_Progress 2
ECHO.Looking inside HKLM\SOFTWARE\Microsoft\Windows NT\Currentversion\WinLogon
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon" 2>nul | findstr /i "DefaultDomainName DefaultUserName DefaultPassword AltDefaultDomainName AltDefaultUserName AltDefaultPassword LastUsedUsername"
CALL :T_Progress 2
ECHO.Looking inside HKLM\SYSTEM\CurrentControlSet\Services\SNMP
reg query HKLM\SYSTEM\CurrentControlSet\Services\SNMP /s 2>nul
CALL :T_Progress 2
ECHO.Looking inside HKCU\Software\TightVNC\Server
reg query HKCU\Software\TightVNC\Server 2>nul
CALL :T_Progress 2
ECHO.Looking inside HKCU\Software\SimonTatham\PuTTY\Sessions
reg query HKCU\Software\SimonTatham\PuTTY\Sessions /s 2>nul
CALL :T_Progress 2
ECHO.Looking inside HKCU\Software\OpenSSH\Agent\Keys
CALL :T_Progress 2
reg query HKCU\Software\OpenSSH\Agent\Keys /s 2>nul
cd %USERPROFILE% 2>nul && dir /s/b *password* == *credential* 2>nul
cd ..\..\..\..\..\..\..\..\..\..\..\..\..\..\..\..\..\..\..
dir /s/b /A:-D RDCMan.settings == *.rdg == SCClient.exe == *_history == .sudo_as_admin_successful == .profile == *bashrc == httpd.conf == *.plan == .htpasswd == .git-credentials == *.rhosts == hosts.equiv == Dockerfile == docker-compose.yml == appcmd.exe == TypedURLs == TypedURLsTime == History == Bookmarks == Cookies == "Login Data" == places.sqlite == key3.db == key4.db == credentials == credentials.db == access_tokens.db == accessTokens.json == legacy_credentials == azureProfile.json == unattend.txt == access.log == error.log == *.gpg == *.pgp == *config*.php == elasticsearch.y*ml == kibana.y*ml == *.p12 == *.der == *.csr == *.cer == known_hosts == id_rsa == id_dsa == *.ovpn == anaconda-ks.cfg == hostapd.conf == rsyncd.conf == cesi.conf == supervisord.conf == tomcat-users.xml == *.kdbx == KeePass.config == Ntds.dit == SAM == SYSTEM == FreeSSHDservice.ini == sysprep.inf == sysprep.xml == unattend.xml == unattended.xml == *vnc*.ini == *vnc*.c*nf* == *vnc*.txt == *vnc*.xml == groups.xml == services.xml == scheduledtasks.xml == printers.xml == drives.xml == datasources.xml == php.ini == https.conf == https-xampp.conf == httpd.conf == my.ini == my.cnf == access.log == error.log == server.xml == SiteList.xml == ConsoleHost_history.txt == setupinfo == setupinfo.bak 2>nul | findstr /v ".dll"
cd inetpub 2>nul && (dir /s/b web.config == *.log & cd ..)
ECHO.
CALL :T_Progress 2

:ExtendedDriveScan
if "%long%" == "true" (
    CALL :ColorLine " %E%33m[+]%E%97m REGISTRY WITH STRING pass OR pwd"
	reg query HKLM /f passw /t REG_SZ /s
	reg query HKCU /f passw /t REG_SZ /s
	reg query HKLM /f pwd /t REG_SZ /s
	reg query HKCU /f pwd /t REG_SZ /s
	ECHO.
	ECHO.   [i] Iterating through the drives
	ECHO.
	for /f %%x in ('wmic logicaldisk get name^| more') do (
		set tdrive=%%x
		if "!tdrive:~1,2!" == ":" (
			%%x
            CALL :ColorLine " %E%33m[+]%E%97m FILES THAT CONTAINS THE WORD PASSWORD WITH EXTENSION: .xml .ini .txt *.cfg *.config"
	        findstr /s/n/m/i password *.xml *.ini *.txt *.cfg *.config 2>nul | findstr /v /i "\\AppData\\Local \\WinSxS ApnDatabase.xml \\UEV\\InboxTemplates \\Microsoft.Windows.Cloud \\Notepad\+\+\\ vmware cortana alphabet \\7-zip\\" 2>nul
            ECHO.
            CALL :ColorLine " %E%33m[+]%E%97m FILES WHOSE NAME CONTAINS THE WORD PASS CRED or .config not inside \Windows\"
            dir /s/b *pass* == *cred* == *.config* == *.cfg 2>nul | findstr /v /i "\\windows\\"  
            ECHO.
		)
	)
	CALL :T_Progress 2
) ELSE (
	CALL :T_Progress 2
)
TITLE PooPee - PooPee - Idle
ECHO.---
ECHO.Scan complete.
PAUSE >NUL 
EXIT /B

:::-Subroutines

:SetOnce
REM :: ANSI escape character is set once below - for ColorLine Subroutine
SET "E=0x1B["
SET "PercentageTrack=0"
EXIT /B

:T_Progress
SET "Percentage=%~1"
SET /A "PercentageTrack=PercentageTrack+Percentage"
TITLE PooPee - PooPee - Scanning... !PercentageTrack!%%
EXIT /B

:ColorLine
SET "CurrentLine=%~1"
FOR /F "delims=" %%A IN ('FORFILES.EXE /P %~dp0 /M %~nx0 /C "CMD /C ECHO.!CurrentLine!"') DO ECHO.%%A
EXIT /B