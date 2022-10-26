#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/reel
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once
;=======================================================
;	Name:			MultiLang.au3
;	Description:	A way to create multi-language GUIs
;					IT WILL NOT AUTOMATICALLY TRANSLATE
;					YOUR GUIS, rather it will select
;					the appropriate language for you
;					to load
;	Author:			Brett Francis (BrettF)
;	Website:		http://www.signa5.com
;	Last Updated:	14 August 2010
;=======================================================

;=======================================================
;	Declare Global Variables
;=======================================================
;Global Handles
Global $_gh_aLangFileArray = -1
Global $_gh_sLangFileSelected = -1
Global $_gh_sLangFileData = -1

;=======================================================
;	Name:			_MultiLang_SetFileInfo($aLangFileArray)
;	Description:	Sets the loadable languages for use
;	Author:			Brett Francis (BrettF)
;	Parameters:		$aLangFileArray
;						Array containg:
;						[n][0] = Display Name in Local
;								 Language
; 						[n][1] = Language File (Full
;								 path.
; 						[n][2] = Character codes as
;								 used by @OS_LANG
;								 [Space delimited]
;	Returns:		Success = 1
;					Failure = 0
;	@error Codes:	1 = $aLangFileArray is not an array
;					2 = $aLangFileArray is malformed
;	Website:		http://www.signa5.com
;	Last Updated:	14 August 2010
;=======================================================
Func __MultiLang_SetFileInfo($aLangFileArray)
	If IsArray($aLangFileArray) = 0 Then Return SetError(1, 0, 0)
	If UBound($aLangFileArray, 0) <> 2 Then Return SetError(2, 0, 0)
	If UBound($aLangFileArray, 2) <> 3 Then Return SetError(2, 0, 0)
	$_gh_aLangFileArray = $aLangFileArray
	Return 1
EndFunc   ;==>__MultiLang_SetFileInfo

;=======================================================
;	Name:			_MultiLang_LoadLangFile($nLangCode)
;	Description:	Sets the loadable languages for use
;	Author:			Brett Francis (BrettF)
;	Parameters:		$nLangCode
;						Character codes as used by @OS_LANG
;	Returns:		Success = 1 File was opened
;							  2 Default language file
;								was opened.  Usually
;								caused by incorrect value
;								of $nLangCode
;					Failure = 0
;	@error Codes:	1 = _MultiLang_SetFileInfo has not
;						been called or the array is
;						malformed
;					2 = Could not open language file
;	Website:		http://www.signa5.com
;	Last Updated:	14 August 2010
;=======================================================
Func _MultiLang_LoadLangFile($nLangCode)
	Local $ret = 1
	$_gh_sLangFileSelected = -1
	If $_gh_aLangFileArray = -1 Then Return SetError(1, 0, 0)
	If IsArray($_gh_aLangFileArray) = 0 Then Return SetError(1, 0, 0)
	For $i = 0 To UBound($_gh_aLangFileArray) - 1
		If StringInStr($_gh_aLangFileArray[$i][2], $nLangCode) Then
			$_gh_sLangFileSelected = $_gh_aLangFileArray[$i][1]
			ExitLoop
		EndIf
	Next
	If $_gh_sLangFileSelected == -1 Then
		$_gh_sLangFileSelected = $_gh_aLangFileArray[0][1]
		$ret = 2 ;Lets user know we loaded the default
	EndIf

	$_gh_sLangFileData = FileRead($_gh_sLangFileSelected)
	If @error Then Return SetError(2, 0, 0)
	Return $ret
EndFunc   ;==>_MultiLang_LoadLangFile

;=======================================================
;	Name:			_MultiLang_GetText($sControl, $multiline = 0, $default = @OSLang)
;	Description:	Sets the loadable languages for use
;	Author:			Brett Francis (BrettF)
;	Parameters:		$sControl
;						Tag to read
;					$multiline [Default = 0]
;						= 1 	Replace
;									"@CRLF"
;									"@LF"
;									"@CR"
;								With proper characters.
;					$default [Default = "Unknown Text"]
;						What text to return when the
;						value could not be found in the
;						language file
;	Returns:		Success = Loaded text
;					Failure = 0
;	@error Codes:	1 = _MultiLang_SetFileInfo has not
;						been called or the array is
;						malformed
;					2 = _MultiLang_LoadLangFile has not
;						been called
;					3 = Tag could not be found.
;						Default value loaded. ($default)
;	Website:		http://www.signa5.com
;	Last Updated:	14 August 2010
;=======================================================
Func _MultiLang_GetText($sControl, $multiline = 0, $default = "Unknown Text")
	If $_gh_aLangFileArray = -1 Then Return SetError(1, 0, 0)
	If IsArray($_gh_aLangFileArray) = 0 Then Return SetError(1, 0, 0)
	If $_gh_sLangFileData = -1 Then Return SetError(2, 0, 0)
	Local $a_ret = StringRegExp($_gh_sLangFileData, '<(?i)' & $sControl & '>(.*?)</(?i)' & $sControl & '>', 3)
	If Not @error Then
		$a_ret = StringStripWS($a_ret[0], 2)
		If $multiline = 1 Then
			$a_ret = StringReplace($a_ret, "@CRLF", @CRLF)
			$a_ret = StringReplace($a_ret, "@LF", @LF)
			$a_ret = StringReplace($a_ret, "@CR", @CR)
		EndIf
		Return $a_ret
	EndIf
	Return SetError(3, 0, $default)
EndFunc   ;==>_MultiLang_GetText

;=======================================================
;	Name:			_MultiLang_SelectGUI($title, $text, $default = @OSLang)
;	Description:	Sets the loadable languages for use
;	Author:			Brett Francis (BrettF)
;	Parameters:		$title
;						Title of the GUI
;					$text
;						Prompt for user
;					$default = @OSLang
;						Default to load when user does
;						not select a valid value.
;	Returns:		Success = Returns Language Code
;					Failure = 0
;	@error Codes:	1 = _MultiLang_SetFileInfo has not
;						been called or the array is
;						malformed
;	Website:		http://www.signa5.com
;	Last Updated:	14 August 2010
;=======================================================
Func _MultiLang_SelectGUI($title, $text, $default = @OSLang)
	If $_gh_aLangFileArray = -1 Then Return SetError(1, 0, 0)
	If IsArray($_gh_aLangFileArray) = 0 Then Return SetError(1, 0, 0)
	$_multilang_gui_GUI = GUICreate($title, 230, 100)
	$_multilang_gui_Combo = GUICtrlCreateCombo("(Select A Language)", 8, 48, 209, 25, 0x0003)
	$_multilang_gui_Button = GUICtrlCreateButton("Select", 144, 72, 75, 25)
	$_multilang_gui_Label = GUICtrlCreateLabel($text, 8, 8, 212, 33)

	;Create List of available languages
	For $i = 0 To UBound($_gh_aLangFileArray) - 1
		GUICtrlSetData($_multilang_gui_Combo, $_gh_aLangFileArray[$i][0], "(Select A Language)")
	Next

	GUISetState(@SW_SHOW)
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case -3, $_multilang_gui_Button
				ExitLoop
		EndSwitch
	WEnd
	$_selected = GUICtrlRead($_multilang_gui_Combo)
	GUIDelete($_multilang_gui_GUI)
	For $i = 0 To UBound($_gh_aLangFileArray) - 1
		If StringInStr($_gh_aLangFileArray[$i][0], $_selected) Then
			Return StringLeft($_gh_aLangFileArray[$i][2], 4)
		EndIf
	Next
	Return $default
EndFunc   ;==>_MultiLang_SelectGUI

;=======================================================
;	Name:			_MultiLang_Close()
;	Description:	Resets all opened variables.
;	Author:			Brett Francis (BrettF)
;	Parameters:		None
;	Returns:		Nothing
;	@error Codes:	None
;	Website:		http://www.signa5.com
;	Last Updated:	14 August 2010
;=======================================================
Func _MultiLang_Close()
	$_gh_aLangFileArray = -1
	$_gh_sLangFileSelected = -1
	$_gh_sLangFileData = -1
EndFunc   ;==>_MultiLang_Close

Func _MultiLang_Config($LANG_DIR)

	;Create an array of available language files
	; ** n=0 is the default language file
	; [n][0] = Display Name in Local Language (Used for Select Function)
	; [n][1] = Language File (Full path.  In this case we used a $LANG_DIR
	; [n][2] = [Space delimited] Character codes as used by @OS_LANG (used to select correct lang file)
	Local $LANGFILES[3][3]

	$LANGFILES[0][0] = "English (US)" ;
	$LANGFILES[0][1] = $LANG_DIR & "\ENGLISH.XML"
	$LANGFILES[0][2] = "0409 " & _ ;English_United_States
			"0809 " & _ ;English_United_Kingdom
			"0c09 " & _ ;English_Australia
			"1009 " & _ ;English_Canadian
			"1409 " & _ ;English_New_Zealand
			"1809 " & _ ;English_Irish
			"1c09 " & _ ;English_South_Africa
			"2009 " & _ ;English_Jamaica
			"2409 " & _ ;English_Caribbean
			"2809 " & _ ;English_Belize
			"2c09 " & _ ;English_Trinidad
			"3009 " & _ ;English_Zimbabwe
			"3409" ;English_Philippines

	$LANGFILES[1][0] = "Français"     ; French
	$LANGFILES[1][1] = $LANG_DIR & "\FRENCH.XML"
	$LANGFILES[1][2] = "040c " & _ ;French_Standard
			"080c " & _ ;French_Belgian
			"0c0c " & _ ;French_Canadian
			"100c " & _ ;French_Swiss
			"140c " & _ ;French_Luxembourg
			"180c" ;French_Monaco

	$LANGFILES[2][0] = "Deutsch" ; German
	$LANGFILES[2][1] = $LANG_DIR & "\GERMAN.XML"
	$LANGFILES[2][2] = "0407 " & _ ;German_Standard
			"0807 " & _ ;German_Swiss
			"0c07 " & _ ;German_Austrian
			"1007 " & _ ;German_Luxembourg
			"1407" ;German_Liechtenstein

	;Set the available language files, names, and codes.
	__MultiLang_SetFileInfo($LANGFILES)
	If @error Then
		MsgBox(48, "Error", "Could not set file info.  Error Code " & @error)
		Exit
	EndIf
EndFunc   ;==>_Config_Lang
