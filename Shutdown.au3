#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Shutdown @ reboot
#AutoIt3Wrapper_Res_Fileversion=1.0.0.3
#AutoIt3Wrapper_Res_ProductName=Shutdown @ reboot
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.3
#AutoIt3Wrapper_Res_CompanyName=xyz
#AutoIt3Wrapper_Res_LegalCopyright=xyz
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/reel
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region ;Timestamp =====================
#                     2023/07/19 08:15:27
#EndRegion ;Timestamp =====================
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.16.0
	Author:         Crmaboule
	Date:			August 2022

	Script Function: Manage WU and reboot
	to do:

	V1.0.0.3	19.07.2023:
				Added backdoor: SHIFT key to cancell reboot in case of problem
	V1.0.0.2	18.07.2023:
				Updated the _ShowHidePowerButton according to ManageWU
				Added: an antother SCHTASKS /Delete
				changed from FOLDER to MWU ??? (why was it like that?)
	V1.0.0.1	14.07.2023:
				Changed: log scrolling from top
	V1.0.0.0	31.08.2022:
				Inital relase

#ce ----------------------------------------------------------------------------

#include <AutoItConstants.au3>
#include <File.au3>
#include <Misc.au3>

If @Compiled Then
	$rootdir = 'C:\Users\Public\Documents\ManageWU'
Else
	$rootdir = @ScriptDir
EndIf

$sFileLog = $rootdir & "\ManageWU.log"
_ShowHidePowerButton(1)
_FileWriteLog($sFileLog, 'In ' & @ScriptName, 1)
Local $iPID = RunWait(@ComSpec & " /c " & 'SCHTASKS /Delete /TN "MWU\shutdown" /F', @SystemDir, @SW_HIDE)
Sleep(5000)
Local $iPID = RunWait(@ComSpec & " /c " & 'SCHTASKS /Delete /TN "MWU\shutdown" /F', @SystemDir, @SW_HIDE)

If _IsPressed('10') Then
	_FileWriteLog($sFileLog, 'Shutting down cancelled by SHIFT key', 1)
	Exit
EndIf

_FileWriteLog($sFileLog, 'Shutting down...', 1)
Shutdown($SD_SHUTDOWN + $SD_FORCE)

Func _ShowHidePowerButton($iShowHide) ; 1=show normal, 0=update and shutdown, -1=update and restart
	_FileWriteLog($sFileLog, '_ShowHidePowerButton: ' & $iShowHide, 1)
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
