#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icon_1.ico
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=可自动更新的 Google Chrome 便携版
#AutoIt3Wrapper_Res_Description=Google Chrome Portable
#AutoIt3Wrapper_Res_Fileversion=3.2.1.0
#AutoIt3Wrapper_Res_LegalCopyright=甲壳虫<jdchenjian@gmail.com>
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_AU3Check_Parameters=-q
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Date.au3>
#include <Constants.au3>
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <ComboConstants.au3>
#include <GuiStatusBar.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include <APIFilesConstants.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>
#include <WinAPIReg.au3>
#include <APIRegConstants.au3>
#include <WinAPIDiag.au3>
#include <WinAPIMisc.au3>
#include <Security.au3>
#include <InetConstants.au3>
#include "WinHttp.au3" ; http://www.autoitscript.com/forum/topic/84133-winhttp-functions/
#include "SimpleMultiThreading.au3"

Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 3) ; Default tray menu items (Script Paused/Exit) will not be shown.
Opt("TrayOnEventMode", 1)
Opt("GUIOnEventMode", 1)
Opt("WinTitleMatchMode", 4)

Global Const $AppVersion = "3.2.1" ; MyChrome version
Global $AppName, $inifile, $FirstRun = 0, $ChromePath, $ChromeDir, $ChromeExe, $UserDataDir, $Params
Global $CacheDir, $CacheSize, $PortableParam
Global $LastCheckUpdate, $UpdateInterval, $Channel, $IsUpdating = 0, $x86 = 0
Global $ProxyType, $ProxySever, $ProxyPort, $UseInetEx
Global $AppUpdate, $AppUpdateLastCheck
Global $RunInBackground, $ExApp, $ExAppAutoExit, $ExApp2, $AppPID, $ExAppPID
Global $TaskBarDir = @AppDataDir & "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
Global $TaskBarLastChange
Global $aExApp, $aExApp2, $aExAppPID[2]
Global $maphost, $google_com
Global $CancelAppUpdate

Global $hSettings, $SettingsOK
Global $hSettingsOK, $hSettingsApply, $hStausbar
Global $hChromePath, $hGetChromePath, $hChromeSource, $hCheckUpdate
Global $hChannel, $hx86, $hUpdateInterval, $hLatestChromeVer, $hCurrentVer, $hUserDataDir, $hCopyData, $hUrlList
Global $hAppUpdate, $hCacheDir, $hSelectCacheDir, $hCacheSize
Global $hParams, $hDownloadThreads, $hProxyType, $hProxySever, $hProxyPort, $hMapHost, $hUseInetEx
Global $hRunInBackground, $hExApp, $hExAppAutoExit, $hExApp2

Global $ChromeFileVersion, $ChromeLastChange, $LatestChromeVer, $LatestChromeUrls, $SelectedUrl
Global $DefaultChromeDir, $DefaultChromeVer, $DefaultUserDataDir
Global $TrayTipProgress = 0
Global $iThreadPid, $DownloadThreads
;~ Global $aDlInfo[6]
;~ 0 - Latest Chrome Version / Bytes read so far
;~ 1 - Latest Chrome url / The size of the download
;~ 2 - Set to True if the download is complete, False if the download is still ongoing.
;~ 3 - True if successful.
;~ 4 - The error value for the download.
;~ 5 - status info
Global $hEvent, $ClientKey, $Progid
Global $aREG[6][3] = [[$HKEY_CURRENT_USER, 'Software\Clients\StartMenuInternet'], _
		[$HKEY_LOCAL_MACHINE, 'Software\Clients\StartMenuInternet'], _
		[$HKEY_CLASSES_ROOT, 'ftp'], _
		[$HKEY_CLASSES_ROOT, 'http'], _
		[$HKEY_CLASSES_ROOT, 'https'], _
		[$HKEY_CLASSES_ROOT, '']] ; ChromeHTML.XXX
Global $aFileAsso[6] = [".htm", ".html", ".shtml", ".webp", ".xht", ".xhtml"]
Global $aUrlAsso[13] = ["ftp", "http", "https", "irc", "mailto", "mms", "news", "nntp", "sms", "smsto", "tel", "urn", "webcal"]

FileChangeDir(@ScriptDir)
$AppName = StringRegExpReplace(@ScriptName, "\.[^.]*$", "")
$inifile = @ScriptDir & "\" & $AppName & ".ini"

Global $EnvID = RegRead('HKLM64\SOFTWARE\Microsoft\Cryptography', 'MachineGuid')
$EnvID &= RegRead("HKLM64\SOFTWARE\Microsoft\Windows NT\CurrentVersion", "InstallDate")
$EnvID &= DriveGetSerial(@HomeDrive & "\")
$EnvID = StringTrimLeft(_WinAPI_HashString($EnvID, 0, 16), 2)

If Not FileExists($inifile) Then
	$FirstRun = 1
	IniWrite($inifile, "Settings", "AppVersion", $AppVersion)
	IniWrite($inifile, "Settings", "ChromePath", ".\Chrome\chrome.exe")
	IniWrite($inifile, "Settings", "UserDataDir", ".\User Data")
	IniWrite($inifile, "Settings", "CacheDir", "")
	IniWrite($inifile, "Settings", "CacheSize", 0)
	IniWrite($inifile, "Settings", "Channel", "Stable")
	IniWrite($inifile, "Settings", "x86", 0)
	IniWrite($inifile, "Settings", "LastCheckUpdate", "2015/01/01 00:00:00")
	IniWrite($inifile, "Settings", "UpdateInterval", 24)
	IniWrite($inifile, "Settings", "ProxyType", "HTTP")
	IniWrite($inifile, "Settings", "UpdateProxy", "google.com")
	IniWrite($inifile, "Settings", "UpdatePort", 80)
	IniWrite($inifile, "Settings", "DownloadThreads", 3)
	IniWrite($inifile, "Settings", "Params", "")
	IniWrite($inifile, "Settings", "RunInBackground", 1)
	IniWrite($inifile, "Settings", "AppUpdate", 1) ; 0 - 不检查更新，1 - 有更新时通知我
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", "2015/01/01 00:00:00")
	IniWrite($inifile, "Settings", "CheckDefaultBrowser", 1)
	IniWrite($inifile, "Settings", "ExApp", "")
	IniWrite($inifile, "Settings", "ExAppAutoExit", 1)
	IniWrite($inifile, "Settings", "ExApp2", "")
	; IPLookup
	IniWrite($inifile, "IPLookup", "google_com", "")
	IniWrite($inifile, "IPLookup", "pid", 0)
	IniWrite($inifile, "IPLookup", "exe", ".\inet.exe")
	IniWrite($inifile, "IPLookup", "UseInetEx", 0)
	IniWrite($inifile, "IPLookup", "LastRun", "2015/01/01 00:00:00")
	IniWrite($inifile, "IPLookup", "maphost", 1)
	IniWrite($inifile, "IPLookup", "GIP", "")
	IniWrite($inifile, "IPLookup", "GIPSource", "")
EndIf

#Region ========= Deal with old MyChrome =========
If $AppVersion <> IniRead($inifile, "Settings", "AppVersion", "") Then
	$FirstRun = 1
	IniWrite($inifile, "Settings", "AppVersion", $AppVersion)
	$arr = IniReadSection($inifile, "IPLookup")
	If @error Then
		IniWrite($inifile, "IPLookup", "google_com", "")
		IniWrite($inifile, "IPLookup", "UseInetEx", 0)
		IniWrite($inifile, "IPLookup", "exe", ".\inet.exe")
		IniWrite($inifile, "IPLookup", "maphost", 1)
	EndIf
EndIf
#EndRegion ========= Deal with old MyChrome =========

;~ read ini info
$ChromePath = IniRead($inifile, "Settings", "ChromePath", ".\Chrome\chrome.exe")
$UserDataDir = IniRead($inifile, "Settings", "UserDataDir", ".\User Data")
$CacheDir = IniRead($inifile, "Settings", "CacheDir", "")
$CacheSize = IniRead($inifile, "Settings", "CacheSize", 0) * 1
$Channel = IniRead($inifile, "Settings", "Channel", "Stable")
$x86 = IniRead($inifile, "Settings", "x86", 0) * 1
$LastCheckUpdate = IniRead($inifile, "Settings", "LastCheckUpdate", "2015/01/01 00:00:00")
$UpdateInterval = IniRead($inifile, "Settings", "UpdateInterval", 24) * 1
$ProxyType = IniRead($inifile, "Settings", "ProxyType", "HTTP")
$ProxySever = IniRead($inifile, "Settings", "UpdateProxy", "google.com")
$ProxyPort = IniRead($inifile, "Settings", "UpdatePort", 80) * 1
$DownloadThreads = IniRead($inifile, "Settings", "DownloadThreads", 3) * 1
$Params = IniRead($inifile, "Settings", "Params", "")
$RunInBackground = IniRead($inifile, "Settings", "RunInBackground", 1) * 1
$AppUpdate = IniRead($inifile, "Settings", "AppUpdate", 1) * 1
$AppUpdateLastCheck = IniRead($inifile, "Settings", "AppUpdateLastCheck", "2015/01/01 00:00:00")
$CheckDefaultBrowser = IniRead($inifile, "Settings", "CheckDefaultBrowser", 1) * 1
$ExApp = IniRead($inifile, "Settings", "ExApp", "")
$ExAppAutoExit = IniRead($inifile, "Settings", "ExAppAutoExit", 1) * 1
$ExApp2 = IniRead($inifile, "Settings", "ExApp2", "")
$Inet = IniRead($inifile, "IPLookup", "exe", ".\inet.exe")
$UseInetEx = IniRead($inifile, "IPLookup", "UseInetEx", "")
$IPLookupLastRun = IniRead($inifile, "IPLookup", "LastRun", "2015/01/01 00:00:00")
$maphost = IniRead($inifile, "IPLookup", "maphost", 1) * 1

$UseInetEx = (FileExists($Inet) And $UseInetEx <> "0") * 1
If Not $UseInetEx Then
	$Inet = @ScriptFullPath
EndIf

Opt("ExpandEnvStrings", 1)
EnvSet("APP", @ScriptDir)
;~ 第一个启动参数为“-set”，或第一次运行，Chrome.exe、用户数据文件夹不存在，则显示设置窗口
If ($cmdline[0] = 1 And $cmdline[1] = "-set") Or $FirstRun Or Not FileExists($ChromePath) Or Not FileExists($UserDataDir) Then
	CreateSettingsShortcut(@ScriptDir & "\" & $AppName & ".vbs")
	Settings()
EndIf

$ChromePath = FullPath($ChromePath)
SplitPath($ChromePath, $ChromeDir, $ChromeExe)
$UserDataDir = FullPath($UserDataDir)

If IsAdmin() And $cmdline[0] = 1 And $cmdline[1] = "-SetDefaultGlobal" Then
	CheckDefaultBrowser($ChromePath)
	Exit
EndIf

CheckEnv()

;~ write file First Run to prevent chrome from generating shortcut on desktop
If Not FileExists($ChromeDir & "\First Run") Then FileWrite($ChromeDir & "\First Run", "")

; quote external cmdline.
For $i = 1 To $cmdline[0]
	If StringInStr($cmdline[$i], " ") Then
		$Params &= ' "' & $cmdline[$i] & '"'
	Else
		$Params &= ' ' & $cmdline[$i]
	EndIf
Next
;~ $PortableParam = '--no-default-browser-check'
$PortableParam = '--user-data-dir="' & $UserDataDir & '"'
If $CacheDir <> "" Then
	$CacheDir = FullPath($CacheDir)
	$PortableParam &= ' --disk-cache-dir="' & $CacheDir & '"'
EndIf
If $CacheSize <> 0 Then
	$PortableParam &= ' --disk-cache-size=' & $CacheSize
EndIf

If $UseInetEx And $ProxyType == "HTTP" And $ProxySever = "google.com" And $maphost Then
	$google_com = IniRead($inifile, "IPLookup", "google_com", "")
	$arr = IniReadSection($inifile, "HostMap")
	If @error Then
		Local $arr[12][2] = [[11, ""], _
				["*.google.com", "google_com"], _
				["*.google.cn", "google_com"], _
				["*.google.com.hk", "google_com"], _
				["*.googleusercontent.com", ""], _
				["*.google-analytics.com", ""], _
				["*.googlevideo.com", ""], _
				["*.googleapis.com", ""], _
				["*.googlesource.com", ""], _
				["*.ggpht.com", ""], _
				["*.gstatic.com", ""], _
				["*.doubleclick.net", ""]]
		IniWriteSection($inifile, "HostMap", $arr)
	Else
		$arr[0][0] = "google_com"
		$arr[0][1] = $google_com
		$arr = ArrayHost2IP($arr)
		$var = ""
		For $i = 1 To UBound($arr) - 1 ; ignore google_com
			If $arr[$i][1] <> "" Then
				$var &= "," & $arr[$i][0] & " " & $arr[$i][1]
			EndIf
		Next
		$var = StringTrimLeft($var, 1)
		$PortableParam &= ' --host-resolver-rules="MAP ' & $var & '"'
	EndIf
EndIf

Local $ChromeIsRunning = AppIsRunning($ChromePath)
If Not $ChromeIsRunning And FileExists($ChromeDir & "\~updated") Then
	ApplyUpdate()
EndIf

; start chrome
$AppPID = Run('"' & $ChromePath & '" ' & $PortableParam & ' ' & $Params, $ChromeDir)

FileChangeDir(@ScriptDir)
CreateSettingsShortcut(@ScriptDir & "\" & $AppName & ".vbs")

; check if another instance of mychrome is running
$list = ProcessList(StringRegExpReplace(@AutoItExe, ".*\\", ""))
For $i = 1 To $list[0][0]
	If $list[$i][1] <> @AutoItPID And GetProcPath($list[$i][1]) = @AutoItExe Then
		Exit ;exit if another instance of mychrome is running
	EndIf
Next

; Start external apps
If $ExApp <> "" Then
	$aExApp = StringSplit($ExApp, "||", 1)
	ReDim $aExAppPID[$aExApp[0] + 1]
	$aExAppPID[0] = $aExApp[0]
	For $i = 1 To $aExApp[0]
		$match = StringRegExp($aExApp[$i], '^"(.*?)" *(.*)', 1)
		If @error Then
			$file = $aExApp[$i]
			$args = ""
		Else
			$file = $match[0]
			$args = $match[1]
		EndIf
		$file = FullPath($file)
		$aExAppPID[$i] = ProcessExists(StringRegExpReplace($file, '.*\\', ''))
		If Not $aExAppPID[$i] And FileExists($file) Then
			$aExAppPID[$i] = ShellExecute($file, $args, StringRegExpReplace($file, '\\[^\\]+$', ''))
		EndIf
	Next
EndIf

If $CheckDefaultBrowser Then
	CheckDefaultBrowser($ChromePath)
EndIf

If FileExists($TaskBarDir) Then
	CheckPinnedPrograms($ChromePath)
EndIf

Global $FirstUpdateCheck = 1
If Not $RunInBackground Then
	UpdateCheck()
	Exit
EndIf
; ========================= app ended if not run in background ================================


If $CheckDefaultBrowser Then ; register REG for notification
	$hEvent = _WinAPI_CreateEvent()
	For $i = 0 To UBound($aREG) - 1
		If $aREG[$i][1] Then
			$aREG[$i][2] = _WinAPI_RegOpenKey($aREG[$i][0], $aREG[$i][1], $KEY_NOTIFY)
			If $aREG[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($aREG[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
			EndIf
		EndIf
	Next
EndIf
OnAutoItExitRegister("OnExit")
AdlibRegister("UpdateCheck", 10000)

WinWait("[REGEXPCLASS:(?i)Chrome]", "", 15)
$hWnd = GethWndbyPID($AppPID, "Chrome")

ReduceMemory()

; wait for chrome exit
$AppIsRunning = True
While 1
	Sleep(500)

	If $hWnd Then
		If Not WinExists($hWnd) Then
			$AppIsRunning = False
		EndIf
	Else ; ProcessExists() is resource consuming than WinExists()
		If Not ProcessExists($AppPID) Then
			$AppIsRunning = False
		EndIf
	EndIf

	If Not $AppIsRunning Then
		; check other chrome instance
		$AppPID = AppIsRunning($ChromePath)
		If Not $AppPID Then
			ExitLoop
		EndIf
		$AppIsRunning = True
		$hWnd = GethWndbyPID($AppPID, "Chrome")
	EndIf

	If $TaskBarLastChange Then
		CheckPinnedPrograms($ChromePath)
	EndIf

	If $hEvent And Not _WinAPI_WaitForSingleObject($hEvent, 0) Then
		; MsgBox(0, "", "Reg changed!")
		Sleep(50)
		CheckDefaultBrowser($ChromePath)
		For $i = 0 To UBound($aREG) - 1
			If $aREG[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($aREG[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
			EndIf
		Next
	EndIf
WEnd

If $ExAppAutoExit And $ExApp <> "" Then
	$cmd = ''
	For $i = 1 To $aExAppPID[0]
		If Not $aExAppPID[$i] Then ContinueLoop
		$cmd &= ' /PID ' & $aExAppPID[$i]
	Next
	If $cmd Then
		$cmd = 'taskkill' & $cmd & ' /T /F'
		Run(@ComSpec & ' /c ' & $cmd, '', @SW_HIDE)
	EndIf
EndIf

; Start external apps
If $ExApp2 <> "" Then
	$aExApp2 = StringSplit($ExApp2, "||", 1)
	For $i = 1 To $aExApp2[0]
		$match = StringRegExp($aExApp2[$i], '^"(.*?)" *(.*)', 1)
		If @error Then
			$file = $aExApp2[$i]
			$args = ""
		Else
			$file = $match[0]
			$args = $match[1]
		EndIf
		$file = FullPath($file)
		If Not ProcessExists(StringRegExpReplace($file, '.*\\', '')) Then
			If FileExists($file) Then
				ShellExecute($file, $args, StringRegExpReplace($file, '\\[^\\]+$', ''))
			EndIf
		EndIf
	Next
EndIf

If 0 Then ; ========= Lines below will never be executed =========
	; put functions here to prevent these functions from being stripped
	get_latest_chrome_ver("Stable")
	download_chrome("", "")
EndIf ; ============= Lines above will never be executed =========
Exit

; ==================== auto-exec codes ends ========================

Func GethWndbyPID($pid, $title = "")
	$list = WinList("[REGEXPCLASS:(?i)" & $title & "]")
	For $i = 1 To $list[0][0]
		If $pid = WinGetProcess($list[$i][1]) Then
			Return $list[$i][1]
		EndIf
	Next
EndFunc   ;==>GethWndbyPID

Func ArrayHost2IP($arr)
	For $i = 0 To UBound($arr) - 1
		If StringRegExp($arr[$i][1], "^[\d\.\|]+$") Then
			If StringInStr($arr[$i][1], "|") Then
				$a = StringSplit($arr[$i][1], "|", 2)
				$arr[$i][1] = $a[0]
			EndIf
		Else
			$arr[$i][1] = ArraySerachIP($arr, $arr[$i][1])
		EndIf
	Next
	Return $arr
EndFunc   ;==>ArrayHost2IP
Func ArraySerachIP($arr, $host)
	For $i = 0 To UBound($arr) - 1
		If $arr[$i][0] = $host Then
			If $arr[$i][1] = "" Then
				Return ""
			ElseIf StringRegExp($arr[$i][1], "^[\d\.\|]+$") Then
				$a = StringSplit($arr[$i][1], "|", 2)
				Return $a[0]
			Else
				Return ArraySerachIP($arr, $arr[$i][1])
			EndIf
		EndIf
	Next
	Return ""
EndFunc   ;==>ArraySerachIP

Func GetChromeLastChange($path)
	; chrome "LastChange"  changed from digits as 312162 to commit hashes
	; chrome release : 800fe26985bd6fd8626dd80f710fae8ac527bd6b-refs/branch-heads/2171@{#470}
	; chromium : 32cbfaa6478f66b93b6d383a58f606960e02441e-refs/heads/master@{#312162}
	Local $match = StringRegExp(FileGetVersion($path, "LastChange"), '(\d{6,})\D*$', 1)
	If Not @error Then Return $match[0]
	Return ""
EndFunc   ;==>GetChromeLastChange

Func CheckEnv()
	Local $oldstr, $var, $EnvString, $variations_seed, $variations_seed_signature
	$EnvString = FileRead($UserDataDir & "\EnvId")
	If $EnvString = $EnvID Then Return
	FileDelete($UserDataDir & "\EnvId")

	If FileExists($UserDataDir & "\Local State") Then
		$EnvString = FileWrite($UserDataDir & "\EnvId", $EnvID)
		FileInstall(".\Local State.MyChrome", $UserDataDir & "\Local State.MyChrome", 1)
		$var = FileRead($UserDataDir & "\Local State.MyChrome")
		FileDelete($UserDataDir & "\Local State.MyChrome")
		Local $match = StringRegExp($var, '(?i)("variations.*_seed": *"\S+?")', 1)
		If Not @error Then $variations_seed = $match[0]
		$match = StringRegExp($var, '(?i)("variations_seed_signature": *"\S+?")', 1)
		If Not @error Then $variations_seed_signature = $match[0]
		$oldstr = FileRead($UserDataDir & "\Local State")
		$var = StringRegExpReplace($oldstr, '(?i)"variations.*_seed": *"\S+?"', $variations_seed)
		If Not @error Then
			$var = StringRegExpReplace($var, '(?i)"variations_seed_signature": *"\S+?"', $variations_seed_signature)
			If $var <> $oldstr Then
				Local $file = FileOpen($UserDataDir & "\Local State", 2 + 256)
				FileWrite($file, $var)
				FileClose($file)
			EndIf
		EndIf
	EndIf
EndFunc   ;==>CheckEnv

Func OnExit()
	If $hEvent Then
		_WinAPI_CloseHandle($hEvent)
		For $i = 0 To UBound($aREG) - 1
			_WinAPI_RegCloseKey($aREG[$i][2])
		Next
	EndIf
EndFunc   ;==>OnExit

Func RunIPlookup()
	Local $pid = IniRead($inifile, "IPLookup", "pid", 0)
	If Not ProcessExists(StringRegExpReplace($Inet, '.*\\', '')) Or Not ProcessExists($pid) Then
		Local $pid = ShellExecute($Inet, '"' & $inifile & '"', @ScriptDir, "open", @SW_HIDE)
		$IPLookupLastRun = _NowCalc()
		IniWrite($inifile, "IPLookup", "LastRun", $IPLookupLastRun)
		IniWrite($inifile, "IPLookup", "pid", $pid)
	EndIf
EndFunc   ;==>RunIPlookup

Func UpdateCheck()
	Local $updated, $var
	If $UseInetEx And $ProxyType == "HTTP" And $ProxySever = "google.com" And _DateDiff("h", $IPLookupLastRun, _NowCalc()) >= 1 Then
		If FileExists($Inet) Then
			RunIPlookup()
		EndIf
	EndIf

	; Check mychrome update
	If $AppUpdate <> 0 And _DateDiff("h", $AppUpdateLastCheck, _NowCalc()) >= 24 Then
		If $UseInetEx Then
			CheckAppUpdate($Inet)
		Else
			CheckAppUpdate()
		EndIf
	EndIf
	; check chrome update
	If $UpdateInterval >= 0 Then
		If $UpdateInterval = 0 Then
			If $FirstUpdateCheck Then
				$updated = UpdateChrome($ChromePath, $Channel)
			EndIf
		Else
			Local $var = _DateDiff("h", $LastCheckUpdate, _NowCalc())
			If $var >= $UpdateInterval Then
				$updated = UpdateChrome($ChromePath, $Channel)
			EndIf
		EndIf
		If $updated And Not AppIsRunning($ChromePath) Then ; restart app/chrome
			If @Compiled Then
				Run('"' & @AutoItExe & '" --restore-last-session')
			Else
				Run('"' & @AutoItExe & '" "' & @ScriptFullPath & '" --restore-last-session')
			EndIf
			Exit
		EndIf
	EndIf

	If $RunInBackground Then
		If $FirstUpdateCheck Then
			AdlibRegister("UpdateCheck", 300000)
		EndIf
		ReduceMemory()
	EndIf
	$FirstUpdateCheck = 0
EndFunc   ;==>UpdateCheck

;~ for win7/vista or newer
Func CheckPinnedPrograms($path)
	If Not FileExists($TaskBarDir) Then
		Return
	EndIf
	Local $ftime = FileGetTime($TaskBarDir, 0, 1)
	If $ftime = $TaskBarLastChange Then
		Return
	EndIf

	$TaskBarLastChange = $ftime
	Local $search = FileFindFirstFile($TaskBarDir & "\*.lnk")
	If $search = -1 Then Return
	Local $file, $ShellObj, $objShortcut
	$ShellObj = ObjCreate("WScript.Shell")
	If Not @error Then
		While 1
			$file = $TaskBarDir & "\" & FileFindNextFile($search)
			If @error Then ExitLoop
			$objShortcut = $ShellObj.CreateShortCut($file)
			If $path = $objShortcut.TargetPath Then
				$objShortcut.TargetPath = @ScriptFullPath
				$objShortcut.IconLocation = $path & ",0"
				$objShortcut.Save
				$TaskBarLastChange = FileGetTime($TaskBarDir, 0, 1)
				ExitLoop
			EndIf
		WEnd
		$objShortcut = ""
	EndIf
	FileClose($search)
EndFunc   ;==>CheckPinnedPrograms

Func CreateSettingsShortcut($fname)
	Local $var = FileRead($fname)
	If $var <> 'CreateObject("shell.application").ShellExecute "' & @ScriptName & '", "-set"' Then
		FileDelete($fname)
		FileWrite($fname, 'CreateObject("shell.application").ShellExecute "' & @ScriptName & '", "-set"')
	EndIf
EndFunc   ;==>CreateSettingsShortcut


Func CheckDefaultBrowser($BrowserPath)
	Local $InternetClient, $key, $i, $j, $var, $RegWriteError = 0

	; 在 StartMenuInternet 中注册后，Win XP 中点击开始菜单的“Internet”项才会启动chrome便携版
	; Win vista / 7 “默认程序” 设置中才会出现Chrome浏览器
	If Not $ClientKey Then
		Local $aRoot[3] = ["HKCU", "HKLM64", "HKLM"]
		For $i = 0 To 2 ; search chrome in internetclient
			$j = 1
			While 1
				$InternetClient = RegEnumKey($aRoot[$i] & "\Software\Clients\StartMenuInternet", $j)
				If @error <> 0 Then ExitLoop
				$key = $aRoot[$i] & '\SOFTWARE\Clients\StartMenuInternet\' & $InternetClient
				$var = RegRead($key & '\DefaultIcon', '')
				If StringInStr($var, $BrowserPath) Then
					$ClientKey = $key
					$Progid = RegRead($ClientKey & '\Capabilities\URLAssociations', 'http')
					ExitLoop 2
				EndIf
				$j += 1
			WEnd
		Next
	EndIf
	If $ClientKey Then
		$var = RegRead($ClientKey & '\shell\open\command', '')
		If Not StringInStr($var, @ScriptFullPath) Then
			$RegWriteError += Not RegWrite($ClientKey & '\shell\open\command', _
					'', 'REG_SZ', '"' & @ScriptFullPath & '"')
		EndIf
	EndIf

	If Not $Progid Then
		$Progid = FindChromeProgid($BrowserPath)
	EndIf

	If $Progid Then
		$var = RegRead('HKCR\' & $Progid & '\shell\open\command', '')
		If Not StringInStr($var, @ScriptFullPath) Then
			RegWrite('HKCR\' & $Progid & '\shell\open\ddeexec', '', 'REG_SZ', '')
			RegDelete('HKCR\' & $Progid & '\shell\open\command', 'DelegateExecute') ; 解决 Win8“未注册类”错误
			$RegWriteError += Not RegWrite('HKCR\' & $Progid & '\shell\open\command', _
					'', 'REG_SZ', '"' & @ScriptFullPath & '" -- "%1"')
		EndIf
		If Not $aREG[5][1] Then
			$aREG[5][1] = $Progid ; for reg notification
			$aREG[5][2] = _WinAPI_RegOpenKey($aREG[5][0], $aREG[5][1], $KEY_NOTIFY)
		EndIf
	EndIf

	Local $aAsso[3] = ['ftp', 'http', 'https']
	For $i = 0 To 2
		$var = RegRead('HKCR\' & $aAsso[$i] & '\DefaultIcon', '')
		If StringInStr($var, $BrowserPath) Then
			$var = RegRead('HKCR\' & $aAsso[$i] & '\shell\open\command', '')
			If Not StringInStr($var, @ScriptFullPath) Then
				RegWrite('HKCR\' & $aAsso[$i] & '\shell\open\ddeexec', '', 'REG_SZ', '')
				RegDelete('HKCR\' & $aAsso[$i] & '\shell\open\command', 'DelegateExecute')
				$RegWriteError += Not RegWrite('HKCR\' & $aAsso[$i] & '\shell\open\command', _
						'', 'REG_SZ', '"' & @ScriptFullPath & '" -- "%1"')
			EndIf
		EndIf
	Next

	If IsAdmin() Then
		RegRead('HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe', '')
		If Not @error Then
			RegWrite('HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe', '', 'REG_SZ', @ScriptFullPath)
			RegWrite('HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe', 'Path', 'REG_SZ', @ScriptDir)
		EndIf
	EndIf

	If $RegWriteError And Not _IsUACAdmin() And @extended Then
		If @Compiled Then
			ShellExecute(@ScriptName, "-SetDefaultGlobal", @ScriptDir, "runas")
		Else
			ShellExecute(@AutoItExe, '"' & @ScriptFullPath & '" -SetDefaultGlobal', @ScriptDir, "runas")
		EndIf
	EndIf
EndFunc   ;==>CheckDefaultBrowser
Func FindChromeProgid($BrowserPath)
	Local $i, $id, $var
	RegRead('HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts', '')
	If @error <> 1 Then
		For $i = 0 To UBound($aFileAsso) - 1
			$id = RegRead('HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\' & $aFileAsso[$i] & '\UserChoice', 'Progid')
			If $id Then
				$var = RegRead('HKCR\' & $id & '\DefaultIcon', '')
				If StringInStr($var, $BrowserPath) Then
					Return $id
				EndIf
			EndIf
		Next
	EndIf

	For $i = 0 To UBound($aFileAsso) - 1
		$id = RegRead('HKCR\' & $aFileAsso[$i], '')
		$var = RegRead('HKCR\' & $id & '\DefaultIcon', '')
		If StringInStr($var, $BrowserPath) Then
			Return $id
		EndIf
	Next

	RegRead('HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations', '')
	If @error <> 1 Then
		For $i = 0 To UBound($aUrlAsso) - 1
			$id = RegRead('HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\' & $aUrlAsso[$i] & '\UserChoice', 'Progid')
			If $id Then
				$var = RegRead('HKCR\' & $id & '\DefaultIcon', '')
				If StringInStr($var, $BrowserPath) Then
					Return $id
				EndIf
			EndIf
		Next
	EndIf
	Return ""
EndFunc   ;==>FindChromeProgid


;~ check MyChrome update
Func CheckAppUpdate($InetPath = "")
	Local $UpdateInfo, $match, $LatestAppVer, $msg, $update, $url, $updated
	Local $slatest = "latest", $surl = "url", $supdate = "update"
	Local $sinet_latest = "inet_latest", $sinet_url = "inet_url", $sinet_update = "inet_update"
	If @AutoItX64 Then
		$slatest &= "_x64"
		$surl &= "_x64"
		$supdate &= "_x64"

		$sinet_latest &= "_x64"
		$sinet_url &= "_x64"
		$sinet_update &= "_x64"
	EndIf
	$AppUpdateLastCheck = _NowCalc()
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", $AppUpdateLastCheck)

	HttpSetProxy(0) ; Use IE defaults for proxy
	$UpdateInfo = BinaryToString(InetRead("http://code.taobao.org/svn/mychrome/trunk/Update.txt", 27), 4)
	$UpdateInfo = StringStripWS($UpdateInfo, 3)
	;ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $UpdateInfo = ' & $UpdateInfo & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console
	$match = StringRegExp($UpdateInfo, '(?ism)^\W*' & $slatest & '=(\N+)$.*^\W*' & _
			$surl & '=(\N+)$.*^\W*' & _
			$supdate & '=(\N*)$', 1)
	If Not @error Then
		$LatestAppVer = $match[0]
		$url = $match[1]
		$update = StringReplace($match[2], "\n", @CRLF)
		If VersionCompare($LatestAppVer, $AppVersion) > 0 Then
			If IsHWnd($hSettings) Then
				$msg = 6
			Else
				$msg = MsgBox(68, 'MyChrome', 'MyChrome 可以更新，是否立即下载？' & @CRLF & @CRLF & _
						'您的版本：' & $AppVersion & '，' & '最新版本：' & $LatestAppVer & @CRLF & @CRLF & $update)
			EndIf
			If $msg == 6 Then
				$updated = UpdateApp("MyChrome", @ScriptFullPath, $url)
				If $updated == 1 Then
					MsgBox(64, "MyChrome", "MyChrome 已更新至 " & $LatestAppVer & " ！")
				ElseIf $updated == 0 Then
					$msg = MsgBox(20, "MyChrome", "MyChrome 自动更新失败！" & @CRLF & @CRLF & "是否去软件发布页手动下载？")
					If $msg = 6 Then ; Yes
						OpenWebsite()
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	If $InetPath Then
		Local $InetVer = FileGetVersion($InetPath)
		$match = StringRegExp($UpdateInfo, '(?ism)^\W*' & $sinet_latest & '=(\N+)$.*^\W*' & _
				$sinet_url & '=(\N+)$.*^\W*' & _
				$sinet_update & '=(\N*)$', 1)
		If Not @error Then
			$LatestAppVer = $match[0]
			$url = $match[1]
			$update = StringReplace($match[2], "\n", @CRLF)
			If VersionCompare($LatestAppVer, $InetVer) > 0 Then
				If $updated Or IsHWnd($hSettings) Then
					$msg = 6
				Else
					$msg = MsgBox(68, 'MyChrome', '网络增强插件 inet 可以更新，是否立即下载？' & @CRLF & @CRLF & _
							'您的版本：' & $InetVer & '，' & '最新版本：' & $LatestAppVer & @CRLF & @CRLF & $update)
				EndIf
				If $msg == 6 Then
					$updated = UpdateApp("Inet", $InetPath, $url)
					If $updated == 1 Then
						MsgBox(64, "MyChrome", "网络增强插件 inet 已更新至 " & $LatestAppVer & " ！")
					ElseIf $updated == 0 Then
						$msg = MsgBox(20, "MyChrome", "网络增强插件 inet 自动更新失败！" & @CRLF & @CRLF & "是否去软件发布页手动下载？")
						If $msg = 6 Then ; Yes
							OpenWebsite()
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	Return $updated
EndFunc   ;==>CheckAppUpdate
Func UpdateApp($App = "MyChrome", $exe = @ScriptFullPath, $url = "")
	Local $temp = @ScriptDir & "\MyChrome_temp"
	Local $file = $temp & "\" & $App & ".7z"
	Local $iBytesSize, $updated = 0
	If Not FileExists($temp) Then DirCreate($temp)
	Local $hDownload = InetGet($url, $file, 19, 1)

	TraySetState(1)
	TraySetClick(8)
	TraySetToolTip("MyChrome")
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "TrayTipProgress")
	Local $iCancel = TrayCreateItem("取消下载 ...")
	TrayItemSetOnEvent(-1, "CancelAppUpdate")
	TrayTip("开始下载 " & $App, "点击图标可查看下载进度", 10, 1)
	$CancelAppUpdate = False

	Do
		Sleep(250)
		If $CancelAppUpdate Then
			$updated = -1
			_GUICtrlStatusBar_SetText($hStausbar, $App & " 更新已取消")
			ExitLoop
		EndIf
		$iBytesSize = InetGetInfo($hDownload, $INET_DOWNLOADREAD) / 1024
		$iBytesSize = StringFormat('%.1f', $iBytesSize)
		If IsHWnd($hSettings) Then
			_GUICtrlStatusBar_SetText($hStausbar, "正在下载 " & $App & ":  " & $iBytesSize & " KB")
		EndIf
		If $TrayTipProgress Or TrayTipExists("下载 " & $App) Then
			TrayTip("", "下载 " & $App & ":  " & $iBytesSize & " KB", 10, 1)
			$TrayTipProgress = 0
		EndIf
	Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
	InetClose($hDownload)
	FileSetAttrib($file, "+A")
	If Not $CancelAppUpdate Then
		FileInstall("7zr.exe", $temp & "\7zr.exe", 1) ; http://www.7-zip.org/download.html
		RunWait($temp & '\7zr.exe x "' & $file & '" -y', $temp, @SW_HIDE)
		If FileExists($temp & "\" & $App & ".exe") Then
			If FileExists($exe) Then
				FileMove($exe, $exe & ".bak", 9)
			EndIf
			FileMove($temp & "\" & $App & ".exe", $exe, 9)
			FileDelete($temp & "\7zr.exe")
			FileDelete($file)
			DirCopy($temp, @ScriptDir, 1)
			$updated = 1
		EndIf
	EndIf

	TrayItemDelete($iCancel)
	TraySetState(2)
	$CancelAppUpdate = False
	DirRemove($temp, 1)
	Return $updated
EndFunc   ;==>UpdateApp
Func CancelAppUpdate()
	$CancelAppUpdate = True
EndFunc   ;==>CancelAppUpdate

;~ 显示设置窗口
Func Settings()
	SplitPath($ChromePath, $ChromeDir, $ChromeExe)
	Switch $UpdateInterval
		Case -1
			$UpdateInterval = "从不"
		Case 168
			$UpdateInterval = "每周"
		Case 24
			$UpdateInterval = "每天"
		Case 1
			$UpdateInterval = "每小时"
		Case Else
			$UpdateInterval = "每次启动时"
	EndSwitch
	$ChromeFileVersion = FileGetVersion($ChromeDir & "\chrome.dll", "FileVersion")
	$ChromeLastChange = GetChromeLastChange($ChromeDir & "\chrome.dll")

	Opt("ExpandEnvStrings", 0)
	$hSettings = GUICreate("MyChrome - 打造自己的 Google Chrome 便携版", 500, 520)
	GUISetOnEvent($GUI_EVENT_CLOSE, "ExitApp")
	GUICtrlCreateLabel("MyChrome " & $AppVersion & " by 甲壳虫 <jdchenjian@gmail.com>", 5, 10, 490, -1, $SS_CENTER)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetTip(-1, "点击打开 MyChrome 主页")
	GUICtrlSetOnEvent(-1, "OpenWebsite")

	;常规
	GUICtrlCreateTab(5, 35, 492, 410)
	GUICtrlCreateTabItem("常规")

	GUICtrlCreateGroup("Google Chrome 程序文件", 10, 80, 480, 180)
	GUICtrlCreateLabel("chrome 路径：", 20, 110, 120, 20)
	$hChromePath = GUICtrlCreateEdit($ChromePath, 130, 106, 290, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, "浏览器主程序路径")
	$hGetChromePath = GUICtrlCreateButton("浏览", 430, 106, 50, 20)
	GUICtrlSetTip(-1, "选择便携版浏览器" & @CRLF & "主程序（chrome.exe）")
	GUICtrlSetOnEvent(-1, "GUI_GetChromePath")

	GUICtrlCreateLabel("获取 Google Chrome 浏览器程序文件：", 20, 144, 250, 20)
	$hChromeSource = GUICtrlCreateCombo("", 280, 140, 200, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData(-1, "----  请选择  ----|从系统中提取|从网络下载|从离线安装文件提取", "----  请选择  ----")
	GUICtrlSetTip(-1, "获取便携版浏览器程序文件")
	GUICtrlSetOnEvent(-1, "GUI_GetChrome")

	GUICtrlCreateLabel("分支：", 20, 174, 80, 20)
	$hChannel = GUICtrlCreateCombo("", 130, 170, 130, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData(-1, "Stable|Beta|Dev|Canary|Chromium-Continuous|Chromium-Snapshots", $Channel)
	GUICtrlSetTip(-1, "Stable - 稳定版(正式版)" & @CRLF & "Beta - 测试版" & @CRLF & "Dev - 开发版" & @CRLF & _
			"Canary - 金丝雀版" & @CRLF & "Chromium - 更新快但不稳定")
	GUICtrlSetOnEvent(-1, "GUI_CheckChrome")

	$hx86 = GUICtrlCreateCheckbox("只下载 32 位浏览器（x86）", 20, 200, -1, 20)
	GUICtrlSetTip(-1, "勾选此项下载32位浏览器。")
	GUICtrlSetOnEvent(-1, "GUI_Eventx86")
	If $x86 Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateLabel("检查浏览器更新：", 20, 235, 110, 20)
	$hUpdateInterval = GUICtrlCreateCombo("", 130, 230, 130, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData(-1, "每次启动时|每小时|每天|每周|从不", $UpdateInterval)

	$hCheckUpdate = GUICtrlCreateButton("立即更新", 360, 170, 120, 24)
	GUICtrlSetTip(-1, "检查浏览器更新" & @CRLF & "下载最新版至 chrome 程序文件夹")
	GUICtrlSetOnEvent(-1, "GUI_Start_End_ChromeUpdate")

	GUICtrlCreateLabel("最新版本：", 280, 204, 70, 20)
	$hLatestChromeVer = GUICtrlCreateLabel("", 350, 204, 140, 20)
	GUICtrlSetTip(-1, "复制下载地址到剪贴板")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetOnEvent(-1, "GUI_ShowUrl")

	GUICtrlCreateLabel("当前版本：", 280, 235, 70, 20)
	$hCurrentVer = GUICtrlCreateLabel("", 350, 235, 140, 20)
	GUICtrlSetData(-1, $ChromeFileVersion & "  " & $ChromeLastChange)

	GUICtrlCreateGroup("Google Chrome 用户数据文件", 10, 280, 480, 80)
	GUICtrlCreateLabel("用户数据文件夹：", 20, 310, 110, 20)
	$hUserDataDir = GUICtrlCreateEdit($UserDataDir, 130, 305, 290, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, "浏览器用户数据文件夹")
	GUICtrlCreateButton("浏览", 430, 305, 50, 20)
	GUICtrlSetTip(-1, "选择用户数据文件夹")
	GUICtrlSetOnEvent(-1, "GUI_GetUserDataDir")
	$hCopyData = GUICtrlCreateCheckbox("从系统中提取用户数据文件", 20, 330, -1, 20)

	$hAppUpdate = GUICtrlCreateCheckbox("MyChrome 发布新版时通知我", 20, 380, -1, 20)
	If $AppUpdate Then
		GUICtrlSetState($hAppUpdate, $GUI_CHECKED)
	EndIf
	$hRunInBackground = GUICtrlCreateCheckbox("MyChrome 在后台运行直至浏览器退出", 20, 410, 400, 20)
	GUICtrlSetOnEvent(-1, "GUI_RunInBackground")
	If $RunInBackground Then
		GUICtrlSetState($hRunInBackground, $GUI_CHECKED)
	EndIf

	; 高级
	GUICtrlCreateTabItem("高级")
	GUICtrlCreateGroup("Google Chrome 缓存", 10, 80, 480, 90)
	GUICtrlCreateLabel("缓存位置：", 20, 110, 100, 20)
	$hCacheDir = GUICtrlCreateEdit($CacheDir, 120, 106, 300, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, "浏览器缓存位置" & @CRLF & "空白 = 默认路径" & @CRLF & "支持%TEMP%等环境变量")
	$hSelectCacheDir = GUICtrlCreateButton("浏览", 430, 106, 50, 20)
	GUICtrlSetTip(-1, "选择缓存位置")
	GUICtrlSetOnEvent(-1, "GUI_SelectCacheDir")
	GUICtrlCreateLabel("缓存大小：", 20, 140, 100, 20)
	$hCacheSize = GUICtrlCreateEdit(Round($CacheSize / 1024 / 1024), 120, 136, 80, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, "缓存大小" & @CRLF & "0 = 无限制")
	GUICtrlCreateLabel(" MB", 200, 140, 40, 20)

	; 启动参数
	GUICtrlCreateLabel("Google Chrome 启动参数", 20, 190)
	Local $lparams = StringReplace($Params, " --", Chr(13) & Chr(10) & "--") ; 空格换成换行符，便于显示
	$hParams = GUICtrlCreateEdit($lparams, 20, 210, 460, 60, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	GUICtrlSetTip(-1, "Chrome 启动参数，每行写一个参数。" & @CRLF & "支持%TEMP%等环境变量，" & @CRLF & "特别地，%APP%代表 MyChrome 所在目录。")

	; 线程数
	GUICtrlCreateGroup("网络设置", 10, 290, 480, 150)
	GUICtrlCreateLabel("下载线程数(1-10)：", 20, 320, 130, 20)
	$hDownloadThreads = GUICtrlCreateInput($DownloadThreads, 150, 316, 60, 20, $ES_NUMBER)
	GUICtrlSetTip(-1, "增减线程数可调节下载速度" & @CRLF & "仅适用于下载 chrome 更新")
	GUICtrlSetOnEvent(-1, "GUI_CheckThreadsNum")
	GUICtrlCreateUpdown($hDownloadThreads)
	GUICtrlSetLimit(-1, 10, 1)

	; 代理
	GUICtrlCreateLabel("代理类型：", 20, 350, 130, 20)
	$hProxyType = GUICtrlCreateCombo("", 150, 346, 120, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetTip(-1, "使用SOCKS代理需启用网络增强插件")
	GUICtrlSetOnEvent(-1, "GUI_EventProxyType")
	$sProxyType = StringReplace($ProxyType, "SYSTEM", "无")
	GUICtrlSetData(-1, "无|HTTP|SOCKS4|SOCKS5", $sProxyType)

	$hUseInetEx = GUICtrlCreateCheckbox("启用网络增强插件（inet.exe）", 290, 350, -1, 20)
	GUICtrlSetTip(-1, "用于查找、验证google可用IP" & @CRLF & "并提供SOCKS4/SOCK5代理支持")
	GUICtrlSetOnEvent(-1, "GUI_EventUseInetEx")
	If $UseInetEx Then
		GUICtrlSetState($hUseInetEx, $GUI_CHECKED)
	EndIf

	GUICtrlCreateLabel("代理服务器：", 20, 380, 130, 20)
	$hProxySever = GUICtrlCreateCombo("", 150, 376, 120, 20)
	If StringInStr("|google.com|127.0.0.1|", "|" & $ProxySever & "|") Then
		GUICtrlSetData(-1, "google.com|127.0.0.1", $ProxySever)
	Else
		GUICtrlSetData(-1, "google.com|127.0.0.1|" & $ProxySever, $ProxySever)
	EndIf
	GUICtrlSetOnEvent(-1, "GUI_SetProxyPort")
	GUICtrlSetTip(-1, "代理服务器IP地址")
	GUICtrlCreateLabel("代理端口：", 290, 380, 80, 20)
	$hProxyPort = GUICtrlCreateCombo("", 370, 376, 80, 20)
	If StringInStr("|80|1080|8087|", "|" & $ProxyPort & "|") Then
		GUICtrlSetData(-1, "80|1080|8087", $ProxyPort)
	Else
		GUICtrlSetData(-1, "80|1080|8087|" & $ProxyPort, $ProxyPort)
	EndIf
	GUICtrlSetTip(-1, "代理服务器端口")
	$hMapHost = GUICtrlCreateCheckbox("恢复浏览器部分google服务（搜索、扩展、书签同步等）*", 20, 406, 460, 20)
	GUICtrlSetTip(-1, "支持的域名见" & $AppName & ".ini")
	GUICtrlSetOnEvent(-1, "GUI_EventMapHost")
	If $maphost And $UseInetEx Then
		GUICtrlSetState($hMapHost, $GUI_CHECKED)
	EndIf
	GUI_SetProxy()

	; 外部程序
	GUICtrlCreateTabItem("外部程序")
	GUICtrlCreateLabel("浏览器启动时运行", 20, 80, -1, 20)
	$hExAppAutoExit = GUICtrlCreateCheckbox(" 浏览器退出后自动关闭*", 240, 75, -1, 20)
	If $ExAppAutoExit = 1 Then
		GUICtrlSetState($hExAppAutoExit, $GUI_CHECKED)
	EndIf
	$hExApp = GUICtrlCreateEdit("", 20, 100, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $ExApp <> "" Then
		GUICtrlSetData(-1, StringReplace($ExApp, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, "浏览器启动时运行的外部程序，支持批处理、vbs文件等" & @CRLF & "如需启动参数，可添加在程序路径之后")
	GUICtrlCreateButton("添加", 440, 100, 40, 20)
	GUICtrlSetTip(-1, "选择外部程序")
	GUICtrlSetOnEvent(-1, "GUI_AddExApp")

	GUICtrlCreateLabel("浏览器退出后运行*", 20, 180, -1, 20)
	$hExApp2 = GUICtrlCreateEdit("", 20, 200, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $ExApp2 <> "" Then
		GUICtrlSetData(-1, StringReplace($ExApp2, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, "浏览器退出后运行的外部程序，支持批处理、vbs文件等" & @CRLF & "如需启动参数，可添加在程序路径之后")
	GUICtrlCreateButton("添加", 440, 200, 40, 20)
	GUICtrlSetTip(-1, "选择外部程序")
	GUICtrlSetOnEvent(-1, "GUI_AddExApp2")

	GUICtrlCreateTabItem("")
	$hSettingsOK = GUICtrlCreateButton("确定", 260, 470, 70, 20)
	GUICtrlSetTip(-1, "应用设置并启动浏览器")
	GUICtrlSetOnEvent(-1, "GUI_SettingsOK")
	GUICtrlSetState(-1, $GUI_FOCUS)
	GUICtrlCreateButton("取消", 340, 470, 70, 20)
	GUICtrlSetTip(-1, "取消")
	GUICtrlSetOnEvent(-1, "ExitApp")
	$hSettingsApply = GUICtrlCreateButton("应用", 420, 470, 70, 20)
	GUICtrlSetTip(-1, "应用")
	GUICtrlSetOnEvent(-1, "GUI_SettingsApply")
	$hStausbar = _GUICtrlStatusBar_Create($hSettings, -1, '双击软件目录下的 "' & $AppName & '.vbs" 文件可调出此窗口')
	Opt("ExpandEnvStrings", 1)

	Local $ChromeExists = GUI_CheckChromeInSystem($Channel) ; 检查系统中是否有 Channel 对应的 Chrome 程序文件
	FileChangeDir(@ScriptDir)
	If $FirstRun And Not FileExists($ChromePath) Then
		If $ChromeExists Then
			_GUICtrlComboBox_SelectString($hChromeSource, "从系统中提取")
		Else
			_GUICtrlComboBox_SelectString($hChromeSource, "从网络下载")
		EndIf
	EndIf

	; 复制用户数据文件选项
	If Not FileExists(FullPath($UserDataDir) & "\Local State") And FileExists($DefaultUserDataDir & "\Local State") Then ; 文件夹中无数据文件且系统中有，则勾选复制
		GUICtrlSetState($hCopyData, $GUI_CHECKED)
	EndIf

	GUISetState(@SW_SHOW)
	AdlibRegister("GUI_ShowLatestChromeVer", 10) ; Channel 对应的 Chrome 程序文件及对应的最新版本号

	While Not $SettingsOK
		Sleep(100)
	WEnd
	GUIDelete($hSettings)
	$hSettings = "" ; free the handle
EndFunc   ;==>Settings

Func GUI_EventMapHost()
	If GUICtrlRead($hMapHost) = $GUI_CHECKED And Not $UseInetEx Then
		MsgBox(64, "MyChrome", "该功能需启用网络增强插件！", 0, $hSettings)
		GUICtrlSetState($hMapHost, $GUI_UNCHECKED)
	EndIf
EndFunc   ;==>GUI_EventMapHost

Func GUI_EventProxyType()
	Local $ptype = StringReplace(GUICtrlRead($hProxyType), "无", "SYSTEM")
	If StringInStr($ptype, "SOCKS") And Not $UseInetEx Then
		MsgBox(64, "MyChrome", "该功能需启用网络增强插件！", 0, $hSettings)
		_GUICtrlComboBox_SelectString($hProxyType, "HTTP")
		Return
	EndIf
	GUI_SetProxy()
EndFunc   ;==>GUI_EventProxyType

Func GUI_EventUseInetEx()
	Local $exe = IniRead($inifile, "IPLookup", "exe", ".\inet.exe")
	If GUICtrlRead($hUseInetEx) = $GUI_CHECKED Then
		If Not FileExists($exe) Then
			Local $msg = MsgBox(68, "MyChrome", "找不到网络增强插件 " & $exe & " ！" & @CRLF & _
					"可以通过更新程序下载此插件，现在下载吗？", 0, $hSettings)
			If $msg = 6 Then
				CheckAppUpdate($exe)
				If FileExists($exe) Then
					_GUICtrlStatusBar_SetText($hStausbar, "插件下载成功")
				Else
					_GUICtrlStatusBar_SetText($hStausbar, "插件下载失败")
				EndIf
			EndIf
			If Not FileExists($exe) Then
				GUICtrlSetState($hUseInetEx, $GUI_UNCHECKED)
				Return
			EndIf
		EndIf
		$UseInetEx = 1
		$Inet = $exe
	Else
		$UseInetEx = 0
		$Inet = @ScriptFullPath
		If GUICtrlRead($hMapHost) == $GUI_CHECKED Then
			GUICtrlSetState($hMapHost, $GUI_UNCHECKED)
		EndIf
		If StringInStr(GUICtrlRead($hProxyType), "SOCKS") Then
			_GUICtrlComboBox_SelectString($hProxyType, "HTTP")
		EndIf
	EndIf
	GUI_SetProxy()
EndFunc   ;==>GUI_EventUseInetEx

;~ Set proxy for update
Func GUI_SetProxy()
	$ProxyType = StringReplace(GUICtrlRead($hProxyType), "无", "SYSTEM")
	If $ProxyType == "SYSTEM" Then
		GUICtrlSetState($hProxySever, $GUI_DISABLE)
		GUICtrlSetState($hProxyPort, $GUI_DISABLE)
		GUICtrlSetState($hMapHost, $GUI_HIDE)
	Else
		GUICtrlSetState($hProxySever, $GUI_ENABLE)
		GUICtrlSetState($hProxyPort, $GUI_ENABLE)
		$ProxySever = GUICtrlRead($hProxySever)
		$ProxyPort = GUICtrlRead($hProxyPort)
		If $ProxyType == "HTTP" And $ProxySever == "google.com" Then
			GUICtrlSetState($hMapHost, $GUI_SHOW)
		Else
			GUICtrlSetState($hMapHost, $GUI_HIDE)
		EndIf
	EndIf
EndFunc   ;==>GUI_SetProxy

Func GUI_SetProxyPort()
	If GUICtrlRead($hProxySever) = "google.com" Then
		GUICtrlSetData($hProxyPort, 80)
	EndIf
	GUI_SetProxy()
EndFunc   ;==>GUI_SetProxyPort

Func GUI_Eventx86()
	If GUICtrlRead($hx86) = $GUI_CHECKED Then
		$x86 = 1
	Else
		$x86 = 0
	EndIf
	If $IsUpdating Then Return
	If ProcessExists($iThreadPid) Then
		_KillThread($iThreadPid)
	EndIf
	AdlibRegister("GUI_ShowLatestChromeVer", 10)
EndFunc   ;==>GUI_Eventx86

Func GUI_AddExApp()
	Local $path
	$path = FileOpenDialog("选择浏览器启动时需运行的外部程序", @ScriptDir, _
			"所有文件 (*.*)", 1 + 2, "", $hSettings)
	If $path = "" Then Return
	$path = RelativePath($path)
	$ExApp = GUICtrlRead($hExApp) & '"' & $path & '"' & @CRLF
	GUICtrlSetData($hExApp, $ExApp)
EndFunc   ;==>GUI_AddExApp
Func GUI_AddExApp2()
	Local $path
	$path = FileOpenDialog("选择浏览器启动时需运行的外部程序", @ScriptDir, _
			"所有文件 (*.*)", 1 + 2, "", $hSettings)
	If $path = "" Then Return
	$path = RelativePath($path)
	$ExApp2 = GUICtrlRead($hExApp2) & '"' & $path & '"' & @CRLF
	GUICtrlSetData($hExApp2, $ExApp2)
EndFunc   ;==>GUI_AddExApp2

Func GUI_RunInBackground()
	If GUICtrlRead($hRunInBackground) = $GUI_CHECKED Then
		Return
	EndIf
	$msg = MsgBox(36 + 256, "MyChrome", '允许 MyChrome 在后台运行可以带来更好的用户体验。若取消此选项需注意以下几点：' & @CRLF & @CRLF & _
			'1. 将浏览器锁定到任务栏或设为默认浏览器后，需再运行一次 MyChrome 才能生效；' & @CRLF & _
			'2. MyChrome 设置界面中带“*”符号的功能/选项将无法实现，包括浏览器退出后关闭外部程序、运行外部程序等。' & @CRLF & @CRLF & _
			'确定要取消此选项吗？', 0, $hSettings)
	If $msg <> 6 Then
		GUICtrlSetState($hRunInBackground, $GUI_CHECKED)
	EndIf
EndFunc   ;==>GUI_RunInBackground

;~ chrome.exe路径
Func GUI_GetChromePath()
	$sChromePath = FileOpenDialog("选择 Chrome 浏览器主程序（chrome.exe）", @ScriptDir, _
			"可执行文件(*.exe)|所有文件(*.*)", 2, "chrome.exe", $hSettings)
	If $sChromePath = "" Then Return
	If FileExists($sChromePath) Then
		_GUICtrlComboBox_SelectString($hChromeSource, "----  请选择  ----")
	EndIf
	Local $chromedll = StringRegExpReplace($sChromePath, "[^\\]+$", "chrome.dll")
	$ChromeFileVersion = FileGetVersion($chromedll, "FileVersion")
	$ChromeLastChange = GetChromeLastChange($chromedll)
	GUICtrlSetData($hCurrentVer, $ChromeFileVersion & "  " & $ChromeLastChange)
	$ChromePath = RelativePath($sChromePath) ; 绝对路径转成相对路径（如果可以）
	GUICtrlSetData($hChromePath, $ChromePath)
EndFunc   ;==>GUI_GetChromePath

; 指定用户数据文件夹
Func GUI_GetUserDataDir()
	Local $sUserDataDir = FileSelectFolder("选择一个文件夹用来保存用户数据文件", "", 1 + 4, _
			@ScriptDir & "\User Data", $hSettings)
	If $sUserDataDir <> "" Then
		$UserDataDir = RelativePath($sUserDataDir) ; 绝对路径转成相对路径（如果可以）
		GUICtrlSetData($hUserDataDir, $UserDataDir)
	EndIf
EndFunc   ;==>GUI_GetUserDataDir


;~ 从系统中复制chrome程序文件
Func GUI_CopyChromeFromSystem()
	$ChromePath = GUICtrlRead($hChromePath)
	SplitPath($ChromePath, $ChromeDir, $ChromeExe)
	$ChromeIsRunning = ChromeIsRunning($ChromePath, "请关闭 Google Chrome 浏览器以便完成更新。" & @CRLF & "是否强制关闭？")
	If $ChromeIsRunning Then Return
	_GUICtrlStatusBar_SetText($hStausbar, "从系统中提取 Google Chrome 程序文件...")
	SplashTextOn("MyChrome", "正在提取 Chrome 程序文件...", 300, 100)
	FileCopy($DefaultChromeDir & "\*.*", $ChromeDir & "\", 1 + 8)
	DirCopy($DefaultChromeDir & "\" & $DefaultChromeVer, $ChromeDir, 1)
	SplashOff()
	; 如果设定的chrome程序文件路径不以chrome.exe结尾，则认为使用者将其改名，将chrome.exe重命名为设定的文件名
	If StringRegExpReplace($ChromePath, ".*\\", "") <> "chrome.exe" Then
		FileMove($ChromeDir & "\chrome.exe", $ChromePath, 1)
	EndIf
	Local $chromedll = StringRegExpReplace($ChromePath, "[^\\]+$", "chrome.dll")
	$ChromeFileVersion = FileGetVersion($chromedll, "FileVersion")
	$ChromeLastChange = GetChromeLastChange($chromedll)
	GUICtrlSetData($hCurrentVer, $ChromeFileVersion & "  " & $ChromeLastChange)
	_GUICtrlStatusBar_SetText($hStausbar, '提取 Google Chrome 程序文件成功！')
EndFunc   ;==>GUI_CopyChromeFromSystem

;~ press "OK" in settings
Func GUI_SettingsOK()
	GUI_SettingsApply()
	If @error Or $IsUpdating Then Return
	If ProcessExists($iThreadPid) Then
		ProcessClose($iThreadPid)
	EndIf
	$SettingsOK = 1
EndFunc   ;==>GUI_SettingsOK

;~ press "Apply" in settings
Func GUI_SettingsApply()
	Local $msg, $var
	FileChangeDir(@ScriptDir)
	Opt("ExpandEnvStrings", 0)
	$ChromePath = RelativePath(GUICtrlRead($hChromePath))
	Switch GUICtrlRead($hUpdateInterval)
		Case "从不"
			$UpdateInterval = -1
		Case "每周"
			$UpdateInterval = 168
		Case "每天"
			$UpdateInterval = 24
		Case "每小时"
			$UpdateInterval = 1
		Case Else
			$UpdateInterval = 0
	EndSwitch
	$Channel = GUICtrlRead($hChannel)
	If GUICtrlRead($hx86) = $GUI_CHECKED Then
		$x86 = 1
	Else
		$x86 = 0
	EndIf
	$UserDataDir = RelativePath(GUICtrlRead($hUserDataDir))
	Local $CopyData = GUICtrlRead($hCopyData)

	If GUICtrlRead($hAppUpdate) = $GUI_CHECKED Then
		$AppUpdate = 1
	Else
		$AppUpdate = 0
	EndIf

	If GUICtrlRead($hRunInBackground) = $GUI_CHECKED Then
		$RunInBackground = 1
	Else
		$RunInBackground = 0
	EndIf

	$CacheDir = GUICtrlRead($hCacheDir)
	If $CacheDir <> "" Then
		$CacheDir = RelativePath($CacheDir)
	EndIf
	$CacheSize = GUICtrlRead($hCacheSize) * 1024 * 1024
	$var = GUICtrlRead($hParams)
	$var = StringStripWS($var, 3)
	$Params = StringReplace($var, Chr(13) & Chr(10), " ") ; 换行符换成空格

	$var = GUICtrlRead($hExApp)
	$var = StringStripWS($var, 3)
	$var = StringReplace($var, @CRLF, "||")
	$var = StringRegExpReplace($var, "\|+\s*\|+", "\|\|")
	$ExApp = $var
	If GUICtrlRead($hExAppAutoExit) = $GUI_CHECKED Then
		$ExAppAutoExit = 1
	Else
		$ExAppAutoExit = 0
	EndIf
	$var = GUICtrlRead($hExApp2)
	$var = StringStripWS($var, 3)
	$var = StringReplace($var, @CRLF, "||")
	$var = StringRegExpReplace($var, "\|+\s*\|+", "\|\|")
	$ExApp2 = $var

	If GUICtrlRead($hUseInetEx) = $GUI_CHECKED Then
		$UseInetEx = 1
	Else
		$UseInetEx = 0
	EndIf
	GUI_SetProxy()
	If GUICtrlRead($hMapHost) = $GUI_CHECKED Then
		$maphost = 1
	Else
		$maphost = 0
	EndIf
	$DownloadThreads = GUICtrlRead($hDownloadThreads)
	IniWrite($inifile, "Settings", "UserDataDir", $UserDataDir)
	IniWrite($inifile, "Settings", "Params", $Params)
	IniWrite($inifile, "Settings", "UpdateInterval", $UpdateInterval)
	IniWrite($inifile, "Settings", "Channel", $Channel)
	IniWrite($inifile, "Settings", "x86", $x86)
	IniWrite($inifile, "Settings", "CacheDir", $CacheDir)
	IniWrite($inifile, "Settings", "CacheSize", $CacheSize)
	IniWrite($inifile, "Settings", "RunInBackground", $RunInBackground)
	IniWrite($inifile, "Settings", "AppUpdate", $AppUpdate)
	IniWrite($inifile, "Settings", "ProxyType", $ProxyType)
	IniWrite($inifile, "Settings", "UpdateProxy", $ProxySever)
	IniWrite($inifile, "Settings", "UpdatePort", $ProxyPort)
	IniWrite($inifile, "Settings", "DownloadThreads", $DownloadThreads)
	IniWrite($inifile, "IPLookup", "maphost", $maphost)
	IniWrite($inifile, "IPLookup", "UseInetEx", $UseInetEx)
	$var = $ExApp
	If StringRegExp($var, '^".*"$') Then $var = '"' & $var & '"'
	IniWrite($inifile, "Settings", "ExApp", $var)
	IniWrite($inifile, "Settings", "ExAppAutoExit", $ExAppAutoExit)
	$var = $ExApp2
	If StringRegExp($var, '^".*"$') Then $var = '"' & $var & '"'
	IniWrite($inifile, "Settings", "ExApp2", $var)


	SplitPath($ChromePath, $ChromeDir, $ChromeExe)
	Opt("ExpandEnvStrings", 1)
	Local $ChromeSource = GUICtrlRead($hChromeSource)
	If $ChromeSource <> "从网络下载" And Not FileExists($ChromePath) Then ; Chrome 路径
		Local $msg = MsgBox(36, "MyChrome", "浏览器程序文件不存在或者路径错误：" & @CRLF & $ChromePath & @CRLF & @CRLF & _
				"请重新设置 chrome 浏览器路径，或者选择从网络下载。" & @CRLF & @CRLF & _
				"需要从网络下载 Google Chrome 的最新版本吗？", 0, $hSettings)
		If $msg = 6 Then
			GUICtrlSetData($hChromeSource, "")
			GUICtrlSetData($hChromeSource, "----  请选择  ----|从系统中提取|从网络下载|从离线安装文件提取", "从网络下载")
		Else
			GUICtrlSetState($hChromePath, $GUI_FOCUS)
			Return SetError(1)
		EndIf
	EndIf
	Opt("ExpandEnvStrings", 0)
	IniWrite($inifile, "Settings", "ChromePath", $ChromePath)
	Opt("ExpandEnvStrings", 1)

	; user data dir
	If Not FileExists($UserDataDir) Then
		DirCreate($UserDataDir)
	EndIf
	If $CopyData = $GUI_CHECKED Then
		Local $lockfile = $UserDataDir & "\lockfile"
		While 1
			If FileExists($lockfile) And FileDelete($lockfile) = 0 Then
				$msg = MsgBox(17, "MyChrome", "浏览器正在运行，无法提取用户数据文件！" & @CRLF & "请关闭 Chrome 浏览器后继续。")
				If $msg <> 1 Then ExitLoop
			Else
				_GUICtrlStatusBar_SetText($hStausbar, "复制 Google Chrome 用户数据文件...")
				SplashTextOn("MyChrome", "正在复制 Chrome 用户数据文件...", 300, 100)
				DirCopy($DefaultUserDataDir, $UserDataDir, 1) ; copy user data
				SplashOff()
				_GUICtrlStatusBar_SetText($hStausbar, '双击软件目录下的 "' & $AppName & '.vbs" 文件可调出此窗口')
				ExitLoop
			EndIf
		WEnd
		GUICtrlSetState($hCopyData, $GUI_UNCHECKED)
	EndIf

	$ChromeSource = GUICtrlRead($hChromeSource)
	If $ChromeSource = "从网络下载" Then
		MsgBox(64, "MyChrome", "即将从网络下载 Google Chrome 的最新版本！", 0, $hSettings)
		_GUICtrlComboBox_SelectString($hChromeSource, "----  请选择  ----")
		GUI_Start_End_ChromeUpdate()
	EndIf
EndFunc   ;==>GUI_SettingsApply

;~ 检查系统中是否有 Channel 对应的 chrome 程序文件及对应最新版本号
Func GUI_CheckChrome()
	Global $Channel = GUICtrlRead($hChannel)
	GUI_CheckChromeInSystem($Channel)
	If $IsUpdating Then Return
	If ProcessExists($iThreadPid) Then
		_KillThread($iThreadPid)
	EndIf
	AdlibRegister("GUI_ShowLatestChromeVer", 10)
EndFunc   ;==>GUI_CheckChrome

;~ 检查系统中是否存在chrome
Func GUI_CheckChromeInSystem($Channel)
	Local $dir, $Subkey, $value = "version"
	If StringInStr($Channel, "Chromium") Then
		$DefaultUserDataDir = @LocalAppDataDir & "\Chromium\User Data"
		$dir = "Chromium\Application"
		$Subkey = "Software\Chromium\BLBeacon"
	ElseIf StringInStr($Channel, "Canary") Then
		$DefaultUserDataDir = @LocalAppDataDir & "\Google\Chrome SxS\User Data"
		$dir = "Google\Chrome SxS\Application"
		$Subkey = "Software\Google\Chrome\BLBeacon"
	Else ; chrome stable / beta / dev
		$DefaultUserDataDir = @LocalAppDataDir & "\Google\Chrome\User Data"
		$dir = "Google\Chrome\Application"
		$Subkey = "Software\Google\Chrome\BLBeacon"
	EndIf

;~ 复制用户数据文件选项
	If FileExists($DefaultUserDataDir & "\Local State") Then
		GUICtrlSetState($hCopyData, $GUI_ENABLE)
		GUICtrlSetTip($hCopyData, "复制 Google Chrome 用户数据文件：" & @CRLF & $DefaultUserDataDir)
	Else
		GUICtrlSetState($hCopyData, $GUI_UNCHECKED)
		GUICtrlSetState($hCopyData, $GUI_DISABLE)
	EndIf

	; 以管理员身份在线安装在 @ProgramFilesDir
	$DefaultChromeDir = @ProgramFilesDir & "\" & $dir
	$DefaultChromeVer = RegRead("HKLM64\" & $Subkey, $value)
	If FileExists($DefaultChromeDir & "\chrome.exe") And FileExists($DefaultChromeDir & "\" & $DefaultChromeVer & "\chrome.dll") Then
		Return 1
	EndIf

	; 离线安装在 @LocalAppDataDir
	$DefaultChromeDir = @LocalAppDataDir & "\" & $dir
	$DefaultChromeVer = RegRead("HKCU\" & $Subkey, $value)
	If FileExists($DefaultChromeDir & "\chrome.exe") And FileExists($DefaultChromeDir & "\" & $DefaultChromeVer & "\chrome.dll") Then
		Return 1
	EndIf
EndFunc   ;==>GUI_CheckChromeInSystem


Func GUI_ShowLatestChromeVer()
	AdlibUnRegister("GUI_ShowLatestChromeVer")
	Local $aDlInfo[6]
	Local $ResponseTimer

	GUI_SetProxy()
	$LatestChromeVer = ""
	$LatestChromeUrls = ""
	$error = ""
	GUICtrlSetData($hLatestChromeVer, "")

	_SetVar("DLInfo", "|||||")
	_SetVar("ResponseTimer", _NowCalc())
	If $ProxyType == "SYSTEM" Then
		$iThreadPid = _StartThread($Inet, "get_latest_chrome_ver", $Channel, $x86, $inifile)
	Else
		$iThreadPid = _StartThread($Inet, "get_latest_chrome_ver", $Channel, $x86, $inifile, _
				$ProxyType & ':' & $ProxySever & ':' & $ProxyPort)
	EndIf

	While 1
		$ResponseTimer = _GetVar("ResponseTimer")
		$aDlInfo = StringSplit(_GetVar("DLInfo"), "|", 2)
		If UBound($aDlInfo) >= 6 Then
			_GUICtrlStatusBar_SetText($hStausbar, $aDlInfo[5])
			If $aDlInfo[2] Then ExitLoop
		EndIf

		If Not ProcessExists($iThreadPid) Or _DateDiff("s", $ResponseTimer, _NowCalc()) > 30 Then
			$error = $Inet & "未运行或无响应"
			ExitLoop ; 子进程结束或无响应
		EndIf
		Sleep(100)
	WEnd
	_KillThread($iThreadPid)
	If $aDlInfo[3] Then
		$LatestChromeVer = $aDlInfo[0]
		$LatestChromeUrls = $aDlInfo[1]
	Else
		If $aDlInfo[4] Then
			$error = $aDlInfo[5]
		EndIf
		_GUICtrlStatusBar_SetText($hStausbar, "获取更新信息失败 " & $error)
	EndIf
	GUICtrlSetData($hLatestChromeVer, $LatestChromeVer)
EndFunc   ;==>GUI_ShowLatestChromeVer

; 打开网站
Func OpenWebsite()
	ShellExecute("http://bbs.kafan.cn/thread-1725205-1-1.html")
EndFunc   ;==>OpenWebsite

;~ 显示下载地址
Func GUI_ShowUrl()
	If $LatestChromeUrls <> "" Then
		Local $hGUI = GUICreate("MyChrome", 500, 260)
		GUISetOnEvent($GUI_EVENT_CLOSE, "GUI_ShowUrlExit")
		GUICtrlCreateLabel("选择链接可下载或复制到剪贴板", 10, 10)
		$hUrlList = GUICtrlCreateList("", 10, 40, 480, 170, BitOR($WS_BORDER, $WS_VSCROLL))
		GUICtrlSetData(-1, StringReplace($LatestChromeUrls, " ", "|"))
		GUICtrlCreateButton("复制", 300, 220, 80, 20)
		GUICtrlSetOnEvent(-1, "GUI_CopyUrl")
		GUICtrlCreateButton("下载", 400, 220, 80, 20)
		GUICtrlSetOnEvent(-1, "GUI_DownloadUrl")
		If $IsUpdating Then
			GUICtrlSetState(-1, $GUI_DISABLE)
		EndIf
		GUISetState(@SW_SHOW, $hGUI)
	EndIf
EndFunc   ;==>GUI_ShowUrl
Func GUI_ShowUrlExit()
	GUIDelete(@GUI_WinHandle)
EndFunc   ;==>GUI_ShowUrlExit
Func GUI_CopyUrl()
	Local $url = GUICtrlRead($hUrlList)
	If $url = "" Then Return
	ClipPut($url)
	MsgBox(64, "MyChrome", "下载地址已复制到剪贴板!", 0, @GUI_WinHandle)
EndFunc   ;==>GUI_CopyUrl
Func GUI_DownloadUrl()
	$SelectedUrl = GUICtrlRead($hUrlList)
	If $SelectedUrl = "" Then Return
	GUIDelete(@GUI_WinHandle)
	GUI_Start_End_ChromeUpdate()
EndFunc   ;==>GUI_DownloadUrl

Func GUI_GetChrome()
	Local $source = GUICtrlRead($hChromeSource)
	If $source = "从系统中提取" Then
		If GUI_CheckChromeInSystem($Channel) Then
			GUI_CopyChromeFromSystem()
		Else
			MsgBox(64, "MyChrome", "在您的系统中未找到 Google Chrome（" & $Channel & "）程序文件!", 0, $hSettings)
		EndIf
		_GUICtrlComboBox_SelectString($hChromeSource, "----  请选择  ----")
	ElseIf $source = "从离线安装文件提取" Then
		Local $installer = FileOpenDialog("选择离线安装文件（chrome_installer.exe）", @ScriptDir, _
				"可执行文件(*.exe)", 1 + 2, "chrome_installer.exe", $hSettings)
		If $installer <> "" Then
			$ChromePath = GUICtrlRead($hChromePath)
			$ChromePath = FullPath($ChromePath)
			InstallChrome($installer)
			EndUpdate()
		EndIf
		_GUICtrlComboBox_SelectString($hChromeSource, "----  请选择  ----")
	EndIf
EndFunc   ;==>GUI_GetChrome

;~ thread 1~10
Func GUI_CheckThreadsNum()
	Local $Threads = GUICtrlRead($hDownloadThreads)
	If $Threads > 10 Then
		GUICtrlSetData($hDownloadThreads, 10)
	ElseIf $Threads < 1 Then
		GUICtrlSetData($hDownloadThreads, 1)
	EndIf
EndFunc   ;==>GUI_CheckThreadsNum

;~ start / stop update
Func GUI_Start_End_ChromeUpdate()
	If Not $IsUpdating Then
		$IsUpdating = 1
		_KillThread($iThreadPid)
		AdlibRegister("GUI_CheckChromeUpdate", 10) ; 通过 timer 启动更新，尽快返回，避免 GUI 无响应
	ElseIf MsgBox(292, "MyChrome", "确定要取消浏览器更新吗？", 0, $hSettings) = 6 Then
		$IsUpdating = 0
	EndIf
EndFunc   ;==>GUI_Start_End_ChromeUpdate

;~ 选择缓存目录
Func GUI_SelectCacheDir()
	Local $sCacheDir = FileSelectFolder("选择一个文件夹用来保存浏览器缓存文件", "", 1 + 4, _
			FullPath($UserDataDir) & "\Default", $hSettings)
	If $sCacheDir <> "" Then
		$CacheDir = RelativePath($sCacheDir) ; 绝对路径转成相对路径（如果可以）
		GUICtrlSetData($hCacheDir, $CacheDir)
	EndIf
EndFunc   ;==>GUI_SelectCacheDir

;~ 更新google chrome
Func GUI_CheckChromeUpdate()
	AdlibUnRegister("GUI_CheckChromeUpdate")
	$ChromePath = GUICtrlRead($hChromePath)
	$Channel = GUICtrlRead($hChannel)
	$DownloadThreads = GUICtrlRead($hDownloadThreads)
	GUI_SetProxy() ; 设置代理
	GUICtrlSetData($hCheckUpdate, "取消更新")
	GUICtrlSetTip($hCheckUpdate, "取消更新")
	GUICtrlSetState($hSettingsOK, $GUI_DISABLE)
	GUICtrlSetState($hSettingsApply, $GUI_DISABLE)

	If $SelectedUrl Then
		Local $surl = $SelectedUrl
		$SelectedUrl = ""
		UpdateChrome($ChromePath, $Channel, $surl)
	Else
		UpdateChrome($ChromePath, $Channel)
	EndIf
	If GUICtrlRead($hChromeSource) = "从网络下载" Then
		_GUICtrlComboBox_SelectString($hChromeSource, "----  请选择  ----")
	EndIf
EndFunc   ;==>GUI_CheckChromeUpdate

;~ 更新浏览器
Func UpdateChrome($ChromePath, $Channel, $surl = "")
	$ChromePath = FullPath($ChromePath)
	SplitPath($ChromePath, $ChromeDir, $ChromeExe)
	If ChromeIsUpdating($ChromeDir) Then
		If IsHWnd($hSettings) Then
			MsgBox(64, "MyChrome", "Google Chrome 浏览器上次更新仍在进行中！", 0, $hSettings)
		EndIf
		EndUpdate()
		Return
	EndIf

	$IsUpdating = 1
	Local $msg, $error, $ResponseTimer, $aDlInfo[6]
	If Not $LatestChromeVer Then ; 获取更新信息
		Do
			$LatestChromeVer = ""
			$LatestChromeUrls = ""
			$error = ""
			_SetVar("DLInfo", "|||||")
			$ResponseTimer = _NowCalc()
			_SetVar("ResponseTimer", $ResponseTimer)
			If $ProxyType == "SYSTEM" Then
				$iThreadPid = _StartThread($Inet, "get_latest_chrome_ver", $Channel, $x86, $inifile)
			Else
				$iThreadPid = _StartThread($Inet, "get_latest_chrome_ver", $Channel, $x86, $inifile, _
						$ProxyType & ':' & $ProxySever & ':' & $ProxyPort)
			EndIf

			While 1
				$ResponseTimer = _GetVar("ResponseTimer")
				$aDlInfo = StringSplit(_GetVar("DLInfo"), "|", 2)
				If UBound($aDlInfo) >= 6 Then
					If IsHWnd($hSettings) Then
						_GUICtrlStatusBar_SetText($hStausbar, $aDlInfo[5])
					EndIf
					If $aDlInfo[2] Then ExitLoop ; 任务完成
				EndIf

				If Not ProcessExists($iThreadPid) Or _DateDiff("s", $ResponseTimer, _NowCalc()) > 30 Then
					$error = $Inet & "未运行或无响应"
					ExitLoop ; 子进程结束或无响应
				EndIf
				If Not $IsUpdating Then
					ExitLoop 2 ; 手动停止更新
				EndIf
				Sleep(100)
			WEnd
			_KillThread($iThreadPid)
			If $aDlInfo[3] Then
				$LatestChromeVer = $aDlInfo[0]
				$LatestChromeUrls = $aDlInfo[1]
			Else
				If $aDlInfo[4] Then
					$error = $aDlInfo[5]
				EndIf
				If IsHWnd($hSettings) Then
					_GUICtrlStatusBar_SetText($hStausbar, "获取更新信息失败 " & $error)
				EndIf
			EndIf

			If Not $LatestChromeVer Then
				If Not IsHWnd($hSettings) Then ExitLoop
				$msg = MsgBox(16 + 5, "MyChrome", "获取 Google Chrome (" & $Channel & ") 更新信息失败！" & @CRLF & _
						$error, 0, $hSettings)
			EndIf
		Until $LatestChromeVer Or $msg = 2 ; Cancel
		If $LatestChromeVer And IsHWnd($hSettings) Then
			GUICtrlSetData($hLatestChromeVer, $LatestChromeVer)
		EndIf
	EndIf

	If Not $LatestChromeVer Then
		EndUpdate()
		Return
	EndIf

	$LastCheckUpdate = _NowCalc()
	IniWrite($inifile, "Settings", "LastCheckUpdate", $LastCheckUpdate)
	$ChromeFileVersion = FileGetVersion($ChromeDir & "\chrome.dll", "FileVersion")
	$ChromeLastChange = GetChromeLastChange($ChromeDir & "\chrome.dll")
	If $LatestChromeVer = $ChromeLastChange Or $LatestChromeVer = $ChromeFileVersion Then
		If Not IsHWnd($hSettings) Then
			EndUpdate()
			Return
		EndIf
	EndIf

	Local $info = "Google Chrome (" & $Channel & ") 可以更新，是否立即下载？" & @CRLF & @CRLF _
			 & "最新版本：" & $LatestChromeVer & @CRLF _
			 & "您的版本：" & $ChromeFileVersion & "  " & $ChromeLastChange
	$msg = 6
	If Not IsHWnd($hSettings) Then
		$msg = MsgBox(68, 'MyChrome', $info)
	EndIf
	If $msg <> 6 Then ; not YES
		EndUpdate()
		Return
	EndIf

	Local $updated, $urls
	$IsUpdating = $LatestChromeUrls
	$TempDir = $ChromeDir & "\~update"
	Local $localfile = $TempDir & "\chrome_installer.exe"
	If Not FileExists($TempDir) Then
		DirCreate($TempDir)
	EndIf
	If IsHWnd($hSettings) Then
		_GUICtrlStatusBar_SetText($hStausbar, "准备下载 Google Chrome ...")
	ElseIf Not @TrayIconVisible Then
		TraySetState(1)
		TraySetClick(8)
		TraySetToolTip("MyChrome")
		TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "TrayTipProgress")
		Local $iCancel = TrayCreateItem("取消更新 ...")
		TrayItemSetOnEvent(-1, "CancelUpdate")
		TrayTip("开始下载 Google Chrome", "点击图标可查看下载进度", 10, 1)
	EndIf

	Local $ResumeDownload = 0, $error, $errormsg
	If $surl Then
		$urls = $surl
	Else
		$urls = $LatestChromeUrls
	EndIf


	While 1
		_SetVar("ResponseTimer", _NowCalc())
		_SetVar("DLInfo", "|||||准备下载 ...")
		If Not $IsUpdating Then
			ExitLoop ; 手动停止
		EndIf
		If $ResumeDownload Then
			_SetVar("ResumeDownload", 1)
			If IsHWnd($hSettings) Then
				_GUICtrlStatusBar_SetText($hStausbar, "尝试恢复下载 ...")
			EndIf
		Else
			If $ProxyType == "SYSTEM" Then
				$iThreadPid = _StartThread($Inet, "download_chrome", $urls, $localfile, $DownloadThreads, $inifile)
			Else
				$iThreadPid = _StartThread($Inet, "download_chrome", $urls, $localfile, _
						$DownloadThreads, $inifile, $ProxyType & ":" & $ProxySever & ":" & $ProxyPort)
			EndIf

			IniWrite($TempDir & "\Update.ini", "general", "pid", $iThreadPid) ; 执行更新的程序pid,用来验证chrome是否正在更新
			IniWrite($TempDir & "\Update.ini", "general", "exe", StringRegExpReplace($Inet, ".*\\", "")) ; 正在执行更新的程序名
			IniWrite($TempDir & "\Update.ini", "general", "latest", $LatestChromeVer) ; 最新版本号
			IniWrite($TempDir & "\Update.ini", "general", "url", $urls) ; 下载地址
		EndIf

		Local $aDlInfo[6]
		While 1 ; 等待下载结束
			$aDlInfo = StringSplit(_GetVar("DLInfo"), "|", 2)
			If IsHWnd($hSettings) Then
				_GUICtrlStatusBar_SetText($hStausbar, $aDlInfo[5])
			ElseIf $TrayTipProgress Or TrayTipExists("下载 Google Chrome") Then
				TrayTip("", "下载 Google Chrome" & @CRLF & $aDlInfo[5], 10, 1)
				$TrayTipProgress = 0
			EndIf
			If $aDlInfo[2] Then ExitLoop ; 任务完成

			If Not ProcessExists($iThreadPid) Or _DateDiff("s", _GetVar("ResponseTimer"), _NowCalc()) > 30 Then
				$error = $Inet & "未运行或无响应"
				ExitLoop ; 子进程结束或无响应
			EndIf

			If Not $IsUpdating Then ; 手动停止
				ExitLoop 2
			EndIf
			Sleep(100)
		WEnd

		If $aDlInfo[2] And $aDlInfo[3] Then ; 下载成功
			FileSetAttrib($localfile, "+A") ; Win8中没这行会出错
			$updated = InstallChrome() ; 安装更新
			ExitLoop
		EndIf

		If $aDlInfo[4] Then
			$error = $aDlInfo[5]
		EndIf
		If $aDlInfo[4] = 10 Then
			$ResumeDownload = 1 ; 下载出错未完成，可续传
		Else
			$ResumeDownload = 0 ; 下载出错，不能续传
			_KillThread($iThreadPid)
		EndIf

		If IsHWnd($hSettings) Then
			_GUICtrlStatusBar_SetText($hStausbar, "下载 Google Chrome 失败 " & $error)
		EndIf

		$msg = MsgBox(16 + 5, "MyChrome", "下载 Google Chrome 失败！" & @CRLF & $error, 0, $hSettings)
		If $msg <> 4 Then ExitLoop
	WEnd

	If @TrayIconVisible Then
		TrayItemDelete($iCancel)
		TraySetState(2)
	EndIf
	EndUpdate()
	Return $updated
EndFunc   ;==>UpdateChrome

Func CancelUpdate()
	Local $msg = MsgBox(292, "MyChrome", "浏览器正在更新，确定要取消吗？")
	If $msg = 6 Then
		$IsUpdating = 0
	EndIf
EndFunc   ;==>CancelUpdate

#Region get Chrome update info (latest version, urls）
;~ $aDlInfo[6]
;~ 0 - Latest Chrome Version
;~ 1 - Latest Chrome url
;~ 2 - Set to True if the download is complete, False if the download is still ongoing.
;~ 3 - True if the download was successful. If this is False then the next data member will be non-zero.
;~ 4 - The error value for the download. The value itself is arbitrary. Testing that the value is non-zero is sufficient for determining if an error occurred.
;~ 5 - The extended value for the download. The value is arbitrary and is primarily only useful to the AutoIt developers.
Func get_latest_chrome_ver($Channel, $x86 = 0, $inifile = "", $Proxy = "")
	Local $host, $urlbase, $var, $LatestVer, $LatestUrls
	Local $http = "https"
	Local $WinVer = WinVer()
	Local $OSArch = StringLower(@OSArch)
	$x86 = $x86 * 1
	Local $ProxySever, $ProxyPort, $sProxy
	If StringInStr($Proxy, "HTTP:") == 1 Then ; support HTTP only
		$arr = StringSplit($Proxy, ":", 2)
		$ProxySever = $arr[1]
		$ProxyPort = $arr[2]
		$sProxy = $ProxySever & ":" & $ProxyPort
		If $ProxySever = "google.com" Then
			$http = "http"
			_SetVar("DLInfo", "|||||查找 Google 可用 IP ...")
			$IP = GetGoogleIP()
			If Not $IP Then
				_SetVar("DLInfo", "||1||1|获取更新信息失败 找不到 Google 可用 IP")
				Return
			EndIf
		EndIf
		$sProxy = StringReplace($sProxy, $ProxySever, $IP)
	EndIf
	AdlibRegister("ResetTimer", 1000) ; 定时向父进程发送时间信息（响应信息）

	Local $hHTTPOpen, $hConnect, $name, $a, $hRequest, $sHeader, $error
	If Not $sProxy Then
		$hHTTPOpen = _WinHttpOpen()
	Else
		$hHTTPOpen = _WinHttpOpen(Default, $WINHTTP_ACCESS_TYPE_NAMED_PROXY, $sProxy, "localhost")
	EndIf
	_WinHttpSetTimeouts($hHTTPOpen, 0, 3000, 3000, 3000)

	; get latest Chromium developer build
	; https://storage.googleapis.com/chromium-browser-continuous/index.html?path=Win/
	; https://storage.googleapis.com/chromium-browser-continuous/index.html?path=Win_x64/
	If StringInStr($Channel, "Chromium") Then
		$host = $http & "://storage.googleapis.com"
		If $Channel = "Chromium-Continuous" Then
			If $x86 Or $OSArch = "x86" Then
				$urlbase = "chromium-browser-continuous/Win"
			Else
				$urlbase = "chromium-browser-continuous/Win_x64"
			EndIf
		Else
			$urlbase = "chromium-browser-snapshots/Win"
		EndIf
		For $i = 1 To 3
			_SetVar("DLInfo", "|||||从服务器获取 Chromium 更新信息... 第 " & $i & " 次尝试")
			$hConnect = _WinHttpConnect($hHTTPOpen, $host)
			If $ProxyPort = 80 Then
				$var = _WinHttpSimpleRequest($hConnect, "GET", $urlbase & "/LAST_CHANGE")
				$error = @error
			Else
				$var = _WinHttpSimpleSSLRequest($hConnect, "GET", $urlbase & "/LAST_CHANGE")
				$error = @error
			EndIf
			_WinHttpCloseHandle($hConnect)
			If $error Then
				$error = "服务器无响应"
			Else
				If StringIsDigit($var) And $var > 0 Then
					$LatestVer = $var
					$LatestUrls = $host & "/" & $urlbase & "/" & $var & "/mini_installer.exe"
					ExitLoop
				Else
					$error = "服务器返回的更新信息无法解析"
				EndIf
			EndIf
		Next
		_WinHttpCloseHandle($hHTTPOpen)
		If $LatestVer Then
			_SetVar("DLInfo", $LatestVer & "|" & $LatestUrls & "|1|1||已成功获取 Chromium 更新信息")
		Else
			_SetVar("DLInfo", "||1||1|" & $error)
		EndIf
		Return
	EndIf

	; 利用 Google Update API 获取 stable/beta/dev/canary 最新版本号 http://code.google.com/p/omaha/wiki/ServerProtocol
	Local $appid, $ap, $data, $match
	Switch $Channel
		Case "Stable"
			$appid = "4DC8B4CA-1BDA-483E-B5FA-D3C12E15B62D" ; protocol v3
			If $x86 Or $OSArch = "x86" Or $WinVer < 6.1 Then
				$ap = "-multi-chrome"
				$OSArch = "x86"
			Else
				$ap = "x64-stable-multi-chrome"
			EndIf
		Case "Beta"
			$appid = "4DC8B4CA-1BDA-483E-B5FA-D3C12E15B62D"
			If $x86 Or $OSArch = "x86" Or $WinVer < 6.1 Then
				$ap = "1.1-beta"
				$OSArch = "x86"
			Else
				$ap = "x64-beta-multi-chrome"
			EndIf
		Case "Dev"
			$appid = "4DC8B4CA-1BDA-483E-B5FA-D3C12E15B62D"
			If $x86 Or $OSArch = "x86" Or $WinVer < 6.1 Then
				$ap = "2.0-dev"
				$OSArch = "x86"
			Else
				$ap = "x64-dev-multi-chrome"
			EndIf
		Case "Canary"
			$appid = "4EA16AC7-FD5A-47C3-875B-DBF4A2008C20"
			If $x86 Or $OSArch = "x86" Or $WinVer < 6.1 Then
				$ap = ""
				$OSArch = "x86"
			Else
				$ap = "x64-canary"
			EndIf
	EndSwitch

	; omaha protocol v3
	$data = '<?xml version="1.0" encoding="UTF-8"?><request protocol="3.0" version="1.3.23.9" ismachine="0">' & _
			'<os platform="win" version="' & $WinVer & '" sp="' & @OSServicePack & '" arch="' & $OSArch & '"/>' & _
			'<app appid="{' & $appid & '}" version="" nextversion="" ap="' & $ap & '"><updatecheck/></app></request>'

	For $i = 1 To 3
		_SetVar("DLInfo", "|||||从服务器获取 Chrome 更新信息... 第 " & 1 & " 次尝试")
		$hConnect = _WinHttpConnect($hHTTPOpen, "https://tools.google.com")
		If $ProxyPort = 80 Then
			$var = _WinHttpSimpleRequest($hConnect, "POST", "service/update2", Default, $data, "User-Agent: Google Update/1.3.23.9;winhttp")
			$error = @error
		Else
			$var = _WinHttpSimpleSSLRequest($hConnect, "POST", "service/update2", Default, $data, "User-Agent: Google Update/1.3.23.9;winhttp")
			$error = @error
		EndIf
		_WinHttpCloseHandle($hConnect)
		If $error Then
			$error = "服务器无响应"
		Else
			$match = StringRegExp($var, '(?i)<manifest +version="(.+?)".* name="(.+?)"', 1)
			If @error Then
				$error = "服务器返回的更新信息无法解析"
			Else
				$error = ""
				ExitLoop
			EndIf
		EndIf
	Next
	If Not $error Then
		$version = $match[0]
		$name = $match[1]
		$match = StringRegExp($var, '(?i)<url +codebase="(.+?)"', 3)
		If Not @error Then
			For $i = 0 To UBound($match) - 1
				$LatestUrls &= " " & $match[$i] & $name
			Next
			$LatestVer = $version
			$LatestUrls = StringStripWS($LatestUrls, 3)
		EndIf
	EndIf

	_WinHttpCloseHandle($hHTTPOpen)
	If $LatestVer Then
		_SetVar("DLInfo", $LatestVer & "|" & $LatestUrls & "|1|1||已成功获取 Chrome 更新信息")
	Else
		_SetVar("DLInfo", "||1||1|" & $error)
	EndIf
EndFunc   ;==>get_latest_chrome_ver
Func ResetTimer() ; 定时向父进程发送时间信息，告诉父进程：我还活着！
	_SetVar("ResponseTimer", _NowCalc())
EndFunc   ;==>ResetTimer
#EndRegion get Chrome update info (latest version, urls）

#Region DownloadChrome
; #FUNCTION# ;===============================================================================
; Name...........: DownloadChrome
; Description ...: 下载 chrome
; Syntax.........: DownloadChrome($url, $localfile, $DownloadThreads = 3, $ProxySever = "", $ProxyPort = "")
; Parameters ....: $url - space separated urls
;                  $localfile - local file path
;                  $DownloadThreads - download threads
;                  $ProxySever - proxy sever for update
;                  $ProxyPort - proxy port for update
;                  _SetVar("ResumeDownload", 1) - 0 - re-download totally，1 - resume download
; Return values .: Success - @error = 0, @extended = ""
;                  Failure - @error = 1: 连接服务器失败，不能续传
;                            @error = 2:下载出错，可以续传
;                            @error = 3:下载的文件不正确，不能续传
;============================================================================================
Func download_chrome($urls, $localfile, $DownloadThreads = 3, $inifile = "MyChrome.ini", $Proxy = "")
	Local $DownLoadInfo
	; Dim $DownLoadInfo[1][5]
;~ [n, 0] - bytes from
;~ [n, 1] - current pos(pointer)
;~ [n, 2] - bytes to
;~ [n, 3] - $hHttpRequest, special falg: 0 - error, -1 - complete
;~ [n, 4] - $hHttpConnect

	AdlibRegister("ResetTimer", 1000) ; 定时向父进程发送时间信息（响应信息）
	Local $ProxySever, $ProxyPort
	If StringInStr($Proxy, "HTTP:") == 1 Then ; support HTTP only
		$arr = StringSplit($Proxy, ":", 2)
		$ProxySever = $arr[1]
		$ProxyPort = $arr[2]
	EndIf
	Local $hHTTPOpen, $ret, $error
	If $ProxySever = "google.com" Or $ProxySever = "" Or $ProxyPort = "" Then ; try direct download first if google.com set as proxy
		$hHTTPOpen = _WinHttpOpen()
	Else
		$hHTTPOpen = _WinHttpOpen(Default, $WINHTTP_ACCESS_TYPE_NAMED_PROXY, $ProxySever & ":" & $ProxyPort, "localhost")
	EndIf
	_WinHttpSetTimeouts($hHTTPOpen, 0, 5000, 5000, 5000) ; 设置超时


	; get valid url
	Local $i, $j, $a, $hConnect, $hRequest, $sHeader, $url
	Local $aUrl = StringSplit($urls, " ")
	For $j = 1 To 2
		For $i = 1 To $aUrl[0]
			_SetVar("DLInfo", "|||||尝试连接 " & $aUrl[$i])
			$a = HttpParseUrl($aUrl[$i])
			$hConnect = _WinHttpConnect($hHTTPOpen, $a[0], $a[2])
			If $a[2] = 443 And $ProxySever <> "google.com" Then
				$hRequest = _WinHttpOpenRequest($hConnect, "GET", $a[1], Default, Default, Default, _
						BitOR($WINHTTP_FLAG_SECURE, $WINHTTP_FLAG_ESCAPE_DISABLE))
			Else
				$hRequest = _WinHttpOpenRequest($hConnect, "GET", $a[1])
			EndIf
			_WinHttpSendRequest($hRequest)
			_WinHttpReceiveResponse($hRequest)
			$sHeader = _WinHttpQueryHeaders($hRequest, $WINHTTP_QUERY_STATUS_CODE)
			_WinHttpCloseHandle($hRequest)
			_WinHttpCloseHandle($hConnect)
			If $sHeader = 200 Then
				$url = $aUrl[$i]
				ExitLoop 2
			EndIf
		Next
		If $ProxySever = "google.com" Then
			_WinHttpCloseHandle($hHTTPOpen)
			_SetVar("DLInfo", "|||||查找 Google 可用 IP ...")
			$hHTTPOpen = _WinHttpOpen(Default, $WINHTTP_ACCESS_TYPE_NAMED_PROXY, GetGoogleIP() & ":" & $ProxyPort, "localhost")
		EndIf
	Next

	If Not $url Then
		_WinHttpCloseHandle($hHTTPOpen)
		_SetVar("DLInfo", "||1||1|连接更新文件服务器失败")
		Return
	Else
		Local $TempDir = StringMid($localfile, 1, StringInStr($localfile, "\", 0, -1) - 1)
		If Not FileExists($TempDir) Then DirCreate($TempDir)
		If FileExists($localfile) Then FileDelete($localfile)
		Local $hDlFile = FileOpen($localfile, 25)
		While 1
			$ret = __DownloadChrome($url, $localfile, $hDlFile, $DownloadThreads, $hHTTPOpen, $DownLoadInfo)
			$error = @error
			_SetVar("DLInfo", $ret)
			For $i = 0 To UBound($DownLoadInfo) - 1
				If Not $DownLoadInfo[$i][3] Or $DownLoadInfo[$i][3] = -1 Then ContinueLoop
				_WinHttpCloseHandle($DownLoadInfo[$i][3])
				_WinHttpCloseHandle($DownLoadInfo[$i][4])
			Next
			If $error <> 10 Then ExitLoop
			While 1
				Sleep(100)
				If _GetVar("ResumeDownload") = 1 Then
					_SetVar("ResumeDownload", 0)
					ExitLoop 1
				EndIf
				If Not WinExists($__hwnd_vars) Then ExitLoop 2
			WEnd
		WEnd
		FileClose($hDlFile)
		If Not WinExists($__hwnd_vars) Then
			DirRemove($TempDir, 1) ; remove if father process is dead
		EndIf
	EndIf
	_WinHttpCloseHandle($hHTTPOpen)
EndFunc   ;==>download_chrome
Func __DownloadChrome($url, $localfile, $hDlFile, $DownloadThreads, $hHTTPOpen, ByRef $DownLoadInfo)
	Local $i, $header, $remotesize, $aThread, $match
	Local $TempDir = StringMid($localfile, 1, StringInStr($localfile, "\", 0, -1) - 1)
	Local $resume = IsArray($DownLoadInfo)

	If Not $resume Then
		; 测试服务器是否支持断点续传、获取远程文件大小，分块
		_SetVar("DLInfo", "|||||正在连接服务器...")
		For $i = 1 To 3
			$aThread = CreateThread($url, $hHTTPOpen, "10-20")
			$header = _WinHttpQueryHeaders($aThread[0])
			_WinHttpCloseHandle($aThread[0])
			_WinHttpCloseHandle($aThread[1])
			If StringRegExp($header, '(?is)^HTTP/[\d\.]+ +2') Then ExitLoop
			Sleep(500)
			If Not WinExists($__hwnd_vars) Then ExitLoop
		Next

		If Not $aThread[0] Or $header = "" Then
			Return SetError(1, 0, "||1||1|连接更新文件服务器失败") ; 无法连接服务器
		EndIf
		If StringRegExp($header, '(?is)^HTTP/[\d\.]+ +200 ') Then ; 不支持断点续传
			Dim $DownLoadInfo[1][5] = [[0, 0, 0]]
			$match = StringRegExp($header, '(?im)Content-Length: *(\d+)', 1)
			If Not @error Then
				$remotesize = $match[0]
				$DownLoadInfo[0][2] = $remotesize - 1
			EndIf
		Else
			Dim $DownLoadInfo[$DownloadThreads][5]
			$match = StringRegExp($header, '(?im)^Content-Range: *bytes +\d+-\d+/(\d+)', 1)
			If Not @error Then ; 多线程分段下载
				$remotesize = $match[0]
				Local $chunks = UBound($DownLoadInfo)
				Local $chunksize = Ceiling($remotesize / $chunks)
				Local $pointer = 0
				$DownLoadInfo[$chunks - 1][2] = $remotesize - 1
				For $i = 0 To $chunks - 1
					$DownLoadInfo[$i][0] = $pointer
					$DownLoadInfo[$i][1] = $pointer
					$pointer += $chunksize
					If $i <> $chunks - 1 Then $DownLoadInfo[$i][2] = $pointer
					$pointer += 1
				Next
			EndIf
		EndIf

		If Not $remotesize Then ; 如果远程文件大小未知，则改单线程下载
			Dim $DownLoadInfo[1][5] = [[0, 0, 0]]
		EndIf
		IniWrite($TempDir & "\Update.ini", "general", "size", $remotesize)
	EndIf

	_SetVar("DLInfo", "|||||下载 Google Chrome ...")
	Local $range, $j
	For $i = 0 To UBound($DownLoadInfo) - 1 ; 发送请求
		If Not WinExists($__hwnd_vars) Then ExitLoop
		If $DownLoadInfo[$i][2] Then
			If $DownLoadInfo[$i][1] > $DownLoadInfo[$i][2] Then ContinueLoop
			$range = $DownLoadInfo[$i][1] & "-" & $DownLoadInfo[$i][2]
		EndIf
		For $j = 1 To 2
			If Not WinExists($__hwnd_vars) Then ExitLoop
			$aThread = CreateThread($url, $hHTTPOpen, $range)
			If Not @error Then ExitLoop
			Sleep(200)
		Next
		If $i = 0 And _WinHttpQueryHeaders($aThread[0], $WINHTTP_QUERY_STATUS_CODE) = 200 Then ; 不支持断点续传
			$DownLoadInfo[$i][0] = 0
			$DownLoadInfo[$i][1] = 0
		EndIf
		$DownLoadInfo[$i][3] = $aThread[0] ; $hHttpRequest
		$DownLoadInfo[$i][4] = $aThread[1] ; $hHttpConnect
	Next

	Local $n, $data, $RecvError, $RecvLen, $msg, $bytes
	Local $Threads = UBound($DownLoadInfo)
	Local $t = TimerInit()
	Local $timediff, $timeinit = $t
	Local $speed, $progress
	Local $ErrorThreads, $LiveThreads, $FileError, $complete = 0
	Local $size = 0, $a
	Local $S[50] ; Stack for download speed calculation
	$remotesize = $DownLoadInfo[$Threads - 1][2] + 1
	If $resume Then
		For $i = 0 To $Threads - 1
			$size += $DownLoadInfo[$i][1] - $DownLoadInfo[$i][0]
		Next
	EndIf
	For $i = 0 To UBound($S) - 1
		$S[$i] = "0:" & $size
	Next

	Do
		If Not WinExists($__hwnd_vars) Then ExitLoop
		For $i = 0 To $Threads - 1
			If Not WinExists($__hwnd_vars) Then ExitLoop 2
			If Not $DownLoadInfo[$i][3] Or $DownLoadInfo[$i][3] = -1 Then
				ContinueLoop
			EndIf

			If $complete Then
				$complete = 0
				$RecvError = -1
				$RecvLen = 0
			Else
				If _WinHttpQueryDataAvailable($DownLoadInfo[$i][3]) Then
					$bytes = @extended
				Else
					$bytes = Default
				EndIf

				$data = _WinHttpReadData($DownLoadInfo[$i][3], 2, $bytes) ; read binary
				$RecvError = @error
				$RecvLen = @extended
			EndIf
			If $RecvError = -1 Then ; 当前线程下载完成
				_WinHttpCloseHandle($DownLoadInfo[$i][3])
				_WinHttpCloseHandle($DownLoadInfo[$i][4])
				$DownLoadInfo[$i][3] = -1
				$DownLoadInfo[$i][4] = -1

				; 判断是否有出错暂停的线程
				$n = 0
				For $j = 0 To $Threads - 1
					If Not $DownLoadInfo[$j][3] Then
						$n = $j
						ExitLoop
					EndIf
				Next
				; 尝试重新启动出错的线程
				If $n Then
					For $j = 1 To 3 ; 重试3次
						Sleep(200)
						$aThread = CreateThread($url, $hHTTPOpen, $DownLoadInfo[$n][1] & "-" & $DownLoadInfo[$n][2])
						If Not @error Then
							$DownLoadInfo[$n][3] = $aThread[0] ; $hHttpRequest
							$DownLoadInfo[$n][4] = $aThread[1] ; $hHttpConnect
							ExitLoop
						EndIf
					Next
				EndIf
			ElseIf $RecvError Then ; 出错，重试，断点续传
				_WinHttpCloseHandle($DownLoadInfo[$i][3])
				_WinHttpCloseHandle($DownLoadInfo[$i][4])
				$DownLoadInfo[$i][3] = 0 ; 出错标志
				$DownLoadInfo[$i][4] = 0 ; 出错标志
				For $j = 1 To 3 ; 重试3次
					Sleep(200)
					$aThread = CreateThread($url, $hHTTPOpen, $DownLoadInfo[$i][1] & "-" & $DownLoadInfo[$i][2])
					If Not @error Then
						$DownLoadInfo[$i][3] = $aThread[0] ; $hHttpRequest
						$DownLoadInfo[$i][4] = $aThread[1] ; $hHttpConnect
						ExitLoop
					EndIf
				Next
			ElseIf $RecvLen Then
				FileSetPos($hDlFile, $DownLoadInfo[$i][1], 0)
				If Not FileWrite($hDlFile, $data) Then
					$FileError = 1
					ExitLoop
				Else
					$DownLoadInfo[$i][1] += $RecvLen
					If $DownLoadInfo[$i][1] > $DownLoadInfo[$i][2] + 1 Then
						$DownLoadInfo[$i][1] = $DownLoadInfo[$i][2] + 1
						$complete = 1 ; mark current thread for complete
						$i = $i - 1 ; return to handle current thread
					EndIf
				EndIf
			EndIf
		Next

		; 检查下载是否结束，是否出错
		$size = 0
		$ErrorThreads = 0
		$LiveThreads = 0
		For $i = 0 To $Threads - 1
			$size += $DownLoadInfo[$i][1] - $DownLoadInfo[$i][0]
			If $DownLoadInfo[$i][3] = 0 Then
				$ErrorThreads += 1
			ElseIf $DownLoadInfo[$i][3] <> -1 Then
				$LiveThreads += 1
			EndIf
		Next

		If $FileError Then
			Return SetError(2, 0, $size & "|" & $remotesize & "|1||2|保存已下载的文件出错")
		EndIf

		If Not $LiveThreads And $ErrorThreads Then
			Return SetError(10, 0, $size & "|" & $remotesize & "|1||10|") ; 下载出错，可续传
		EndIf

		If TimerDiff($t) > 200 Then
			$speed = 0
			$t = TimerInit()
			$timediff = TimerDiff($timeinit)
			_ArrayPush($S, $timediff & ":" & $size)
			$a = StringSplit($S[0], ":")
			If $a[0] >= 2 Then
				$speed = ($size - $a[2]) / ($timediff - $a[1]) / 1.024
				$speed = StringFormat('%.1f', $speed)
			EndIf
			$progress = StringFormat('%.1f', $size / $remotesize * 100) & "%  -  " & _
					Round($size / 1024 / 1024, 1) & " MB / " & Round($remotesize / 1024 / 1024, 1) & " MB  -  " & $speed & " KB/s"
			_SetVar("DLInfo", $size & "|" & $remotesize & "||||下载进度:  " & $progress)
		EndIf
	Until Not $LiveThreads

	FileClose($hDlFile)
	FileSetAttrib($localfile, "+A") ; Win8中没这行会出错
	If $remotesize And $remotesize <> FileGetSize($localfile) Then ; 文件大小不对，下载出错
		Return SetError(3, 0, $size & "|" & $remotesize & "|1||3|已下载的 Google Chrome 文件大小不正确") ; 已下载的文件大小不正确
	Else
		Return SetError(0, 0, $size & "|" & $remotesize & "|1|1||Google Chrome 下载完成")
	EndIf
EndFunc   ;==>__DownloadChrome
#EndRegion DownloadChrome

; #FUNCTION# ;===============================================================================
; Name...........: CreateThread
; Description ...: create thread
; Syntax.........: CreateThread($url, $hHttpOpen, $range = "")
; Parameters ....: $url - usr as "http://dl.google.com/chrome/install/912.12/chrome_installer.exe"
;                  $hHttpOpen -
;                  $range - request range as "0-10000"
; Return values .: array
;                  Success: [$hHttpRequest, $hHttpConnect]
;                  failure: [0, 0] and set @error
;============================================================================================
Func CreateThread($url, $hHTTPOpen, $range = "")
	Local $hHttpConnect, $hHttpRequest, $aHandle

	Local $aUrl = HttpParseUrl($url) ; $aUrl[0] - host, $aUrl[1] - page, $aUrl[2] - port
	$hHttpConnect = _WinHttpConnect($hHTTPOpen, $aUrl[0], $aUrl[2])

	If $aUrl[2] = 443 Then
		$hHttpRequest = _WinHttpOpenRequest($hHttpConnect, "GET", $aUrl[1], Default, Default, Default, _
				BitOR($WINHTTP_FLAG_SECURE, $WINHTTP_FLAG_ESCAPE_DISABLE))
	Else
		$hHttpRequest = _WinHttpOpenRequest($hHttpConnect, "GET", $aUrl[1])
	EndIf
	If $range Then
		_WinHttpSendRequest($hHttpRequest, "Range: bytes=" & $range & @CRLF)
	Else
		_WinHttpSendRequest($hHttpRequest)
	EndIf
	_WinHttpReceiveResponse($hHttpRequest)
	Local $header = _WinHttpQueryHeaders($hHttpRequest, $WINHTTP_QUERY_STATUS_CODE)
	If StringLeft($header, 1) <> "2" Or Not _WinHttpQueryDataAvailable($hHttpRequest) Then
		_WinHttpCloseHandle($hHttpRequest)
		_WinHttpCloseHandle($hHttpConnect)
		Dim $aHandle[2] = [0, 0]
		Return SetError(1, 0, $aHandle)
	EndIf
	Dim $aHandle[2] = [$hHttpRequest, $hHttpRequest]
	Return SetError(0, 0, $aHandle)
EndFunc   ;==>CreateThread

Func InstallChrome($ChromeInstaller = "")
	$ChromePath = FullPath($ChromePath)
	SplitPath($ChromePath, $ChromeDir, $ChromeExe)
	Local $TempDir = $ChromeDir & "\~update"
	If Not FileExists($TempDir) Then DirCreate($TempDir)
	If $ChromeInstaller = "" Then $ChromeInstaller = $TempDir & "\chrome_installer.exe"

	If IsHWnd($hSettings) Then
		_GUICtrlStatusBar_SetText($hStausbar, "正在提取 Google Chrome 程序文件...")
	Else
		TraySetState(1)
		TraySetClick(0)
		TraySetToolTip("MyChrome")
		TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "")
		TrayTip("Google Chrome 更新", "正在提取 Google Chrome 程序文件...", 5, 1)
	EndIf

	; 解压
	FileInstall("7zr.exe", $TempDir & "\7zr.exe", 1) ; http://www.7-zip.org/download.html
	RunWait($TempDir & '\7zr.exe x "' & $ChromeInstaller & '" -y', $TempDir, @SW_HIDE)
	RunWait($TempDir & '\7zr.exe x "' & $TempDir & '\chrome.7z" -y', $TempDir, @SW_HIDE)

	; 检查主要文件是否存在
	Local $latest = IniRead($TempDir & "\Update.ini", "general", "latest", "")
	If Not StringInStr($latest, ".") Then ; 版本号中必须有 .
		$latest = FileGetVersion($TempDir & "\Chrome-bin\chrome.exe")
		If Not $latest Then ; 不带版本号
			Local $file
			Local $search = FileFindFirstFile("*.*")
			While 1
				$file = FileFindNextFile($search)
				If @error Then ExitLoop
				If StringRegExp($file, "^[\d\.]+\.[\d\.]+$") Then
					$latest = $file
					ExitLoop
				EndIf
			WEnd
			FileClose($search)
		EndIf
	EndIf

	If Not FileExists($TempDir & "\Chrome-bin\chrome.exe") Or Not FileExists($TempDir & "\Chrome-bin\" & $latest & "\chrome.dll") Then
		MsgBox(64, "更新错误-MyChrome", "提取 Google Chrome 程序文件失败！", 0, $hSettings)
		Return SetError(1, 0, 0) ; 解压错误
	EndIf

	FileMove($TempDir & "\Chrome-bin\*.*", $TempDir & "\Chrome-bin\" & $latest & "\", 9)
	DirRemove($ChromeDir & "\~updated", 1)
	DirMove($TempDir & "\Chrome-bin\" & $latest, $ChromeDir & "\~updated", 1)

	; 复制程序文件
	$ChromeIsRunning = ChromeIsRunning($ChromePath, '请关闭 Chrome 浏览器以便完成更新，是否强制关闭？' & _
			@CRLF & '点击“是”强制关闭浏览器，点击“否”推迟到下次启动时应用更新。')
	If $ChromeIsRunning Then Return
	Return ApplyUpdate() ; 返回版本号
EndFunc   ;==>InstallChrome


Func ApplyUpdate()
	If IsHWnd($hSettings) Then
		_GUICtrlStatusBar_SetText($hStausbar, "正在应用浏览器更新...")
	ElseIf @TrayIconVisible Then
		TrayTip("Google Chrome 更新", "正在应用浏览器更新...", 5, 1)
	EndIf
	FileMove($ChromeDir & "\~updated\*.*", $ChromeDir, 9)
	DirCopy($ChromeDir & "\~updated", $ChromeDir, 1)
	; 如果设定的chrome程序文件路径不以chrome.exe结尾，则认为使用者将其改名，将chrome.exe重命名为设定的文件名
	If StringRegExpReplace($ChromePath, ".*\\", "") <> "chrome.exe" Then
		FileMove($ChromeDir & "\chrome.exe", $ChromePath, 1)
	EndIf
	Local $chromedll = $ChromeDir & "\chrome.dll"
	$ChromeFileVersion = FileGetVersion($chromedll, "FileVersion")
	$ChromeLastChange = GetChromeLastChange($chromedll)
	If IsHWnd($hSettings) Then
		GUICtrlSetData($hCurrentVer, $ChromeFileVersion & "  " & $ChromeLastChange)
	EndIf
	MsgBox(64, "MyChrome", "Google Chrome 浏览器已更新至 " & $ChromeFileVersion & _
			" " & $ChromeLastChange & " !", 0, $hSettings)
	DirRemove($ChromeDir & "\~updated", 1)
	Return $ChromeFileVersion ; 返回版本号
EndFunc   ;==>ApplyUpdate

;~ 显示托盘气泡提示
Func TrayTipProgress()
	$TrayTipProgress = 1
EndFunc   ;==>TrayTipProgress

;~ 退出更新，清理临时文件，恢复状态
Func EndUpdate()
	If ProcessExists($iThreadPid) Then
		_KillThread($iThreadPid)
	EndIf

	; 检查是否有另一个 MyChrome 进程正在更新 Chrome，
	If Not ChromeIsUpdating($ChromeDir) Then
		Local $TempDir = $ChromeDir & "\~update"
		If FileExists($TempDir) Then
			DirRemove($TempDir, 1) ; 如果此文件夹中没有其它文件则删除
		EndIf
	EndIf

	If IsHWnd($hSettings) Then
		GUICtrlSetData($hCheckUpdate, "立即更新")
		GUICtrlSetTip($hCheckUpdate, "检查浏览器更新" & @CRLF & "下载最新版至 chrome 程序文件夹")
		GUICtrlSetState($hSettingsOK, $GUI_ENABLE)
		GUICtrlSetState($hSettingsApply, $GUI_ENABLE)
		_GUICtrlStatusBar_SetText($hStausbar, '双击软件目录下的 "' & $AppName & '.vbs" 文件可调出此窗口')
	EndIf
	$IsUpdating = 0
EndFunc   ;==>EndUpdate

; 退出前检查是否在更新
Func ExitApp()
	If $IsUpdating Then
		Local $msg = MsgBox(292, "MyChrome", "浏览器正在更新，确定要取消更新并退出吗？", 0, $hSettings)
		If $msg = 7 Then Return
		EndUpdate()
	ElseIf ProcessExists($iThreadPid) Then
		_KillThread($iThreadPid)
	EndIf
	Exit
EndFunc   ;==>ExitApp

; #FUNCTION# ;===============================================================================
; Name...........: SplitPath
; Description ...: 路径分割
; Syntax.........: SplitPath($path, ByRef $dir, ByRef $file)
;                  $path - 路径
;                  $dir - 目录
;                  $file - 文件名
; Return values .: Success -
;                  Failure -
; Author ........: 甲壳虫
;============================================================================================
Func SplitPath($path, ByRef $dir, ByRef $file)
	Local $pos = StringInStr($path, "\", 0, -1)
	If $pos = 0 Then
		$dir = "."
		$file = $path
	Else
		$dir = StringLeft($path, $pos - 1)
		$file = StringMid($path, $pos + 1)
	EndIf
EndFunc   ;==>SplitPath

;~ 绝对路径转成相对于脚本目录的相对路径，
;~ 如 .\dir1\dir2 或 ..\dir2
Func RelativePath($path)
	If $path = "" Then Return $path
	If StringLeft($path, 1) = "%" Then Return $path
	If Not StringInStr($path, ":") And StringLeft($path, 2) <> "\\" Then Return $path
	If StringLeft(@ScriptDir, 3) <> StringLeft($path, 3) Then Return $path ; different driver
	If StringRight($path, 1) <> "\" Then $path &= "\"
	Local $r = '.\'
	Local $pos, $dir = @ScriptDir & "\"
	While 1
		$path = StringReplace($path, $dir, $r)
		If @extended Then ExitLoop
		$pos = StringInStr($dir, "\", 0, -2)
		If $pos = 0 Then ExitLoop
		$dir = StringLeft($dir, $pos)
		If StringLeft($r, 2) = '.\' Then
			$r = '..\'
		Else
			$r = '..\' & $r
		EndIf
	WEnd
	If StringRight($path, 1) = "\" Then $path = StringTrimRight($path, 1)
	Return $path
EndFunc   ;==>RelativePath

;~ 相对于脚本目录的相对路径转换成绝对路径，输出结果结尾没有 “\”。
Func FullPath($path)
	If $path = "" Then Return $path
	If StringLeft($path, 1) = "%" Then Return $path
	If StringInStr($path, ":\") Or StringLeft($path, 2) = "\\" Then Return $path
	If StringRight($path, 1) <> "\" Then $path &= "\"
	Local $dir = @ScriptDir
	If StringLeft($path, 2) = ".\" Then
		$path = StringReplace($path, '.', $dir, 1)
	ElseIf StringLeft($path, 3) <> "..\" Then
		$path = $dir & "\" & $path
	Else
		Local $i, $n, $pos
		$path = StringReplace($path, "..\", "")
		$n = @extended
		For $i = 1 To $n
			$pos = StringInStr($dir, "\", 0, -1)
			If $pos = 0 Then ExitLoop
			$dir = StringLeft($dir, $pos - 1)
		Next
		$path = $dir & "\" & $path
	EndIf
	If StringRight($path, 1) = "\" Then $path = StringTrimRight($path, 1)
	Return $path
EndFunc   ;==>FullPath

;~ 判断是否有另一个 MyChrome 进程正在更新当前的 chrome
;~ 本程序是否正在更新 chrome 由 $IsUpdating 判断
Func ChromeIsUpdating($dir)
	Local $UpdateIni = $dir & "\~update\Update.ini"
	If Not FileExists($UpdateIni) Then Return

	Local $pid = IniRead($UpdateIni, "general", "pid", "")
	Local $exe = IniRead($UpdateIni, "general", "exe", "")
	If $pid <> $iThreadPid And ProcessExists($pid) And ProcessExists($exe) Then
		Return 1
	EndIf
EndFunc   ;==>ChromeIsUpdating

Func AppIsRunning($AppPath)
	Local $exe = StringRegExpReplace($AppPath, '.*\\', '')
	Local $list = ProcessList($exe)
	For $i = 1 To $list[0][0]
		If StringInStr(GetProcPath($list[$i][1]), $AppPath) Then
			Return $list[$i][1]
		EndIf
	Next
	Return 0
EndFunc   ;==>AppIsRunning

;~ 等待 chrome 浏览器关闭
Func ChromeIsRunning($AppPath = "chrome.exe", $msg = "请关闭 Google Chrome 浏览器后继续！" & @CRLF & "是否强制关闭？")
	If Not AppIsRunning($AppPath) Then Return 0
	$var = MsgBox(52, 'MyChrome', $msg, 0, $hSettings)
	If $var <> 6 Then Return 1
	$exe = StringRegExpReplace($AppPath, '.*\\', '')
	For $j = 1 To 20
		; close chrome
		$list = WinList("[REGEXPCLASS:(?i)Chrome]")
		For $i = 1 To $list[0][0]
			$pid = WinGetProcess($list[$i][1])
			If StringInStr(GetProcPath($pid), $AppPath) Then
				WinClose($list[$i][1])
				WinWaitClose($list[$i][1], "", 2)
			EndIf
		Next
		; kill chrome processes
		Sleep(1000)
		$list = ProcessList($exe)
		For $i = 1 To $list[0][0]
			If StringInStr(GetProcPath($list[$i][1]), $AppPath) Then
				ProcessClose($list[$i][1])
			EndIf
		Next
		If Not AppIsRunning($AppPath) Then Return 0
	Next
	Return 1
EndFunc   ;==>ChromeIsRunning


; #FUNCTION# ;===============================================================================
; Name...........: HttpParseUrl
; Description ...: 解析 http 网址
; Syntax.........: HttpParseUrl($url)
; Parameters ....: $url - 网址，如：http://dl.google.com/chrome/install/912.12/chrome_installer.exe
; Return values .: Success - $Array[0] - host, 如：dl.google.com
;                            $Array[1] - page, 如：/chrome/install/912.12/chrome_installer.exe
;                            $Array[2] - port, 如：80
;                  Failure - Returns empty sets @error
; Author ........: 甲壳虫
;============================================================================================
Func HttpParseUrl($url)
	Local $host, $page, $port, $aResults[3]
	Local $match = StringRegExp($url, '(?i)^https?://([^/]+)(/?.*)', 1)
	If @error Then Return SetError(1, 0, $aResults)
	$aResults[0] = $match[0] ; host
	$aResults[1] = $match[1] ; page
	If $aResults[1] = "" Then $aResults[1] = "/"
	If StringLeft($url, 5) = "https" Then
		$aResults[2] = 443
	Else
		$aResults[2] = 80
	EndIf
	Return SetError(0, 0, $aResults)
EndFunc   ;==>HttpParseUrl

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlComboBox_SelectString
; Description ...: Searches the ListBox of a ComboBox for an item that begins with the characters in a specified string
; Syntax.........: _GUICtrlComboBox_SelectString($hWnd, $sText[, $iIndex = -1])
; Parameters ....: $hWnd        - Handle to control
;                  $sText       - String that contains the characters for which to search
;                  $iIndex      - Specifies the zero-based index of the item preceding the first item to be searched
; Return values .: Success      - The index of the selected item
;                  Failure      - -1
; Author ........: Gary Frost (gafrost)
; Modified.......:
; Remarks .......: When the search reaches the bottom of the list, it continues from the top of the list back to the
;                  item specified by the wParam parameter.
;+
;                  If $iIndex is ?, the entire list is searched from the beginning.
;                  A string is selected only if the characters from the starting point match the characters in the
;                  prefix string
;+
;                  If a matching item is found, it is selected and copied to the edit control
; Related .......: _GUICtrlComboBox_FindString, _GUICtrlComboBox_FindStringExact, _GUICtrlComboBoxEx_FindStringExact
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _GUICtrlComboBox_SelectString($hWnd, $sText, $iIndex = -1)
;~ 	If $Debug_CB Then __UDF_ValidateClassName($hWnd, $__COMBOBOXCONSTANT_ClassName)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)

	Return _SendMessage($hWnd, $CB_SELECTSTRING, $iIndex, $sText, 0, "wparam", "wstr")
EndFunc   ;==>_GUICtrlComboBox_SelectString

; get Windows version
Func WinVer()
	Local $tOSVI, $ret
	$tOSVI = DllStructCreate('dword Size;dword MajorVersion;dword MinorVersion;dword BuildNumber;dword PlatformId;wchar CSDVersion[128]')
	DllStructSetData($tOSVI, 'Size', DllStructGetSize($tOSVI))
	$ret = DllCall('kernel32.dll', 'int', 'GetVersionExW', 'ptr', DllStructGetPtr($tOSVI))
	If (@error) Or (Not $ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return DllStructGetData($tOSVI, 'MajorVersion') & "." & DllStructGetData($tOSVI, 'MinorVersion')
EndFunc   ;==>WinVer

;===============================================================================
;~ 函数: TrayTipExists()
;~ 描述: 检测托盘提示是否存在
;~ 参数:
;~ $TrayText = TrayTip text 中包含的文字
;~ $MatchMode = TrayTip text 匹配模式
;~                  0 - 用 StringInStr 匹配部分文字 (default)
;~                  1 - StringRegExp 正则式匹配
;~ 返回值: TrayTip() 的 handle
;~ 例:
;~ TrayTip("下载 Google Chrome", "10000 KB / 21000 KB - 100 KB/s", 20)
;~ $hTrayTip = TrayTipExists("(?i) KB / .* KB .* KB/s", 1)
;~ If Not $hTrayTip Then
;~ 	MsgBox(0, "", "未检测到托盘提示！")
;~ Else
;~ 	Do
;~ 		Sleep(100)
;~ 	Until Not TrayTipExists("(?i) KB / .* KB .* KB/s", 1)
;~ 	MsgBox(0, "TrayTipExists()", "托盘提示因点击或超时关闭！")
;~ EndIf
;===============================================================================
Func TrayTipExists($TrayText, $MatchMode = 0)
	Local $aWindows = WinList('[CLASS:tooltips_class32]')
	Local $i, $hWnd, $class, $text
	For $i = 1 To $aWindows[0][0]
		If Not BitAND(WinGetState($aWindows[$i][1]), 2) Then ContinueLoop ; ignore hidden windows
		$hWnd = DllCall("user32.dll", "hwnd", "GetParent", "hwnd", $aWindows[$i][1])
		If @error Then Return SetError(@error, @extended, 0)
		$class = DllCall("user32.dll", "int", "GetClassNameW", "hwnd", $hWnd[0], "wstr", "", "int", 1024)
		If @error Then Return SetError(@error, @extended, 0)
		If $class[2] <> "Shell_TrayWnd" Then ContinueLoop

		$text = WinGetTitle($aWindows[$i][1]) ; actually get the text of TrayTip()
		If $MatchMode = 1 Then
			If StringRegExp($text, $TrayText) Then Return $aWindows[$i][1]
		Else
			If StringInStr($text, $TrayText) Then Return $aWindows[$i][1]
		EndIf
	Next
EndFunc   ;==>TrayTipExists

;~ http://www.autoitscript.com/forum/index.php?showtopic=13399&hl=GetCurrentProcessId&st=20
; Original version : w_Outer
; modified by Rajesh V R to include process ID
Func ReduceMemory($ProcID = @AutoItPID)
	Local $ai_Handle = DllCall("kernel32.dll", 'int', 'OpenProcess', 'int', 0x1f0fff, 'int', False, 'int', $ProcID)
	Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ai_Handle[0])
	DllCall('kernel32.dll', 'int', 'CloseHandle', 'int', $ai_Handle[0])
	Return $ai_Return[0]
EndFunc   ;==>ReduceMemory

; #FUNCTION# ;===============================================================================
; 参考 http://www.autoitscript.com/forum/topic/63947-read-full-exe-path-of-a-known-windowprogram/
; Name...........: GetProcPath
; Description ...: 取得进程路径
; Syntax.........: GetProcPath($Process_PID)
; Parameters ....: $Process_PID - 进程的 pid
; Return values .: Success - 完整路径
;                  Failure - set @error
;============================================================================================
Func GetProcPath($pid = @AutoItPID)
	If @OSArch <> "X86" And Not @AutoItX64 And Not _WinAPI_IsWow64Process($pid) Then ; much slow than dllcall method
		Local $colItems = ""
		Local $objWMIService = ObjGet("winmgmts:\\localhost\root\CIMV2")
		$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE ProcessId = " & $pid, "WQL", _
				0x10 + 0x20)
		If IsObj($colItems) Then
			For $objItem In $colItems
				If $objItem.ExecutablePath Then Return $objItem.ExecutablePath
			Next
		EndIf
		Return ""
	Else
		Local $hProcess = DllCall('kernel32.dll', 'ptr', 'OpenProcess', 'dword', BitOR(0x0400, 0x0010), 'int', 0, 'dword', $pid)
		If (@error) Or (Not $hProcess[0]) Then Return SetError(1, 0, '')
		Local $ret = DllCall(@SystemDir & '\psapi.dll', 'int', 'GetModuleFileNameExW', 'ptr', $hProcess[0], 'ptr', 0, 'wstr', '', 'int', 1024)
		If (@error) Or (Not $ret[0]) Then Return SetError(1, 0, '')
		Return $ret[3]
	EndIf
EndFunc   ;==>GetProcPath

; #FUNCTION# ====================================================================================================================
; Name ..........: _IsUACAdmin
; Description ...: Determines if process has Admin privileges and whether running under UAC.
; Syntax ........: _IsUACAdmin()
; Parameters ....: None
; Return values .: Success          - 1 - User has full Admin rights (Elevated Admin w/ UAC)
;                  Failure          - 0 - User is not an Admin, sets @extended:
;                                   | 0 - User cannot elevate
;                                   | 1 - User can elevate
; Author ........: Erik Pilsits
; Modified ......:
; Remarks .......: THE GOOD STUFF: returns 0 w/ @extended = 1 > UAC Protected Admin
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _IsUACAdmin()
	If StringRegExp(@OSVersion, "_(XP|2003)") Or RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", "EnableLUA") <> 1 Then
		Return SetExtended(0, IsAdmin())
	EndIf

	Local $hToken = _Security__OpenProcessToken(_WinAPI_GetCurrentProcess(), $TOKEN_QUERY)
	Local $tTI = _Security__GetTokenInformation($hToken, $TOKENGROUPS)
	_WinAPI_CloseHandle($hToken)

	Local $pTI = DllStructGetPtr($tTI)
	Local $cbSIDATTR = DllStructGetSize(DllStructCreate("ptr;dword"))
	Local $count = DllStructGetData(DllStructCreate("dword", $pTI), 1)
	Local $pGROUP1 = DllStructGetPtr(DllStructCreate("dword;STRUCT;ptr;dword;ENDSTRUCT", $pTI), 2)
	Local $tGROUP, $sGROUP = ""

	; S-1-5-32-544 > BUILTINAdministrators > $SID_ADMINISTRATORS
	; S-1-16-8192  > Mandatory LabelMedium Mandatory Level (Protected Admin) > $SID_MEDIUM_MANDATORY_LEVEL
	; S-1-16-12288 > Mandatory LabelHigh Mandatory Level (Elevated Admin) > $SID_HIGH_MANDATORY_LEVEL
	; SE_GROUP_USE_FOR_DENY_ONLY = 0x10

	Local $inAdminGrp = False, $denyAdmin = False, $elevatedAdmin = False, $sSID
	For $i = 0 To $count - 1
		$tGROUP = DllStructCreate("ptr;dword", $pGROUP1 + ($cbSIDATTR * $i))
		$sSID = _Security__SidToStringSid(DllStructGetData($tGROUP, 1))
		If StringInStr($sSID, "S-1-5-32-544") Then ; member of Administrators group
			$inAdminGrp = True
			; check for deny attribute
			If (BitAND(DllStructGetData($tGROUP, 2), 0x10) = 0x10) Then $denyAdmin = True
		ElseIf StringInStr($sSID, "S-1-16-12288") Then
			$elevatedAdmin = True
		EndIf
	Next

	If $inAdminGrp Then
		; check elevated
		If $elevatedAdmin Then
			; check deny status
			If $denyAdmin Then
				; protected Admin CANNOT elevate
				Return SetExtended(0, 0)
			Else
				; elevated Admin
				Return SetExtended(1, 1)
			EndIf
		Else
			; protected Admin
			Return SetExtended(1, 0)
		EndIf
	Else
		; not an Admin
		Return SetExtended(0, 0)
	EndIf
EndFunc   ;==>_IsUACAdmin

; Return $v1 - $v1
Func VersionCompare($v1, $v2)
	Local $i, $a1, $a2, $ret = 0
	$a1 = StringSplit($v1, ".", 2)
	$a2 = StringSplit($v2, ".", 2)
	If UBound($a1) > UBound($a2) Then
		ReDim $a2[UBound($a1)]
	Else
		ReDim $a1[UBound($a2)]
	EndIf
	For $i = 0 To UBound($a1) - 1
		$ret = $a1[$i] - $a2[$i]
		If $ret <> 0 Then ExitLoop
	Next
	Return $ret
EndFunc   ;==>VersionCompare

Func GetGoogleIP()
	Local $IP
	$inifile = StringLeft(@ScriptFullPath, StringInStr(@ScriptFullPath, ".", 0, -1) - 1) & ".ini"
	$GIP = IniRead($inifile, "IPLookup", "GIP", "")
	If $GIP <> "" Then
		Local $aIP = StringSplit($GIP, "|", 2)
		$IP = GetValidIP($aIP, $inifile, True)
		If $IP Then Return $IP
	EndIf
	$GIPSource = IniRead($inifile, "IPLookup", "GIPSource", "")
	$gs = $GIPSource
	$ss = "1234"
	If $gs = "" Then $gs = 1
	While 1
		Switch $gs
			Case 1 ; http://www.xiexingwen.com/
				$var = InetReadData("http://xiexingwen.com/google/tts.php?query=*", 1024)
				$match = StringRegExp($var, '(?is)var +hs\s*=\s*\[\s*([\d\." ,]+)\s*\]', 1)
				If Not @error Then
					$match = StringRegExp($match[0], '"(\d+\.\d+\.\d+\.\d+)"', 3)
					If Not @error Then
						$IP = GetValidIP($match, $inifile)
					EndIf
				EndIf
			Case 2 ; https://github.com/txthinking/google-hosts
				$var = InetReadData("https://raw.githubusercontent.com/txthinking/google-hosts/master/hosts", 512)
				$match = StringRegExp($var, '(?im)^(\d+\.\d+\.\d+\.\d+) +.*\.google', 3)
				If Not @error Then
					$var = ""
					For $i = 0 To UBound($match) - 1
						If Not StringInStr($var, $match[$i]) Then
							$var &= " " & $match[$i]
						EndIf
					Next
					$var = StringStripWS($var, 7)
					$IP = GetValidIP(StringSplit($var, " ", 2), $inifile)
				EndIf
			Case 3 ; http://www.go2121.com/google/splus.php?query=*
				$var = InetReadData("http://go2121.com/google/splus.php?query=*", 1024)
				$match = StringRegExp($var, '(?is)var +hs\s*=\s*\[\s*([\d\." ,]+)\s*\]', 1)
				If Not @error Then
					$match = StringRegExp($match[0], '"(\d+\.\d+\.\d+\.\d+)"', 3)
					If Not @error Then
						$IP = GetValidIP($match, $inifile)
					EndIf
				EndIf
			Case 4 ; http://anotherhome.net/easygoagent/proxy.ini
				$var = InetReadData("http://anotherhome.net/easygoagent/proxy.ini", 4*1024)
				$match = StringRegExp($var, '(?i)google_hk\s*=\s*([\d\.\|]+)', 1) ; google_hk = 216.58.220.71|216.58.220.27|64.233.189.197
				If Not @error Then
					$IP = GetValidIP(StringSplit($match[0], "|", 2), $inifile)
				EndIf
		EndSwitch
		If $IP Then ExitLoop
		$ss = StringReplace($ss, $gs, "")
		$gs = StringLeft($ss, 1)
		If $gs = "" Then ExitLoop
	WEnd
;~ 	If Not $IP Then
;~ 		$IP = TCPNameToIP("google.cn")
;~ 	EndIf
	If $gs <> $GIPSource Then
		IniWrite($inifile, "IPLookup", "GIPSource", $gs)
	EndIf
	Return $IP
EndFunc   ;==>GetGoogleIP
Func InetReadData($url, $bytes = 1024)
	$aUrl = HttpParseUrl($url)
	If @error Then Return ""
	$hOpen = _WinHttpOpen()
	_WinHttpSetTimeouts($hOpen, 0, 5000, 5000, 5000)
	$hConnect = _WinHttpConnect($hOpen, $aUrl[0], $aUrl[2])
	If $aUrl[2] = 443 Then
		$hRequest = _WinHttpSimpleSendSSLRequest($hConnect, "GET", $aUrl[1])
	Else
		$hRequest = _WinHttpSimpleSendRequest($hConnect, "GET", $aUrl[1])
	EndIf
	_WinHttpReceiveResponse($hRequest)
	$var = _WinHttpReadData($hRequest, 1, $bytes)
	_WinHttpCloseHandle($hRequest)
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)
	Return $var
EndFunc   ;==>InetReadData
Func GetValidIP($aIP, $inifile, $fromini = False)
	Local $IP, $NewIPs
	$TryCnt = 20
	If UBound($aIP) < $TryCnt Then
		$TryCnt = UBound($aIP)
	EndIf
	TCPStartup()
	AutoItSetOption("TCPTimeout", 2000)
	For $i = 0 To $TryCnt - 1
		$sHeader = "GET / HTTP/1.1" & @CRLF & _
				"Host: " & $aIP[$i] & @CRLF & _
				"Connection: close" & @CRLF & @CRLF
		$hConnect = TCPConnect($aIP[$i], 80)
		TCPSend($hConnect, $sHeader)
		$sHeader = TCPRecv($hConnect, 1024)
		TCPCloseSocket($hConnect)
		If StringRegExp($sHeader, '(?is)HTTP/\d+\.\d+ +[123]\d\d +.*Server: *gws', 0) Then
			$IP = $aIP[$i]
			For $j = $i To $TryCnt - 1
				$NewIPs &= "|" & $aIP[$j]
			Next
			$NewIPs = StringTrimLeft($NewIPs, 1)
			ExitLoop
		EndIf
	Next
	TCPShutdown()
	If Not $fromini Or ($fromini And $IP <> $aIP[0]) Then
		IniWrite($inifile, "IPLookup", "GIP", $NewIPs)
	EndIf
	Return $IP
EndFunc   ;==>GetValidIP
