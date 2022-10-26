#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Manage WU
#AutoIt3Wrapper_Res_Fileversion=1.0.0.7
#AutoIt3Wrapper_Res_ProductName=Manage WU
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.7
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/reel
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.16.0
	Author:         Cramaboule
	Date:			July - August 2022

	Script Function: Manage WU and reboot


	Bug: 	Not known

	To do:	-

	V1.0.0.7	19.10.2022:
				Added: Win10 22H2 (10.0.19045.xxxx)
	V1.0.0.6	18.10.2022:
				Modified: loop until gets internet
	V1.0.0.5	06.10.2022:
				Added: WIN11 22H2 (10.0.226xx)
	V1.0.0.4	03.10.2022:
				Modified: force UpToDate if wusa exit code not those that we want => re-download and re-Install KB.
	V1.0.0.3	28.09.2022:
				Add: Possibility to update and reboot
	V1.0.0.2	28.09.2022:
				Modified: revert 'possibility to reboot'
				was not made properly
	V1.0.0.1	27.09.2022:
				Modified: Text in buttons
				Add: Possibility to update and reboot
	V1.0.0.0	30.08.2022:
				Inital relase

#ce ----------------------------------------------------------------------------
#include-once
#include <FileConstants.au3>
#include <InetConstants.au3>
#include <AutoItConstants.au3>
#include <File.au3>
#include <String.au3>
#include <Array.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <MsgBoxConstants.au3>
#include <Date.au3>
#include <WinAPISys.au3>
#include <WinAPIProc.au3>
#include <Misc.au3>
#include 'MultiLang.au3'
;~ ======================================== MUST BE AT 0 WHEN COMPILING FOR PROD =============================
Global $debug = 0
Global $dev = 0 ; for developpement purpose only
;~ ======================================== MUST BE AT 0 WHEN COMPILING FOR PROD =============================

Global $head = 'Manage Windows Update V1.0.0.7'

If @Compiled Then
	Global $rootdir = 'C:\Users\Public\Documents\ManageWU'
Else
	Global $rootdir = @ScriptDir
EndIf

If $dev Then ;=========================================== $dev = 1 ; for developpement purpose only ===========
	Global $sFileNew = $rootdir & '\new\ManageWU-dev.exe'
Else
	Global $sFileNew = $rootdir & '\new\ManageWU.exe'
EndIf

Global $sFileIni = $rootdir & '\ManageWU.ini'
Global $sFileLog = $rootdir & '\ManageWU.log'
Global $sFileDat = $rootdir & '\ManageWU.dat'
Global $sKBFolder = $rootdir & '\KBfiles'
Global $sRootDwl = 'https://exemple.com/download'
Global $sEndWorkOrRebootLater = ''

_FileWriteLog($sFileLog, 'Starting...')

Sleep(500) ; let time other process to close nicely (during update of itself)

$aProcessList = ProcessList(@ScriptName)
If $aProcessList[0][0] > 1 Then
	_WritingStuff_Exiting('', '2 prg running')
	$sStatus = IniRead($sFileIni, 'Update', 'Status', 'UpToDate')
	If $sStatus = 'RebootAtEndWork' Then ; normaly 1 prg run but in this case we need to kill older process in order to display GUI
		$sFirstPID = IniRead($sFileIni, 'Running', 'PID', 0)
		_WritingStuff_Exiting('', 'Will kill other prg ' & $sFirstPID)
		RunWait(@ComSpec & ' /c ' & 'TASKKILL /F /PID ' & $sFirstPID, @SystemDir, @SW_HIDE) ;kill older process
	Else
		_WritingStuff_Exiting('', 'An Another process exists, exiting', 1)
	EndIf
EndIf
$sPID = ProcessExists(@ScriptName)
IniWrite($sFileIni, 'Running', 'PID', $sPID)
_WritingStuff_Exiting('', 'PID : ' & $sPID)

If $Cmdline[0] And $Cmdline[1] = '-s' Then
	_WritingStuff_Exiting('', 'command line -s, intalling')
	_Install()
	Run($rootdir & '\' & @ScriptName)
	_WritingStuff_Exiting('', 'Exiting from command line -s', 1)
EndIf

_Update()

If Not (FileExists($rootdir & '\' & @ScriptName)) Then
	_Install(1)
	_FileWriteLog($sFileLog, 'Did the install because $rootdir was not there, exetuting command line -s')
	Run($rootdir & '\' & @ScriptName & ' -s')
	_WritingStuff_Exiting('', 'Exiting from $rootdir not existing', 1)
EndIf

_CleanFileLog()

$bIamSYSTEM = 0
$aUser = _WinAPI_GetProcessUser(0)
_FileWriteLog($sFileLog, 'Process is run by : ' & $aUser[0])
If StringInStr($aUser[0], 'syst') Then
	$bIamSYSTEM = 1
	_WritingStuff_Exiting('', 'Process is run by ' & $aUser[0] & ' GUI will be shown at next normal schedule', 1)
EndIf

$aVersion = _GetVersion()
Switch $aVersion[1]
	Case 'WIN_10'
		If StringInStr($aVersion[0], '10.0.19045') Then ;22h2
			$sKBfile = IniRead($sFileDat, 'Windows10-22h2', 'KBfile', 'Error')
			$sVersion = IniRead($sFileDat, 'Windows10-22h2', 'Version', 'Error')
		Else
			$sKBfile = IniRead($sFileDat, 'Windows10-21h2', 'KBfile', 'Error')
			$sVersion = IniRead($sFileDat, 'Windows10-21h2', 'Version', 'Error')
		EndIf
	Case 'WIN_11'
		If StringInStr($aVersion[0], '10.0.226') Then ;22h2
			$sKBfile = IniRead($sFileDat, 'Windows11-22h2', 'KBfile', 'Error')
			$sVersion = IniRead($sFileDat, 'Windows11-22h2', 'Version', 'Error')
		Else
			$sKBfile = IniRead($sFileDat, 'Windows11-21h2', 'KBfile', 'Error')
			$sVersion = IniRead($sFileDat, 'Windows11-21h2', 'Version', 'Error')
		EndIf
	Case Else
		_WritingStuff_Exiting('', 'Case Else in Switch $aVersion [1]=' & $aVersion[1], 1)
EndSwitch

If $debug Then
	$sVersion = 1234
	IniWrite($sFileIni, 'Update', 'Status', 'WuInsalled')
	$sStatus = IniRead($sFileIni, 'Update', 'Status', 'UpToDate')
Else
	$sStatus = IniRead($sFileIni, 'Update', 'Status', 'UpToDate')
EndIf
_FileWriteLog($sFileLog, 'KBFile from dat file : ' & $sKBfile)
_FileWriteLog($sFileLog, 'Version from dat file : ' & $sVersion)

If $aVersion[0] <> $sVersion Then
	If $sStatus = 'UpToDate' Then IniWrite($sFileIni, 'Update', 'Status', 'NeedUpdate')
	$sStatus = IniRead($sFileIni, 'Update', 'Status', 'UpToDate')
	_WritingStuff_Exiting('', 'Before Switch', 0)
	Switch $sStatus
		Case 'NeedUpdate'
			_FileWriteLog($sFileLog, 'Downloading : ' & $sRootDwl & $sKBfile)
			DirRemove($sKBFolder, $DIR_REMOVE)
			DirCreate($sKBFolder)
			InetGet($sRootDwl & $sKBfile, $sKBFolder & '\' & $sKBfile, $INET_FORCERELOAD)
			If @error <> 0 Then
				_WritingStuff_Exiting('NeedUpdate', 'Download failed, InetGet got error, Exiting', 1)
			EndIf
			_WritingStuff_Exiting('Installing', 'Download finished, need installing', 0)
			ContinueCase

		Case 'Installing'
			$ReturnCode = _InstallKBFile($sKBfile)
			If $ReturnCode = '1618' Then     ; already running
				_WritingStuff_Exiting('', 'An another install is in progress, waiting 15 minutes', 0)
				Sleep(1000 * 60 * 15)     ; 15 minutes
				$ReturnCode = _InstallKBFile($sKBfile)
			EndIf
			If (($ReturnCode <> '2359301') And ($ReturnCode <> '2359302') And ($ReturnCode <> '3010')) Then
				_WritingStuff_Exiting('UpToDate', 'Exiting after wusa', 1) ; force UpToDate if error => force re-downloading, and re-installing
			EndIf
			_WritingStuff_Exiting('WuInsalled', 'wusa has finished, WU Insalled and need reboot', 0)
			If $bIamSYSTEM Then
				_WritingStuff_Exiting('', 'User is SYSTEM prg will exit and GUI will be shown at next schedule', 1)
			Else
				ContinueCase
			EndIf

		Case 'WuInsalled', 'RebootLater', 'RebootAtEndWork', 'Rebooting' ; missed somehow reboot and not up to date
			_WritingStuff_Exiting('', 'Displaying choices', 0)
			_DisplayChoices($aVersion[2])
			ContinueCase

		Case 'RebootAtEndWork'
			If $sEndWorkOrRebootLater = 'RebootLater' Then
				ContinueCase
			Else
				_WritingStuff_Exiting('RebootAtEndWork', 'User choose reboot at end work', 0)
				_ShowHidePowerButton(0) ; Hide buttons and show update and shut down ; 1=show normal, 0=update and shutdown, -1=update and restart
				_WaitToReboot(0) ; Wait to reboot and bloque reboot (Shutdown)(short time) to write ini
				_WritingStuff_Exiting('RebootAtEndWork', 'User click on "reboot at end work"', 1)
			EndIf

		Case 'RebootLater'
			_ShowHidePowerButton(-1) ; Hide buttons and show update and restart ; 1=show normal, 0=update and shutdown, -1=update and restart
			_WaitToReboot(-1) ; Wait to reboot and bloque reboot (short time) to write ini
			_WritingStuff_Exiting('RebootLater', 'User click on "reboot later"', 1)

		Case Else
			_WritingStuff_Exiting('', 'Case else $sStatus, Exiting!!!', 1)
	EndSwitch
Else
	_ShowHidePowerButton(1) ; 1=show normal, 0=update and shutdown, -1=update and restart
	_WritingStuff_Exiting('UpToDate', 'Version of Windows is up to date, Exiting', 1)
EndIf

;~ =============== Functions ====================================================================================================================================

;~ ==============================================================================================================================================================

Func _Update()
	_FileWriteLog($sFileLog, 'Update() Function')
	;Check for update on the internet
	Do
		Sleep(100)
	Until Ping('www.google.ch')

	InetGet($sRootDwl & 'ManageWU.dat', $sFileDat, $INET_FORCERELOAD)
	$FileTimeNew = IniRead($sFileDat, StringTrimRight(@ScriptName, 4), 'Version', 'Error') ; ManageWU, ManageWU-dev
	$FileTimeOld = FileGetTime($rootdir & '\' & @ScriptName, $FT_MODIFIED, $FT_STRING)
	If $FileTimeNew <> 'Error' And $FileTimeNew > $FileTimeOld Then ; Newer version; connected to the network and have a newer version
		_FileWriteLog($sFileLog, 'New version of ' & @ScriptName)
		DirRemove($rootdir & '\new', $DIR_REMOVE)
		DirCreate($rootdir & '\new')
		InetGet($sRootDwl & @ScriptName, $sFileNew, $INET_FORCERELOAD)
		Run($sFileNew & ' -s')
		_WritingStuff_Exiting('', 'End of Update() func, Exiting', 1)
	Else
		_FileWriteLog($sFileLog, @ScriptName & ' has not changed')
	EndIf
	_WritingStuff_Exiting('', 'End of Update() func')

EndFunc   ;==>_Update

Func _Install($param = 0)
	DirCreate($rootdir)
	DirCreate($rootdir & '\LngFiles')
	_FileWriteLog($sFileLog, 'Install() Function')
	FileInstall('MyBrand.bmp', $rootdir & '\', $FC_OVERWRITE + $FC_CREATEPATH)
	FileInstall('.\LngFiles\FRENCH.XML', $rootdir & '\LngFiles\', $FC_OVERWRITE + $FC_CREATEPATH)
	FileInstall('.\LngFiles\ENGLISH.XML', $rootdir & '\LngFiles\', $FC_OVERWRITE + $FC_CREATEPATH)
	FileInstall('.\LngFiles\GERMAN.XML', $rootdir & '\LngFiles\', $FC_OVERWRITE + $FC_CREATEPATH)
	FileInstall('ScheduleManageWU.xml', $rootdir & '\', $FC_OVERWRITE + $FC_CREATEPATH)
	FileInstall('Shutdown.exe', $rootdir & '\', $FC_OVERWRITE + $FC_CREATEPATH)
	If $param Then IniWrite($sFileIni, 'Update', 'Status', 'UpToDate')
	FileCopy(@ScriptFullPath, $rootdir, $FC_OVERWRITE + $FC_CREATEPATH)
	InetGet($sRootDwl & 'ManageWU.dat', $sFileDat, $INET_FORCERELOAD)
	Local $iPID = RunWait(@ComSpec & ' /c SCHTASKS /create /TN "ManageWU\ManageWU" /xml "' & $rootdir & '\ScheduleManageWU.xml" /F', @SystemDir, @SW_HIDE, BitOR($STDERR_CHILD, $STDOUT_CHILD))
EndFunc   ;==>_Install

Func _InstallKBFile($ssKBfile)
	$sRun = @ComSpec & ' /c wusa.exe "' & $sKBFolder & '\' & $ssKBfile & '" /quiet /norestart'
	_FileWriteLog($sFileLog, 'Executing : ' & $sRun)
	$sReturnCode = RunWait($sRun, @SystemDir, @SW_HIDE)
	_FileWriteLog($sFileLog, 'Return code from wusa : ' & $sReturnCode)
	Return $sReturnCode
EndFunc   ;==>_InstallKBFile

Func _GetVersion()
	Local $aReturn[0], $sOutput = ''
	_FileWriteLog($sFileLog, '_GetVersion() Function')
	Local $iPID = Run(@ComSpec & ' /c ver', @SystemDir, @SW_HIDE, $STDERR_MERGED)
	While 1
		$sOutput &= StdoutRead($iPID)
		If @error Then         ; Exit the loop if the process closes or StdoutRead returns an error.
			ExitLoop
		EndIf
	WEnd
	$sOutput = _StringBetween($sOutput, 'version ', ']')
	_FileWriteLog($sFileLog, 'Version of PC : ' & $sOutput[0])
	_FileWriteLog($sFileLog, 'Version of Windows : ' & @OSVersion)
	_FileWriteLog($sFileLog, 'Langage of Windows : ' & @MUILang) ;return the current lang, better then @OSLang
	_ArrayAdd($aReturn, $sOutput[0])
	_ArrayAdd($aReturn, @OSVersion)
	_ArrayAdd($aReturn, @MUILang)
	Return $aReturn
EndFunc   ;==>_GetVersion

Func _DisplayChoices($lang)
	_MultiLang_Config(@ScriptDir & '\LngFiles')
	If @error Then
		_WritingStuff_Exiting('', 'Error : cannot set config language files')
	EndIf

	_MultiLang_LoadLangFile($lang)
	If @error Then
		_WritingStuff_Exiting('', 'Error : cannot opening language files')
	EndIf

	$frmFakeGUI = GUICreate('FakeGUI', 0, 0)
	$Form1 = GUICreate($head, 615, 570, -1, -1, $DS_MODALFRAME, $WS_EX_TOPMOST, $frmFakeGUI)
	$Form2 = ''

	$Graphic1 = GUICtrlCreateGraphic(0, -2, 617, 129)
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	$Pic1 = GUICtrlCreatePic($rootdir & '\MyBrand.bmp', 16, 30, 64, 64)
	$Label7 = GUICtrlCreateLabel('Windows Update', 113, 39, 286, 46)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 28, 400, 0, 'Arial')
	GUICtrlSetColor(-1, 0x000000)
	$Label1 = GUICtrlCreateLabel(_MultiLang_GetText('Label1', 1), 55, 138, 500, 325)
	GUICtrlSetFont(-1, 12, 400, 0, 'Arial')
	GUICtrlSetColor(-1, 0x000000)
	$ButtonInstallEndWork = GUICtrlCreateButton(_MultiLang_GetText('ButtonInstallEndWork', 1), 40, 470, 129, 49, BitOR($BS_MULTILINE, $BS_DEFPUSHBUTTON))
	$ButtonRebootLater = GUICtrlCreateButton(_MultiLang_GetText('ButtonRebootLater', 1), 244, 470, 129, 49, $BS_MULTILINE)
	$ButtonReboot = GUICtrlCreateButton(_MultiLang_GetText('ButtonReboot', 1), 448, 470, 129, 49, $BS_MULTILINE)
	$Label18 = GUICtrlCreateLabel('Your IT-Team', 505, 522, 100, 20)
	GUICtrlSetFont(-1, 8, 400, 0, "Arial")
	GUICtrlSetColor(-1, 0x000000)
	GUISetState(@SW_SHOW)
	WinSetOnTop($Form1, '', $WINDOWS_ONTOP)
	WinWaitActive($Form1, '', 10)
	_WritingStuff_Exiting('', 'Show Gui')

	While 1
		$nMsg1 = GUIGetMsg($Form1)
		Switch $nMsg1
			Case $GUI_EVENT_CLOSE
				_WritingStuff_Exiting('Rebooting', '$GUI_EVENT_CLOSE 1, Rebooting')
				Sleep(100)
				Shutdown($SD_REBOOT + $SD_FORCE)

			Case $ButtonReboot
				_WritingStuff_Exiting('Rebooting', 'User choose reboot', 0)
				Sleep(100)
				Shutdown($SD_REBOOT + $SD_FORCE)

			Case $ButtonRebootLater
				GUIDelete($Form1)
				GUIDelete($Form2)
				$sEndWorkOrRebootLater = 'RebootLater'
				_WritingStuff_Exiting('RebootLater', 'User choose reboot Later')
				ExitLoop

			Case $ButtonInstallEndWork
				GUIDelete($Form1)
				GUIDelete($Form2)
				$sEndWorkOrRebootLater = 'RebootAtEndWork'
				_WritingStuff_Exiting('RebootAtEndWork', 'User choose Install at End Work')
				ExitLoop

		EndSwitch
	WEnd
EndFunc   ;==>_DisplayChoices

Func _ShowHidePowerButton($iShowHide) ; 1=show normal, 0=update and shutdown, -1=update and restart

	Local $iRestart = 0
	Local $iShutdown = 0
	Switch $iShowHide
		Case '-1'
			$iShowHide = Int(1) ; 0 to show, 1 to hide
			$iRestart = Int(0)  ; 0 to show, 1 to hide
			$iShutdown = Int(1) ; 0 to show, 1 to hide
		Case '0'
			$iShowHide = Int(1) ; 0 to show, 1 to hide
			$iRestart = Int(1)  ; 0 to show, 1 to hide
			$iShutdown = Int(0) ; 0 to show, 1 to hide
		Case '1'
			$iShowHide = Int(0) ; 0 to show, 1 to hide
			$iRestart = Int(0)  ; 0 to show, 1 to hide
			$iShutdown = Int(0) ; 0 to show, 1 to hide
	EndSwitch

	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideSignOut', 'value', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideSleep', 'value', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideSwitchAccount', 'value', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideLock', 'value', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideRestart', 'value', 'REG_DWORD', Int($iRestart))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideShutDown', 'value', 'REG_DWORD', Int($iShutdown))
	;
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideSignOut', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideSleep', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideSwitchAccount', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideLock', 'REG_DWORD', Int($iShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideRestart', 'REG_DWORD', Int($iRestart))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideShutDown', 'REG_DWORD', Int($iShutdown))
	;
	RegWrite('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'shutdownwithoutlogon', 'REG_DWORD', Not (Int($iShowHide))) ; 1 to show, 0 to hide
	If $iShowHide <> 0 Then
		RegWrite('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'ShutdownFlyoutOptions', 'REG_DWORD', 10) ; will display etiher Install and shut down OR Update and shutdown
		RegWrite('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'EnhancedShutdownEnabled', 'REG_DWORD', Int($iShowHide))
	Else
		RegWrite('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'ShutdownFlyoutOptions', 'REG_DWORD', Int($iShowHide))
		RegDelete('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'EnhancedShutdownEnabled')
	EndIf
EndFunc   ;==>_ShowHidePowerButton

Func _WaitToReboot($iParameter)
	_WritingStuff_Exiting('', 'In Func _WaitToReboot()', 0)
	Global $frmFakeGUI = GUICreate('FakeGUI', 0, 0)
	Global $g_hForm = GUICreate('Wait to reboot', 0, 0, 0, 0, $DS_MODALFRAME, -1, $frmFakeGUI)
	Global $iShutdownOrRestart = $iParameter ; 0=Shutdown , -1=reboot
	GUIRegisterMsg($WM_QUERYENDSESSION, 'WM_QUERYENDSESSION')
	WinSetTrans($g_hForm, 'Wait to reboot', 0)
	GUISetState(@SW_SHOW)

	; Set the highest shutdown priority for the current process to prevent closure the other processes.
	_WinAPI_SetProcessShutdownParameters(0x03FF)
	_WinAPI_ShutdownBlockReasonCreate($g_hForm, 'This application is blocking system shutdown because of WU.')

	While 1
		$nMsg3 = GUIGetMsg($g_hForm)
		Switch $nMsg3
			Case $GUI_EVENT_CLOSE
				_WritingStuff_Exiting('', '$GUI_EVENT_CLOSE 3', 0)
				_ShowHidePowerButton(1) ; 1=show normal, 0=update and shutdown, -1=update and restart
				If $iShutdownOrRestart = 0 Then ; 0=Shutdown , -1=reboot
					Run('SCHTASKS /create /tn "ManageWU\Shutdown" /tr "' & $rootdir & '\Shutdown.exe" /sc ONSTART /RU "SYSTEM" /RL "HIGHEST" /F')
				EndIf
				_WritingStuff_Exiting('UpToDate', '', 0)
				_WinAPI_ShutdownBlockReasonDestroy($g_hForm)
				Shutdown($SD_REBOOT + $SD_FORCE)
		EndSwitch
		_ShowHidePowerButton($iShutdownOrRestart)     ; 1=show normal, 0=update and shutdown, -1=update and restart
		Sleep(200)
	WEnd
EndFunc   ;==>_WaitToReboot

Func WM_QUERYENDSESSION($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $wParam, $lParam
	_WritingStuff_Exiting('', 'In Func WM_QUERYENDSESSION', 0)
	Switch $hWnd
		Case $g_hForm
			If _WinAPI_ShutdownBlockReasonQuery($g_hForm) Then
				_ShowHidePowerButton(1) ; 1=show normal, 0=update and shutdown, -1=update and restart
				If $iShutdownOrRestart = 0 Then ; 0=Shutdown , -1=reboot
					Run('SCHTASKS /create /tn "ManageWU\Shutdown" /tr "' & $rootdir & '\Shutdown.exe" /sc ONSTART /RU "SYSTEM" /RL "HIGHEST" /F')
				EndIf
				_WritingStuff_Exiting('UpToDate', '', 0)
				_WinAPI_ShutdownBlockReasonDestroy($g_hForm)
				Shutdown($SD_REBOOT + $SD_FORCE)
				Return 0
			EndIf
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_QUERYENDSESSION

Func _CleanFileLog()
	$IniDate = IniRead($sFileIni, 'LogFile', 'DateOfDeletion', '')
;~ 	Clean log file if older than 30 days
	If (($IniDate = '') Or (_DateAdd('D', -30, _NowCalcDate()) >= $IniDate)) Then
		FileDelete($sFileLog)
		IniWrite($sFileIni, 'LogFile', 'DateOfDeletion', _NowCalcDate())
		_WritingStuff_Exiting('', 'Log file cleared')
	Else
		_WritingStuff_Exiting('', 'No need to clean log file')
	EndIf
EndFunc   ;==>_CleanFileLog

Func _WritingStuff_Exiting($ssStatus = '', $ssOtherMessage = '', $eexit = 0)
	If $ssStatus <> '' Then IniWrite($sFileIni, 'Update', 'Status', $ssStatus)

	If $ssOtherMessage <> '' Then _FileWriteLog($sFileLog, $ssOtherMessage)

	_FileWriteLog($sFileLog, 'Status : ' & IniRead($sFileIni, 'Update', 'Status', 'Nothing'))

	If $eexit Then
		_FileWriteLog($sFileLog, 'Bye...')
		Exit
	EndIf
EndFunc   ;==>_WritingStuff_Exiting
