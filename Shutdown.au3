#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\sbg.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Shutdown @ reboot
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=Shutdown @ reboot
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_CompanyName=Société Biblique de Genève
#AutoIt3Wrapper_Res_LegalCopyright=2022 Société Biblique de Genève
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/reel
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#AutoIt3Wrapper_Run_Before=WriteTimestamp.exe "%in%"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Region ;Timestamp =====================
#                     2022/08/31 19:15:03
#EndRegion ;Timestamp =====================
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.16.0
	Author:         Marc Arm
	Date:			August 2022

	Script Function: Manage WU and reboot

	V1.0.0.0 : Inital relase

#ce ----------------------------------------------------------------------------

#include <AutoItConstants.au3>
#include <File.au3>

If @Compiled Then
	$rootdir = 'C:\Users\Public\Documents\ManageWU'
Else
	$rootdir = @ScriptDir
EndIf

$sFileLog = $rootdir & "\ManageWU.log"
_ShowHidePowerButton(1)
_FileWriteLog($sFileLog, 'In ' & @ScriptName)
Local $iPID = RunWait(@ComSpec & " /c " & 'SCHTASKS /Delete /TN "SBGMB\shutdown" /F', @SystemDir, @SW_HIDE)
Sleep(5000)
_FileWriteLog($sFileLog, 'Shutting down...')
Shutdown($SD_SHUTDOWN + $SD_FORCE)

Func _ShowHidePowerButton($bShowHide) ; 1 to show, 0 to hide
	$bShowHide = Not ($bShowHide) ; 0 to show, 1 to hide
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideSignOut', 'value', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideSleep', 'value', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideSwitchAccount', 'value', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideLock', 'value', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\default\Start\HideRestart', 'value', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideSignOut', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideSleep', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideSwitchAccount', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideLock', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start', 'HideRestart', 'REG_DWORD', Int($bShowHide))
	RegWrite('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System', 'shutdownwithoutlogon', 'REG_DWORD', Not (Int($bShowHide))) ; 1 to show, 0 to hide
	If $bShowHide Then
		RegWrite('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'ShutdownFlyoutOptions', 'REG_DWORD', 10) ; will display Install and shut down
		RegWrite('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'EnhancedShutdownEnabled', 'REG_DWORD', Int($bShowHide))
	Else
		RegWrite('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'ShutdownFlyoutOptions', 'REG_DWORD', Int($bShowHide))
		RegDelete('HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator', 'EnhancedShutdownEnabled')
	EndIf
EndFunc   ;==>_ShowHidePowerButton
