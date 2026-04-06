#include <GUIConstantsEx.au3>
#include <AutoItConstants.au3>
#include <ComboConstants.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ScreenCapture.au3>
#include <WinAPI.au3>
#include <WinAPIGdi.au3>
#include <Misc.au3>

Opt("GUIOnEventMode", 1)
Opt("MustDeclareVars", 1)

Global Const $DEFAULT_FPS = 30
Global Const $WDA_EXCLUDEFROMCAPTURE = 0x00000011
Global Const $MAIN_STYLE = BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU, $WS_MINIMIZEBOX)
Global Const $PREVIEW_STYLE_NORMAL = BitOR($WS_MINIMIZEBOX, $WS_CAPTION, $WS_POPUP, $WS_SYSMENU)
Global Const $BORDER = 12
Global Const $MAIN_WIDTH = 700
Global Const $MAIN_HEIGHT = 170
Global Const $MAIN_PADDING = $BORDER
Global Const $INFO_HEIGHT = 20
Global Const $INFO_TOP = $MAIN_HEIGHT - $INFO_HEIGHT
Global Const $PREVIEW_WIDTH = 676
Global Const $PREVIEW_HEIGHT = 412
Global Const $PREVIEW_WINDOW_GAP = 16
Global Const $SETTINGS_INI = @ScriptDir & "\DesktopRender.ini"
Global Const $SETTINGS_SECTION = "Selection"
Global Const $SETTINGS_UI_SECTION = "UI"
Global Const $SETTINGS_PROFILE_PREFIX = "Profile_"
Global Const $BTN_TOP = $BORDER
Global Const $BTN_HEIGHT = 30
Global Const $BTN_SELECT_LEFT = $BORDER
Global Const $BTN_SELECT_WIDTH = 150
Global Const $BTN_PAUSE_LEFT = 174
Global Const $BTN_PAUSE_WIDTH = 90
Global Const $BTN_RECORD_LEFT = 276
Global Const $BTN_RECORD_WIDTH = 110
Global Const $BTN_RECORDINGS_LEFT = 398
Global Const $BTN_RECORDINGS_WIDTH = 210
Global Const $CHK_TOP_TOP = 52
Global Const $CHK_TOP_LEFT = 144
Global Const $CHK_TOP_WIDTH = 140
Global Const $SECOND_ROW_TOP = 52
Global Const $CHK_AFFINITY_LEFT = $BORDER
Global Const $CHK_AFFINITY_WIDTH = 120
Global Const $CHK_FOLLOW_LEFT = 296
Global Const $CHK_FOLLOW_WIDTH = 110
Global Const $CHK_ACTIVE_LEFT = 418
Global Const $CHK_ACTIVE_WIDTH = 110
Global Const $CHK_NEXT_ACTIVE_LEFT = 540
Global Const $CHK_NEXT_ACTIVE_WIDTH = 136
Global Const $CHK_HEIGHT = 20
Global Const $THIRD_ROW_TOP = 82
Global Const $LBL_PROFILE_LEFT = $BORDER
Global Const $LBL_PROFILE_TOP = $THIRD_ROW_TOP + 4
Global Const $LBL_PROFILE_WIDTH = 60
Global Const $CMB_PROFILE_LEFT = 78
Global Const $CMB_PROFILE_TOP = $THIRD_ROW_TOP
Global Const $CMB_PROFILE_WIDTH = 170
Global Const $CMB_PROFILE_HEIGHT = 25
Global Const $LBL_REFRESH_LEFT = 270
Global Const $LBL_REFRESH_TOP = $THIRD_ROW_TOP + 4
Global Const $LBL_REFRESH_WIDTH = 20
Global Const $CMB_REFRESH_LEFT = 300
Global Const $CMB_REFRESH_TOP = $THIRD_ROW_TOP
Global Const $CMB_REFRESH_WIDTH = 72
Global Const $CMB_REFRESH_HEIGHT = 25
Global Const $FOURTH_ROW_TOP = 116
Global Const $LBL_RECORD_LEFT = $BORDER
Global Const $LBL_RECORD_TOP = $FOURTH_ROW_TOP + 2
Global Const $LBL_RECORD_WIDTH = $MAIN_WIDTH - ($BORDER * 2)
Global Const $RECORDINGS_DIR = @ScriptDir & "\recordings"

Global $g_hMain = 0
Global $g_idInfo = 0
Global $g_hPreview = 0
Global $g_idBtnSelect = 0
Global $g_idBtnPause = 0
Global $g_idBtnRecord = 0
Global $g_idBtnRecordings = 0
Global $g_idLblProfile = 0
Global $g_idCmbProfile = 0
Global $g_idLblRefresh = 0
Global $g_idCmbFps = 0
Global $g_idChkTop = 0
Global $g_idChkAffinity = 0
Global $g_idChkFollowMouse = 0
Global $g_idChkFollowActive = 0
Global $g_idChkFollowActiveNextOnly = 0
Global $g_idLblRecord = 0
Global $g_hPreviewDC = 0
Global $g_hBackDC = 0
Global $g_hBackBitmap = 0
Global $g_hBackBitmapOld = 0
Global $g_iPreviewW = 0
Global $g_iPreviewH = 0

Global $g_iSelX = -1
Global $g_iSelY = -1
Global $g_iSelW = 0
Global $g_iSelH = 0
Global $g_bPaused = False
Global $g_bRunning = True
Global $g_hRefreshTimer = 0
Global $g_bCfgTopmost = True
Global $g_bCfgAffinity = True
Global $g_bCfgFollowMouse = False
Global $g_bCfgFollowActive = False
Global $g_bCfgFollowActiveNextOnly = True
Global $g_iCfgMainX = Default
Global $g_iCfgMainY = Default
Global $g_iCfgPreviewX = Default
Global $g_iCfgPreviewY = Default
Global $g_iCfgPreviewW = $PREVIEW_WIDTH
Global $g_iCfgPreviewH = $PREVIEW_HEIGHT
Global $g_iFps = $DEFAULT_FPS
Global $g_sCfgProfile = "Whatsapp"
Global $g_sCfgRecordFormat = "mp4"
Global $g_sCfgRecordCodec = "libx264"
Global $g_sCfgRecordCodecArgs = " -preset ultrafast -pix_fmt yuv420p "
Global $g_sCfgRecordContainerArgs = " -movflags +faststart "
Global $g_bRecording = False
Global $g_iRecordingPid = 0
Global $g_sRecordingFile = ""
Global $g_hFollowActiveTarget = 0

_LoadUiSettingsFromIni()
_LoadSelectionFromIni()
_CreateMainWindow()
GUIRegisterMsg($WM_ERASEBKGND, "App_WMEraseBkgnd")
$g_hRefreshTimer = TimerInit()

While $g_bRunning
    If TimerDiff($g_hRefreshTimer) >= _GetRefreshIntervalMs() Then
        _RefreshPreview()
        $g_hRefreshTimer = TimerInit()
    EndIf
    Sleep(10)
WEnd

_SaveAllSettingsToIni()
_StopRecording(False)
_DestroyBackBuffer()
If $g_hPreview <> 0 Then GUIDelete($g_hPreview)
GUIDelete($g_hMain)

Func _CreateMainWindow()
    $g_hMain = GUICreate("DesktopRender", $MAIN_WIDTH, $MAIN_HEIGHT, $g_iCfgMainX, $g_iCfgMainY, $MAIN_STYLE, $WS_EX_COMPOSITED)
    GUISetOnEvent($GUI_EVENT_CLOSE, "_OnMainClose", $g_hMain)

    $g_idBtnSelect = GUICtrlCreateButton("Selectionner une zone", $BTN_SELECT_LEFT, $BTN_TOP, $BTN_SELECT_WIDTH, $BTN_HEIGHT)
    $g_idBtnPause = GUICtrlCreateButton("Pause", $BTN_PAUSE_LEFT, $BTN_TOP, $BTN_PAUSE_WIDTH, $BTN_HEIGHT)
    $g_idBtnRecord = GUICtrlCreateButton("Enregistrer", $BTN_RECORD_LEFT, $BTN_TOP, $BTN_RECORD_WIDTH, $BTN_HEIGHT)
    $g_idBtnRecordings = GUICtrlCreateButton("Aller au dossier enregistrements", $BTN_RECORDINGS_LEFT, $BTN_TOP, $BTN_RECORDINGS_WIDTH, $BTN_HEIGHT)
    $g_idChkTop = GUICtrlCreateCheckbox("Toujours au premier plan", $CHK_TOP_LEFT, $CHK_TOP_TOP, $CHK_TOP_WIDTH, $CHK_HEIGHT)
    $g_idChkAffinity = GUICtrlCreateCheckbox("Exclure de la capture", $CHK_AFFINITY_LEFT, $SECOND_ROW_TOP, $CHK_AFFINITY_WIDTH, $CHK_HEIGHT)
    $g_idChkFollowMouse = GUICtrlCreateCheckbox("Suivre la souris", $CHK_FOLLOW_LEFT, $SECOND_ROW_TOP, $CHK_FOLLOW_WIDTH, $CHK_HEIGHT)
    $g_idChkFollowActive = GUICtrlCreateCheckbox("Suivre fenetre", $CHK_ACTIVE_LEFT, $SECOND_ROW_TOP, $CHK_ACTIVE_WIDTH, $CHK_HEIGHT)
    $g_idChkFollowActiveNextOnly = GUICtrlCreateCheckbox("Seulement la prochaine", $CHK_NEXT_ACTIVE_LEFT, $SECOND_ROW_TOP, $CHK_NEXT_ACTIVE_WIDTH, $CHK_HEIGHT)
    $g_idLblProfile = GUICtrlCreateLabel("Profil video", $LBL_PROFILE_LEFT, $LBL_PROFILE_TOP, $LBL_PROFILE_WIDTH, $INFO_HEIGHT)
    $g_idCmbProfile = GUICtrlCreateCombo("", $CMB_PROFILE_LEFT, $CMB_PROFILE_TOP, $CMB_PROFILE_WIDTH, $CMB_PROFILE_HEIGHT, $CBS_DROPDOWNLIST)
    $g_idLblRefresh = GUICtrlCreateLabel("Fps", $LBL_REFRESH_LEFT, $LBL_REFRESH_TOP, $LBL_REFRESH_WIDTH, $INFO_HEIGHT)
    $g_idCmbFps = GUICtrlCreateCombo("", $CMB_REFRESH_LEFT, $CMB_REFRESH_TOP, $CMB_REFRESH_WIDTH, $CMB_REFRESH_HEIGHT, $CBS_DROPDOWNLIST)
    GUICtrlSetOnEvent($g_idBtnSelect, "_OnPickRegion")
    GUICtrlSetOnEvent($g_idBtnPause, "_OnTogglePause")
    GUICtrlSetOnEvent($g_idBtnRecord, "_OnToggleRecording")
    GUICtrlSetOnEvent($g_idBtnRecordings, "_OnOpenRecordingsFolder")
    GUICtrlSetOnEvent($g_idCmbProfile, "_OnChangeProfile")
    GUICtrlSetOnEvent($g_idCmbFps, "_OnChangeFps")
    GUICtrlSetOnEvent($g_idChkTop, "_OnToggleTopmost")
    GUICtrlSetOnEvent($g_idChkAffinity, "_OnToggleAffinity")
    GUICtrlSetOnEvent($g_idChkFollowMouse, "_OnToggleFollowMouse")
    GUICtrlSetOnEvent($g_idChkFollowActive, "_OnToggleFollowActive")
    GUICtrlSetOnEvent($g_idChkFollowActiveNextOnly, "_OnToggleFollowActiveNextOnly")
    GUICtrlSetResizing($g_idBtnSelect, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idBtnPause, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idBtnRecord, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idBtnRecordings, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idLblProfile, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idCmbProfile, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idLblRefresh, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idCmbFps, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idChkTop, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idChkAffinity, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idChkFollowMouse, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idChkFollowActive, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idChkFollowActiveNextOnly, $GUI_DOCKALL)
    If $g_bCfgTopmost Then GUICtrlSetState($g_idChkTop, $GUI_CHECKED)
    If $g_bCfgAffinity Then GUICtrlSetState($g_idChkAffinity, $GUI_CHECKED)
    If $g_bCfgFollowMouse Then GUICtrlSetState($g_idChkFollowMouse, $GUI_CHECKED)
    If $g_bCfgFollowActive Then GUICtrlSetState($g_idChkFollowActive, $GUI_CHECKED)
    If $g_bCfgFollowActiveNextOnly Then GUICtrlSetState($g_idChkFollowActiveNextOnly, $GUI_CHECKED)
    GUICtrlSetData($g_idCmbProfile, "Whatsapp|HighQuality|mobile", $g_sCfgProfile)
    GUICtrlSetData($g_idCmbFps, "10|24|30|60", String($g_iFps))
    _UpdateFollowActiveNextOnlyUi()

    $g_idInfo = GUICtrlCreateLabel("", $MAIN_PADDING, $INFO_TOP, $PREVIEW_WIDTH, $INFO_HEIGHT)
    $g_idLblRecord = GUICtrlCreateLabel("", $LBL_RECORD_LEFT, $LBL_RECORD_TOP, $LBL_RECORD_WIDTH, $INFO_HEIGHT)

	GUICtrlSetResizing($g_idInfo, $GUI_DOCKALL)
    GUICtrlSetResizing($g_idLblRecord, $GUI_DOCKALL)
    GUICtrlSetFont($g_idLblProfile, 9, 400, 0, "Segoe UI")
    GUICtrlSetFont($g_idCmbProfile, 9, 400, 0, "Segoe UI")
    GUICtrlSetFont($g_idLblRefresh, 9, 400, 0, "Segoe UI")
    GUICtrlSetFont($g_idCmbFps, 9, 400, 0, "Segoe UI")
    GUICtrlSetFont($g_idInfo, 9, 400, 0, "Segoe UI")
    GUICtrlSetFont($g_idLblRecord, 9, 400, 0, "Segoe UI")

    Local $aPreviewSize = _GetWindowSizeForClient($g_iCfgPreviewW, $g_iCfgPreviewH, $PREVIEW_STYLE_NORMAL, $WS_EX_COMPOSITED)
    $g_hPreview = GUICreate("DesktopRender Preview", $aPreviewSize[0], $aPreviewSize[1], $g_iCfgPreviewX, $g_iCfgPreviewY, $PREVIEW_STYLE_NORMAL, $WS_EX_COMPOSITED)
    GUISetOnEvent($GUI_EVENT_CLOSE, "_OnPreviewClose", $g_hPreview)
    GUISetBkColor(0x000000, $g_hPreview)
    _EnableDoubleBuffering($g_hPreview)
    _ResizeBackBuffer($g_iCfgPreviewW, $g_iCfgPreviewH)

    WinSetOnTop($g_hMain, "", 1)
    WinSetOnTop($g_hPreview, "", 1)
    _EnableDoubleBuffering($g_hMain)
    _UpdateInfo()
    GUISetState(@SW_SHOW, $g_hMain)
    If $g_iCfgPreviewX = Default Or $g_iCfgPreviewY = Default Then _PositionPreviewWindow()
    GUISetState(@SW_SHOW, $g_hPreview)
    _ApplyWindowAffinity($g_hMain)
    If $g_iSelW > 0 And $g_iSelH > 0 Then _ResizeMainToRegion()
EndFunc

Func _UpdateInfo()
    Local $sState = "actif"
    Local $bTrackedWindow = False
    If $g_bPaused Then $sState = "pause"
    If $g_idChkFollowMouse <> 0 And GUICtrlRead($g_idChkFollowMouse) = $GUI_CHECKED Then $sState &= " | suivi souris"
    If $g_idChkFollowActive <> 0 And GUICtrlRead($g_idChkFollowActive) = $GUI_CHECKED Then $sState &= " | suivi fenetre"
    If $g_bRecording Then $sState &= ", enregistrement"

    If $g_idChkFollowActive <> 0 And GUICtrlRead($g_idChkFollowActive) = $GUI_CHECKED And _
       $g_idChkFollowActiveNextOnly <> 0 And GUICtrlRead($g_idChkFollowActiveNextOnly) = $GUI_CHECKED And _
       $g_hFollowActiveTarget <> 0 And WinExists($g_hFollowActiveTarget) Then
        $bTrackedWindow = True
    EndIf

    If $g_iSelW <= 0 Or $g_iSelH <= 0 Then
        Local $sEmptyInfo = "Aucune zone definie. Clique sur 'Selectionner une zone', puis trace un rectangle sur l'ecran."
        If $bTrackedWindow Then $sEmptyInfo &= " | Fenetre suivie"
        GUICtrlSetData($g_idInfo, $sEmptyInfo)
        _UpdateRecordingInfo()
        Return
    EndIf

    Local $sInfo = "Zone: X=" & $g_iSelX & " Y=" & $g_iSelY & " L=" & $g_iSelW & " H=" & $g_iSelH & " | Fps: " & $g_iFps & " | Etat: " & $sState
    If $bTrackedWindow Then $sInfo &= " | Fenetre suivie"
    GUICtrlSetData($g_idInfo, $sInfo)
    _UpdateRecordingInfo()
EndFunc

Func _OnMainClose()
    $g_bRunning = False
EndFunc

Func _OnPreviewClose()
    $g_bRunning = False
EndFunc

Func _OnPickRegion()
    If $g_bRecording Then _StopRecording(True)
    _PickRegion()
EndFunc

Func _OnTogglePause()
    $g_bPaused = Not $g_bPaused
    If $g_bPaused Then
        GUICtrlSetData($g_idBtnPause, "Reprendre")
    Else
        GUICtrlSetData($g_idBtnPause, "Pause")
    EndIf
    _UpdateInfo()
EndFunc

Func _OnToggleRecording()
    If $g_bRecording Then
        _StopRecording(True)
    Else
        _StartRecording()
    EndIf
    _UpdateInfo()
EndFunc

Func _OnOpenRecordingsFolder()
    DirCreate($RECORDINGS_DIR)
    ShellExecute($RECORDINGS_DIR)
EndFunc

Func _OnChangeProfile()
    Local $sProfile = _NormalizeProfileName(GUICtrlRead($g_idCmbProfile))
    If $sProfile = $g_sCfgProfile Then Return

    If $g_bRecording Then _StopRecording(True)

    $g_sCfgProfile = $sProfile
    _LoadRecordProfileFromIni($g_sCfgProfile)
    GUICtrlSetData($g_idCmbProfile, $g_sCfgProfile)
    _SaveAllSettingsToIni()
    _UpdateInfo()
EndFunc

Func _OnChangeFps()
    $g_iFps = _NormalizeFps(GUICtrlRead($g_idCmbFps))
    GUICtrlSetData($g_idCmbFps, String($g_iFps))
    $g_hRefreshTimer = TimerInit()
    _UpdateInfo()
    _SaveAllSettingsToIni()
EndFunc

Func _OnToggleTopmost()
    If GUICtrlRead($g_idChkTop) = $GUI_CHECKED Then
        WinSetOnTop($g_hMain, "", 1)
        If $g_hPreview <> 0 Then WinSetOnTop($g_hPreview, "", 1)
    Else
        WinSetOnTop($g_hMain, "", 0)
        If $g_hPreview <> 0 Then WinSetOnTop($g_hPreview, "", 0)
    EndIf
    _SaveAllSettingsToIni()
EndFunc

Func _OnToggleAffinity()
    _ApplyWindowAffinity($g_hMain)
    _SaveAllSettingsToIni()
EndFunc

Func _OnToggleFollowMouse()
    If GUICtrlRead($g_idChkFollowMouse) = $GUI_CHECKED Then
        If $g_idChkFollowActive <> 0 Then
            GUICtrlSetState($g_idChkFollowActive, $GUI_UNCHECKED)
            $g_hFollowActiveTarget = 0
            _UpdateFollowActiveNextOnlyUi()
        EndIf
        If $g_bRecording Then
            _StopRecording(True)
            MsgBox(48, "DesktopRender", "Le mode 'Suivre la souris' n'est pas compatible avec l'enregistrement de zone fixe.")
        EndIf
    EndIf
    _UpdateInfo()
    _SaveAllSettingsToIni()
EndFunc

Func _OnToggleFollowActive()
    If GUICtrlRead($g_idChkFollowActive) = $GUI_CHECKED Then
        If $g_idChkFollowMouse <> 0 Then GUICtrlSetState($g_idChkFollowMouse, $GUI_UNCHECKED)
        If $g_bRecording Then
            _StopRecording(True)
            MsgBox(48, "DesktopRender", "Le mode 'Suivre la fenetre active' n'est pas compatible avec l'enregistrement de zone fixe.")
        EndIf
        $g_hFollowActiveTarget = 0
        _UpdateFollowActiveNextOnlyUi()
        _UpdateFollowActiveWindowRegion()
    Else
        $g_hFollowActiveTarget = 0
        _UpdateFollowActiveNextOnlyUi()
    EndIf
    _UpdateInfo()
    _SaveAllSettingsToIni()
EndFunc

Func _OnToggleFollowActiveNextOnly()
    $g_hFollowActiveTarget = 0
    _UpdateInfo()
    _SaveAllSettingsToIni()
EndFunc

Func _PickRegion()
    Local $iOldPause = $g_bPaused
    Local $iOldX = $g_iSelX
    Local $iOldY = $g_iSelY
    Local $iOldW = $g_iSelW
    Local $iOldH = $g_iSelH
    $g_bPaused = True
    GUICtrlSetData($g_idBtnPause, "Reprendre")
    Local $aRegion = _SelectScreenRegion()

    If Not IsArray($aRegion) Then
        $g_iSelX = $iOldX
        $g_iSelY = $iOldY
        $g_iSelW = $iOldW
        $g_iSelH = $iOldH
        If $g_iSelW > 0 And $g_iSelH > 0 Then
            _ResizeMainToRegion()
            _PresentFrame()
        EndIf
        $g_bPaused = $iOldPause
        If $g_bPaused Then
            GUICtrlSetData($g_idBtnPause, "Reprendre")
        Else
            GUICtrlSetData($g_idBtnPause, "Pause")
        EndIf
        _UpdateInfo()
        Return
    EndIf

    $g_iSelX = $aRegion[0]
    $g_iSelY = $aRegion[1]
    $g_iSelW = $aRegion[2]
    $g_iSelH = $aRegion[3]
    If $g_idChkFollowMouse <> 0 Then GUICtrlSetState($g_idChkFollowMouse, $GUI_UNCHECKED)
    If $g_idChkFollowActive <> 0 Then GUICtrlSetState($g_idChkFollowActive, $GUI_UNCHECKED)
    $g_hFollowActiveTarget = 0
    _UpdateFollowActiveNextOnlyUi()
    _SaveAllSettingsToIni()
    $g_bPaused = False
    GUICtrlSetData($g_idBtnPause, "Pause")

    _ResizeMainToRegion()
    _UpdateInfo()
    _RefreshPreview()
EndFunc

Func _LoadSelectionFromIni()
    Local $iX = Int(IniRead($SETTINGS_INI, $SETTINGS_SECTION, "x", "-1"))
    Local $iY = Int(IniRead($SETTINGS_INI, $SETTINGS_SECTION, "y", "-1"))
    Local $iW = Int(IniRead($SETTINGS_INI, $SETTINGS_SECTION, "w", "0"))
    Local $iH = Int(IniRead($SETTINGS_INI, $SETTINGS_SECTION, "h", "0"))
    Local $aDesktop = _GetVirtualDesktopRect()
    Local $iMinX = $aDesktop[0]
    Local $iMinY = $aDesktop[1]
    Local $iMaxX = $aDesktop[0] + $aDesktop[2]
    Local $iMaxY = $aDesktop[1] + $aDesktop[3]

    If $iW <= 0 Or $iH <= 0 Then Return
    If $iX < $iMinX Then $iX = $iMinX
    If $iY < $iMinY Then $iY = $iMinY
    If $iX >= $iMaxX Or $iY >= $iMaxY Then Return
    If ($iX + $iW) > $iMaxX Then $iW = $iMaxX - $iX
    If ($iY + $iH) > $iMaxY Then $iH = $iMaxY - $iY
    If $iW <= 0 Or $iH <= 0 Then Return

    $g_iSelX = $iX
    $g_iSelY = $iY
    $g_iSelW = $iW
    $g_iSelH = $iH
EndFunc

Func _SaveSelectionToIni()
    If $g_iSelW <= 0 Or $g_iSelH <= 0 Then Return
    IniWrite($SETTINGS_INI, $SETTINGS_SECTION, "x", $g_iSelX)
    IniWrite($SETTINGS_INI, $SETTINGS_SECTION, "y", $g_iSelY)
    IniWrite($SETTINGS_INI, $SETTINGS_SECTION, "w", $g_iSelW)
    IniWrite($SETTINGS_INI, $SETTINGS_SECTION, "h", $g_iSelH)
EndFunc

Func _LoadUiSettingsFromIni()
    $g_bCfgTopmost = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "topmost", "1")) <> 0
    $g_bCfgAffinity = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "affinity", "1")) <> 0
    $g_bCfgFollowMouse = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "follow_mouse", "0")) <> 0
    $g_bCfgFollowActive = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "follow_active", "0")) <> 0
    $g_bCfgFollowActiveNextOnly = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "follow_active_next_only", "1")) <> 0
    $g_iFps = _NormalizeFps(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "fps", String($DEFAULT_FPS)))
    $g_sCfgProfile = _NormalizeProfileName(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "profil", "Whatsapp"))
    _LoadRecordProfileFromIni($g_sCfgProfile)
    $g_iCfgMainX = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "main_x", "-1"))
    $g_iCfgMainY = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "main_y", "-1"))
    $g_iCfgPreviewX = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_x", "-1"))
    $g_iCfgPreviewY = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_y", "-1"))
    $g_iCfgPreviewW = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_w", $PREVIEW_WIDTH))
    $g_iCfgPreviewH = Int(IniRead($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_h", $PREVIEW_HEIGHT))

    If $g_iCfgMainX < 0 Then $g_iCfgMainX = Default
    If $g_iCfgMainY < 0 Then $g_iCfgMainY = Default
    If $g_iCfgPreviewX < 0 Then $g_iCfgPreviewX = Default
    If $g_iCfgPreviewY < 0 Then $g_iCfgPreviewY = Default
    If $g_iCfgPreviewW <= 0 Then $g_iCfgPreviewW = $PREVIEW_WIDTH
    If $g_iCfgPreviewH <= 0 Then $g_iCfgPreviewH = $PREVIEW_HEIGHT
    If $g_bCfgFollowMouse And $g_bCfgFollowActive Then $g_bCfgFollowActive = False
EndFunc

Func _SaveAllSettingsToIni()
    _SaveSelectionToIni()
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "topmost", _CheckedToInt($g_idChkTop))
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "affinity", _CheckedToInt($g_idChkAffinity))
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "follow_mouse", _CheckedToInt($g_idChkFollowMouse))
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "follow_active", _CheckedToInt($g_idChkFollowActive))
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "follow_active_next_only", _CheckedToInt($g_idChkFollowActiveNextOnly))
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "fps", $g_iFps)
    IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "profil", $g_sCfgProfile)

    Local $aMain = WinGetPos($g_hMain)
    If IsArray($aMain) Then
        IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "main_x", $aMain[0])
        IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "main_y", $aMain[1])
    EndIf

    Local $aPreview = WinGetPos($g_hPreview)
    If IsArray($aPreview) Then
        IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_x", $aPreview[0])
        IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_y", $aPreview[1])
    EndIf

    Local $aPreviewClient = WinGetClientSize($g_hPreview)
    If IsArray($aPreviewClient) Then
        IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_w", $aPreviewClient[0])
        IniWrite($SETTINGS_INI, $SETTINGS_UI_SECTION, "preview_h", $aPreviewClient[1])
    EndIf
EndFunc

Func _CheckedToInt($idCtrl)
    If $idCtrl = 0 Then Return 0
    If GUICtrlRead($idCtrl) = $GUI_CHECKED Then Return 1
    Return 0
EndFunc

Func _UpdateFollowActiveNextOnlyUi()
    If $g_idChkFollowActiveNextOnly = 0 Then Return

    Local $bFollowActiveEnabled = False
    If $g_idChkFollowActive <> 0 And GUICtrlRead($g_idChkFollowActive) = $GUI_CHECKED Then $bFollowActiveEnabled = True

    If $bFollowActiveEnabled Then
        GUICtrlSetState($g_idChkFollowActiveNextOnly, $GUI_ENABLE)
    Else
        GUICtrlSetState($g_idChkFollowActiveNextOnly, $GUI_CHECKED)
        GUICtrlSetState($g_idChkFollowActiveNextOnly, $GUI_DISABLE)
    EndIf
EndFunc

Func _SetRecordingUiLock($bLocked)
    Local $iState = $GUI_ENABLE
    If $bLocked Then $iState = $GUI_DISABLE

    If $g_idBtnSelect <> 0 Then GUICtrlSetState($g_idBtnSelect, $iState)
    If $g_idBtnPause <> 0 Then GUICtrlSetState($g_idBtnPause, $iState)
    If $g_idBtnRecordings <> 0 Then GUICtrlSetState($g_idBtnRecordings, $iState)
    If $g_idCmbProfile <> 0 Then GUICtrlSetState($g_idCmbProfile, $iState)
    If $g_idCmbFps <> 0 Then GUICtrlSetState($g_idCmbFps, $iState)
    If $g_idChkTop <> 0 Then GUICtrlSetState($g_idChkTop, $iState)
    If $g_idChkAffinity <> 0 Then GUICtrlSetState($g_idChkAffinity, $iState)
    If $g_idChkFollowMouse <> 0 Then GUICtrlSetState($g_idChkFollowMouse, $iState)
    If $g_idChkFollowActive <> 0 Then GUICtrlSetState($g_idChkFollowActive, $iState)

    If $bLocked Then
        If $g_idChkFollowActiveNextOnly <> 0 Then GUICtrlSetState($g_idChkFollowActiveNextOnly, $GUI_DISABLE)
        If $g_idBtnRecord <> 0 Then GUICtrlSetState($g_idBtnRecord, $GUI_ENABLE)
        Return
    EndIf

    _UpdateFollowActiveNextOnlyUi()
    If $g_idBtnRecord <> 0 Then GUICtrlSetState($g_idBtnRecord, $GUI_ENABLE)
EndFunc

Func _GetValidFollowActiveHandle()
    Local $hActive = WinGetHandle("[ACTIVE]")
    If $hActive = 0 Then Return 0
    If $hActive = $g_hMain Or $hActive = $g_hPreview Then Return 0

    Local $aPos = WinGetPos($hActive)
    If @error Or Not IsArray($aPos) Then Return 0
    If $aPos[2] <= 0 Or $aPos[3] <= 0 Then Return 0

    Return $hActive
EndFunc

Func _NormalizeRecordFormat($sFormat)
    $sFormat = StringLower(StringStripWS($sFormat, 3))
    Switch $sFormat
        Case "mkv", "mp4", "avi"
            Return $sFormat
    EndSwitch
    Return "mkv"
EndFunc

Func _NormalizeFps($vFps)
    Local $iFps = Int($vFps)
    Switch $iFps
        Case 10, 24, 30, 60
            Return $iFps
    EndSwitch
    Return $DEFAULT_FPS
EndFunc

Func _GetRefreshIntervalMs()
    Return Int(1000 / $g_iFps)
EndFunc

Func _NormalizeRecordCodec($sCodec)
    $sCodec = StringLower(StringStripWS($sCodec, 3))
    Switch $sCodec
        Case "libx264", "libx265", "mpeg4", "libvpx-vp9", "libsvtav1", "ffv1", "mjpeg", _
             "h264_nvenc", "hevc_nvenc", "h264_qsv", "hevc_qsv", "h264_amf", "hevc_amf"
            Return $sCodec
    EndSwitch
    Return "libx264"
EndFunc

Func _NormalizeProfileName($sProfile)
    $sProfile = StringStripWS($sProfile, 3)
    Switch StringLower($sProfile)
        Case "whatsapp"
            Return "Whatsapp"
        Case "highquality"
            Return "HighQuality"
        Case "mobile"
            Return "mobile"
    EndSwitch
    Return "Whatsapp"
EndFunc

Func _LoadRecordProfileFromIni($sProfile)
    Local $sSection = $SETTINGS_PROFILE_PREFIX & _NormalizeProfileName($sProfile)

    $g_sCfgRecordFormat = _NormalizeRecordFormat(IniRead($SETTINGS_INI, $sSection, "format", "mp4"))
    $g_sCfgRecordCodec = _NormalizeRecordCodec(IniRead($SETTINGS_INI, $sSection, "codec", "libx264"))
    $g_sCfgRecordCodecArgs = _NormalizeFfmpegArgs(IniRead($SETTINGS_INI, $sSection, "codec_args", "-preset ultrafast -pix_fmt yuv420p"))
    $g_sCfgRecordContainerArgs = _NormalizeFfmpegArgs(IniRead($SETTINGS_INI, $sSection, "container_args", "-movflags +faststart"))
EndFunc

Func _NormalizeFfmpegArgs($sArgs)
    $sArgs = StringStripWS($sArgs, 3)
    If $sArgs = "" Then Return " "
    If StringLeft($sArgs, 1) <> " " Then $sArgs = " " & $sArgs
    If StringRight($sArgs, 1) <> " " Then $sArgs &= " "
    Return $sArgs
EndFunc

Func _GetEvenVideoSize($iValue)
    If $iValue <= 1 Then Return 2
    If BitAND($iValue, 1) <> 0 Then Return $iValue - 1
    Return $iValue
EndFunc

Func _ResizeMainToRegion()
    Local $iWidth = $g_iSelW
    Local $iHeight = $g_iSelH
    Local $aDesktop = _GetVirtualDesktopRect()

    If $iWidth < 160 Then $iWidth = 160
    If $iHeight < 120 Then $iHeight = 120
    If $iWidth > $aDesktop[2] - 60 Then $iWidth = $aDesktop[2] - 60
    If $iHeight > $aDesktop[3] - 60 Then $iHeight = $aDesktop[3] - 60

    If $g_hPreview <> 0 Then
        Local $aPreview = WinGetPos($g_hPreview)
        If IsArray($aPreview) Then
            _SetPreviewClientSize($iWidth, $iHeight, $aPreview[0], $aPreview[1])
        Else
            _SetPreviewClientSize($iWidth, $iHeight)
        EndIf
        _ResizeBackBuffer($iWidth, $iHeight)
    EndIf
EndFunc

Func _PositionPreviewWindow()
    If $g_hMain = 0 Or $g_hPreview = 0 Then Return

    Local $aMain = WinGetPos($g_hMain)
    If @error Or Not IsArray($aMain) Then Return
    Local $iPreviewX = $aMain[0] + $aMain[2] + $PREVIEW_WINDOW_GAP
    Local $iPreviewY = $aMain[1]

    Local $aClient = WinGetClientSize($g_hPreview)
    If @error Or Not IsArray($aClient) Then
        _SetPreviewClientSize($PREVIEW_WIDTH, $PREVIEW_HEIGHT, $iPreviewX, $iPreviewY)
        Return
    EndIf

    _SetPreviewClientSize($aClient[0], $aClient[1], $iPreviewX, $iPreviewY)
EndFunc

Func _SetPreviewClientSize($iClientW, $iClientH, $iX = Default, $iY = Default)
    If $g_hPreview = 0 Then Return
    Local $aSize = _GetWindowSizeForClient($iClientW, $iClientH, _WinAPI_GetWindowLong($g_hPreview, $GWL_STYLE), _WinAPI_GetWindowLong($g_hPreview, $GWL_EXSTYLE))
    WinMove($g_hPreview, "", $iX, $iY, $aSize[0], $aSize[1])
EndFunc

Func _GetWindowSizeForClient($iClientW, $iClientH, $iStyle, $iExStyle)
    Local $tRect = DllStructCreate($tagRECT)
    DllStructSetData($tRect, "Left", 0)
    DllStructSetData($tRect, "Top", 0)
    DllStructSetData($tRect, "Right", $iClientW)
    DllStructSetData($tRect, "Bottom", $iClientH)

    _WinAPI_AdjustWindowRectEx($tRect, $iStyle, $iExStyle, False)

    Local $aSize[2]
    $aSize[0] = DllStructGetData($tRect, "Right") - DllStructGetData($tRect, "Left")
    $aSize[1] = DllStructGetData($tRect, "Bottom") - DllStructGetData($tRect, "Top")
    Return $aSize
EndFunc

Func _RefreshPreview()
    If $g_bPaused Then Return
    If $g_iSelW <= 0 Or $g_iSelH <= 0 Then Return
    _EnsureRecordingProcessAlive()
    _UpdateFollowMouseRegion()
    _UpdateFollowActiveWindowRegion()
    _PresentFrame()
EndFunc

Func _StartRecording()
    If $g_iSelW <= 0 Or $g_iSelH <= 0 Then
        MsgBox(48, "DesktopRender", "Definis d'abord une zone a enregistrer.")
        Return
    EndIf

    If ($g_idChkFollowMouse <> 0 And GUICtrlRead($g_idChkFollowMouse) = $GUI_CHECKED) Or _
       ($g_idChkFollowActive <> 0 And GUICtrlRead($g_idChkFollowActive) = $GUI_CHECKED) Then
        MsgBox(48, "DesktopRender", "Desactive le suivi souris ou fenetre avant de demarrer un enregistrement.")
        Return
    EndIf

    Local $sFfmpeg = _ResolveFfmpegPath()
    If $sFfmpeg = "" Then
        MsgBox(48, "DesktopRender", "ffmpeg.exe introuvable. Place ffmpeg.exe a cote du script ou ajoute-le au PATH Windows.")
        Return
    EndIf

    DirCreate($RECORDINGS_DIR)
    $g_sRecordingFile = $RECORDINGS_DIR & "\DesktopRender_" & @YEAR & "-" & StringFormat("%02d", @MON) & "-" & StringFormat("%02d", @MDAY) & "_" & _
        StringFormat("%02d", @HOUR) & "-" & StringFormat("%02d", @MIN) & "-" & StringFormat("%02d", @SEC) & "." & $g_sCfgRecordFormat
    Local $iVideoW = _GetEvenVideoSize($g_iSelW)
    Local $iVideoH = _GetEvenVideoSize($g_iSelH)

    Local $sCmd = '"' & $sFfmpeg & '"' & _
        " -hide_banner -loglevel error -y" & _
        " -f gdigrab -framerate " & $g_iFps & _
        " -offset_x " & $g_iSelX & _
        " -offset_y " & $g_iSelY & _
        " -video_size " & $iVideoW & "x" & $iVideoH & _
        " -draw_mouse 1 -i desktop" & _
        " -c:v " & $g_sCfgRecordCodec & _
        $g_sCfgRecordCodecArgs & _
        $g_sCfgRecordContainerArgs & _
        '"' & $g_sRecordingFile & '"'
    $g_iRecordingPid = Run($sCmd, @ScriptDir, @SW_HIDE, $STDIN_CHILD + $STDERR_CHILD + $STDOUT_CHILD)
    If $g_iRecordingPid = 0 Then
        $g_sRecordingFile = ""
        MsgBox(16, "DesktopRender", "Impossible de demarrer ffmpeg.")
        Return
    EndIf

    $g_bRecording = True
    GUICtrlSetData($g_idBtnRecord, "Arreter")
    _SetRecordingUiLock(True)
    _UpdateRecordingInfo()
EndFunc

Func _StopRecording($bShowMessage = True)
    If Not $g_bRecording Then Return

    If $g_iRecordingPid <> 0 And ProcessExists($g_iRecordingPid) Then
        StdinWrite($g_iRecordingPid, "q")

        Local $hWait = TimerInit()
        While ProcessExists($g_iRecordingPid) And TimerDiff($hWait) < 3000
            Sleep(50)
        WEnd

        If ProcessExists($g_iRecordingPid) Then ProcessClose($g_iRecordingPid)
    EndIf

    $g_bRecording = False
    $g_iRecordingPid = 0
    GUICtrlSetData($g_idBtnRecord, "Enregistrer")
    _SetRecordingUiLock(False)
    _UpdateRecordingInfo()

    If $bShowMessage And $g_sRecordingFile <> "" Then
        MsgBox(64, "DesktopRender", "Enregistrement termine :" & @CRLF & $g_sRecordingFile)
    EndIf
EndFunc

Func _EnsureRecordingProcessAlive()
    If Not $g_bRecording Then Return
    If $g_iRecordingPid <> 0 And ProcessExists($g_iRecordingPid) Then Return

    $g_bRecording = False
    $g_iRecordingPid = 0
    GUICtrlSetData($g_idBtnRecord, "Enregistrer")
    _SetRecordingUiLock(False)
    _UpdateRecordingInfo()
    MsgBox(16, "DesktopRender", "L'enregistrement s'est arrete de maniere inattendue.")
EndFunc

Func _UpdateRecordingInfo()
    If $g_idLblRecord = 0 Then Return

    If $g_bRecording Then
        GUICtrlSetData($g_idLblRecord, "Profil : " & $g_sCfgProfile & " | Video : enregistrement en cours...")
    Else
        GUICtrlSetData($g_idLblRecord, "Profil : " & $g_sCfgProfile & " | Video : inactive")
    EndIf
EndFunc

Func _ResolveFfmpegPath()
    Local $sLocalExe = @ScriptDir & "\ffmpeg.exe"
    If FileExists($sLocalExe) Then Return $sLocalExe

    Local $iPid = Run(@ComSpec & ' /c where ffmpeg.exe', "", @SW_HIDE, $STDOUT_CHILD)
    If $iPid = 0 Then Return ""

    Local $sOutput = ""
    While 1
        $sOutput &= StdoutRead($iPid)
        If @error Then ExitLoop
        If Not ProcessExists($iPid) Then ExitLoop
        Sleep(20)
    WEnd
    $sOutput &= StdoutRead($iPid)
    $sOutput = StringStripWS(StringReplace($sOutput, @CR, ""), 3)
    If $sOutput = "" Then Return ""

    Local $aLines = StringSplit($sOutput, @LF, 2)
    If UBound($aLines) = 0 Then Return ""
    If FileExists($aLines[0]) Then Return $aLines[0]
    Return ""
EndFunc

Func _UpdateFollowMouseRegion()
    If $g_idChkFollowMouse = 0 Then Return
    If GUICtrlRead($g_idChkFollowMouse) <> $GUI_CHECKED Then Return

    Local $aMouse = MouseGetPos()
    Local $aDesktop = _GetVirtualDesktopRect()
    Local $iMinX = $aDesktop[0]
    Local $iMinY = $aDesktop[1]
    Local $iMaxX = $aDesktop[0] + $aDesktop[2]
    Local $iMaxY = $aDesktop[1] + $aDesktop[3]
    Local $iHalfW = Int($g_iSelW / 2)
    Local $iHalfH = Int($g_iSelH / 2)

    $g_iSelX = $aMouse[0] - $iHalfW
    $g_iSelY = $aMouse[1] - $iHalfH

    If ($g_iSelX + $g_iSelW) > $iMaxX Then $g_iSelX = $iMaxX - $g_iSelW
    If ($g_iSelY + $g_iSelH) > $iMaxY Then $g_iSelY = $iMaxY - $g_iSelH
    If $g_iSelX < $iMinX Then $g_iSelX = $iMinX
    If $g_iSelY < $iMinY Then $g_iSelY = $iMinY
EndFunc

Func _UpdateFollowActiveWindowRegion()
    If $g_idChkFollowActive = 0 Then Return
    If GUICtrlRead($g_idChkFollowActive) <> $GUI_CHECKED Then Return

    Local $hActive = 0
    Local $bNextOnly = False
    If $g_idChkFollowActiveNextOnly <> 0 And GUICtrlRead($g_idChkFollowActiveNextOnly) = $GUI_CHECKED Then $bNextOnly = True

    If $bNextOnly Then
        If $g_hFollowActiveTarget <> 0 And Not WinExists($g_hFollowActiveTarget) Then
            $g_hFollowActiveTarget = 0
            _UpdateInfo()
        EndIf
        If $g_hFollowActiveTarget = 0 Then $g_hFollowActiveTarget = _GetValidFollowActiveHandle()
        $hActive = $g_hFollowActiveTarget
    Else
        $g_hFollowActiveTarget = 0
        $hActive = _GetValidFollowActiveHandle()
    EndIf

    If $hActive = 0 Then Return
    If $bNextOnly And $g_hFollowActiveTarget = $hActive Then _UpdateInfo()

    Local $aPos = WinGetPos($hActive)
    If @error Or Not IsArray($aPos) Then Return
    If $aPos[2] <= 0 Or $aPos[3] <= 0 Then Return
    Local $aDesktop = _GetVirtualDesktopRect()
    Local $iMinX = $aDesktop[0]
    Local $iMinY = $aDesktop[1]
    Local $iMaxX = $aDesktop[0] + $aDesktop[2]
    Local $iMaxY = $aDesktop[1] + $aDesktop[3]

    $g_iSelX = $aPos[0]
    $g_iSelY = $aPos[1]
    $g_iSelW = $aPos[2]
    $g_iSelH = $aPos[3]

    If $g_iSelX < $iMinX Then
        $g_iSelW -= ($iMinX - $g_iSelX)
        $g_iSelX = $iMinX
    EndIf
    If $g_iSelY < $iMinY Then
        $g_iSelH -= ($iMinY - $g_iSelY)
        $g_iSelY = $iMinY
    EndIf
    If ($g_iSelX + $g_iSelW) > $iMaxX Then $g_iSelW = $iMaxX - $g_iSelX
    If ($g_iSelY + $g_iSelH) > $iMaxY Then $g_iSelH = $iMaxY - $g_iSelY
    If $g_iSelW <= 0 Or $g_iSelH <= 0 Then Return

    _ResizeMainToRegion()
EndFunc

Func _ApplyWindowAffinity($hWnd)
    If $hWnd = 0 Then Return

    If $g_idChkAffinity <> 0 And GUICtrlRead($g_idChkAffinity) <> $GUI_CHECKED Then
        _WinAPI_SetWindowDisplayAffinity($hWnd, $WDA_NONE)
        Return
    EndIf

    If Not _WinAPI_SetWindowDisplayAffinity($hWnd, $WDA_EXCLUDEFROMCAPTURE) Then
        _WinAPI_SetWindowDisplayAffinity($hWnd, $WDA_MONITOR)
    EndIf
EndFunc

Func _SelectScreenRegion()
    Local Const $iLineSize = 5
    Local Const $iHitSize = 14
    Local Const $iMinZone = 80
    Local $aDesktop = _GetVirtualDesktopRect()
    Local $iMinX = $aDesktop[0]
    Local $iMinY = $aDesktop[1]
    Local $iMaxX = $aDesktop[0] + $aDesktop[2] - 1
    Local $iMaxY = $aDesktop[1] + $aDesktop[3] - 1

    Local $hOverlay = GUICreate("Selection", $aDesktop[2], $aDesktop[3], $iMinX, $iMinY, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
    GUISetBkColor(0x000000, $hOverlay)
    WinSetTrans($hOverlay, "", 80)

    Local $idV1 = GUICtrlCreateLabel("", 0, 0, $iLineSize, $aDesktop[3])
    Local $idV2 = GUICtrlCreateLabel("", 0, 0, $iLineSize, $aDesktop[3])
    Local $idH1 = GUICtrlCreateLabel("", 0, 0, $aDesktop[2], $iLineSize)
    Local $idH2 = GUICtrlCreateLabel("", 0, 0, $aDesktop[2], $iLineSize)

    GUICtrlSetBkColor($idV1, 0x00D8FF)
    GUICtrlSetBkColor($idV2, 0x00D8FF)
    GUICtrlSetBkColor($idH1, 0x00D8FF)
    GUICtrlSetBkColor($idH2, 0x00D8FF)

    Local $hCenter = GUICreate("", 100, 100, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
    GUISetBkColor(0xFFFFFF, $hCenter)
    WinSetTrans($hCenter, "", 16)

    Local $iV1 = $iMinX + Int($aDesktop[2] / 3)
    Local $iV2 = $iMinX + Int(($aDesktop[2] * 2) / 3)
    Local $iH1 = $iMinY + Int($aDesktop[3] / 3)
    Local $iH2 = $iMinY + Int(($aDesktop[3] * 2) / 3)

    If $g_iSelW > 0 And $g_iSelH > 0 Then
        $iV1 = $g_iSelX
        $iV2 = $g_iSelX + $g_iSelW - 1
        $iH1 = $g_iSelY
        $iH2 = $g_iSelY + $g_iSelH - 1
    EndIf

    _UpdateSelectionGuides($hOverlay, $hCenter, $idV1, $idV2, $idH1, $idH2, $iV1, $iV2, $iH1, $iH2)
    _PreviewSelectionRegion($iV1, $iV2, $iH1, $iH2)
    GUISetState(@SW_SHOW, $hOverlay)
    GUISetState(@SW_SHOW, $hCenter)
    WinSetOnTop($hCenter, "", 1)

    Local $iDragMode = 0
    Local $iDragOffsetX = 0
    Local $iDragOffsetY = 0

    While 1
        If _IsPressed("1B") Then
            GUIDelete($hCenter)
            GUIDelete($hOverlay)
            Return SetError(1, 0, 0)
        EndIf

        If _IsPressed("0D") Then ExitLoop

        Local $aMouse = MouseGetPos()

        If _IsPressed("01") Then
            If $iDragMode = 0 Then
                $iDragMode = _HitTestSelectionGuide($aMouse[0], $aMouse[1], $iV1, $iV2, $iH1, $iH2, $iHitSize)
                If $iDragMode = 9 Then
                    $iDragOffsetX = $aMouse[0] - $iV1
                    $iDragOffsetY = $aMouse[1] - $iH1
                EndIf
            EndIf

            Switch $iDragMode
                Case 1
                    $iV1 = _Clamp($aMouse[0], $iMinX, $iV2 - ($iMinZone - 1))
                Case 2
                    $iV2 = _Clamp($aMouse[0], $iV1 + ($iMinZone - 1), $iMaxX)
                Case 3
                    $iH1 = _Clamp($aMouse[1], $iMinY, $iH2 - ($iMinZone - 1))
                Case 4
                    $iH2 = _Clamp($aMouse[1], $iH1 + ($iMinZone - 1), $iMaxY)
                Case 5
                    $iV1 = _Clamp($aMouse[0], $iMinX, $iV2 - ($iMinZone - 1))
                    $iH1 = _Clamp($aMouse[1], $iMinY, $iH2 - ($iMinZone - 1))
                Case 6
                    $iV2 = _Clamp($aMouse[0], $iV1 + ($iMinZone - 1), $iMaxX)
                    $iH1 = _Clamp($aMouse[1], $iMinY, $iH2 - ($iMinZone - 1))
                Case 7
                    $iV1 = _Clamp($aMouse[0], $iMinX, $iV2 - ($iMinZone - 1))
                    $iH2 = _Clamp($aMouse[1], $iH1 + ($iMinZone - 1), $iMaxY)
                Case 8
                    $iV2 = _Clamp($aMouse[0], $iV1 + ($iMinZone - 1), $iMaxX)
                    $iH2 = _Clamp($aMouse[1], $iH1 + ($iMinZone - 1), $iMaxY)
                Case 9
                    Local $iZoneW = $iV2 - $iV1
                    Local $iZoneH = $iH2 - $iH1
                    Local $iNewV1 = _Clamp($aMouse[0] - $iDragOffsetX, $iMinX, $iMaxX - $iZoneW)
                    Local $iNewH1 = _Clamp($aMouse[1] - $iDragOffsetY, $iMinY, $iMaxY - $iZoneH)
                    $iV1 = $iNewV1
                    $iV2 = $iNewV1 + $iZoneW
                    $iH1 = $iNewH1
                    $iH2 = $iNewH1 + $iZoneH
            EndSwitch

            If $iDragMode <> 0 Then
                _UpdateSelectionGuides($hOverlay, $hCenter, $idV1, $idV2, $idH1, $idH2, $iV1, $iV2, $iH1, $iH2)
                _PreviewSelectionRegion($iV1, $iV2, $iH1, $iH2)
                WinSetOnTop($hCenter, "", 1)
            EndIf
        Else
            $iDragMode = 0
        EndIf

        _PresentFrame()

        Sleep(10)
    WEnd

    GUIDelete($hCenter)
    GUIDelete($hOverlay)

    If (($iV2 - $iV1) + 1) < 20 Or (($iH2 - $iH1) + 1) < 20 Then
        Return SetError(2, 0, 0)
    EndIf

    Local $aRegion[4] = [$iV1, $iH1, ($iV2 - $iV1) + 1, ($iH2 - $iH1) + 1]
    Return $aRegion
EndFunc

Func _PreviewSelectionRegion($iV1, $iV2, $iH1, $iH2)
    $g_iSelX = $iV1
    $g_iSelY = $iH1
    $g_iSelW = ($iV2 - $iV1) + 1
    $g_iSelH = ($iH2 - $iH1) + 1
    _ResizeMainToRegion()
    _PresentFrame()
EndFunc

Func _UpdateSelectionGuides($hOverlay, $hCenter, $idV1, $idV2, $idH1, $idH2, $iV1, $iV2, $iH1, $iH2)
    Local $aDesktop = _GetVirtualDesktopRect()
    Local $iLocalX1 = $iV1 - $aDesktop[0]
    Local $iLocalX2 = $iV2 - $aDesktop[0]
    Local $iLocalY1 = $iH1 - $aDesktop[1]
    Local $iLocalY2 = $iH2 - $aDesktop[1]

    GUICtrlSetPos($idV1, $iLocalX1 - 5, 0, 5, $aDesktop[3])
    GUICtrlSetPos($idV2, $iLocalX2, 0, 5, $aDesktop[3])
    GUICtrlSetPos($idH1, 0, $iLocalY1 - 5, $aDesktop[2], 5)
    GUICtrlSetPos($idH2, 0, $iLocalY2, $aDesktop[2], 5)
    _ApplySelectionHole($hOverlay, $iLocalX1, $iLocalY1, ($iV2 - $iV1) + 1, ($iH2 - $iH1) + 1)
    WinMove($hCenter, "", $iV1, $iH1, ($iV2 - $iV1) + 1, ($iH2 - $iH1) + 1)
EndFunc

Func _GetVirtualDesktopRect()
    Local $aRect[4]
    $aRect[0] = _GetSystemMetric($SM_XVIRTUALSCREEN)
    $aRect[1] = _GetSystemMetric($SM_YVIRTUALSCREEN)
    $aRect[2] = _GetSystemMetric($SM_CXVIRTUALSCREEN)
    $aRect[3] = _GetSystemMetric($SM_CYVIRTUALSCREEN)

    If $aRect[2] <= 0 Then
        $aRect[0] = 0
        $aRect[2] = @DesktopWidth
    EndIf
    If $aRect[3] <= 0 Then
        $aRect[1] = 0
        $aRect[3] = @DesktopHeight
    EndIf

    Return $aRect
EndFunc

Func _GetSystemMetric($iIndex)
    Local $aResult = DllCall("user32.dll", "int", "GetSystemMetrics", "int", $iIndex)
    If @error Or Not IsArray($aResult) Then Return 0
    Return $aResult[0]
EndFunc

Func _HitTestSelectionGuide($iMouseX, $iMouseY, $iV1, $iV2, $iH1, $iH2, $iHitSize)
    If $iMouseX >= $iV1 And $iMouseX <= $iV2 And $iMouseY >= $iH1 And $iMouseY <= $iH2 Then
        Local $iMargin = 4
        Local $bNearLeft = ($iMouseX - $iV1) <= $iMargin
        Local $bNearRight = ($iV2 - $iMouseX) <= $iMargin
        Local $bNearTop = ($iMouseY - $iH1) <= $iMargin
        Local $bNearBottom = ($iH2 - $iMouseY) <= $iMargin

        If $bNearLeft And $bNearTop Then Return 5
        If $bNearRight And $bNearTop Then Return 6
        If $bNearLeft And $bNearBottom Then Return 7
        If $bNearRight And $bNearBottom Then Return 8
        If $bNearLeft Then Return 1
        If $bNearRight Then Return 2
        If $bNearTop Then Return 3
        If $bNearBottom Then Return 4
        Return 9
    EndIf
    If $iMouseX < $iV1 And $iMouseY < $iH1 Then Return 5
    If $iMouseX > $iV2 And $iMouseY < $iH1 Then Return 6
    If $iMouseX < $iV1 And $iMouseY > $iH2 Then Return 7
    If $iMouseX > $iV2 And $iMouseY > $iH2 Then Return 8

    If $iMouseX < $iV1 And $iMouseY >= $iH1 And $iMouseY <= $iH2 Then Return 1
    If $iMouseX > $iV2 And $iMouseY >= $iH1 And $iMouseY <= $iH2 Then Return 2
    If $iMouseY < $iH1 And $iMouseX >= $iV1 And $iMouseX <= $iV2 Then Return 3
    If $iMouseY > $iH2 And $iMouseX >= $iV1 And $iMouseX <= $iV2 Then Return 4

    Local $iBest = 0
    Local $iBestDist = 999999

    Local $iDist = Abs($iMouseX - $iV1)
    If $iDist <= $iHitSize And $iDist < $iBestDist Then
        $iBest = 1
        $iBestDist = $iDist
    EndIf

    $iDist = Abs($iMouseX - $iV2)
    If $iDist <= $iHitSize And $iDist < $iBestDist Then
        $iBest = 2
        $iBestDist = $iDist
    EndIf

    $iDist = Abs($iMouseY - $iH1)
    If $iDist <= $iHitSize And $iDist < $iBestDist Then
        $iBest = 3
        $iBestDist = $iDist
    EndIf

    $iDist = Abs($iMouseY - $iH2)
    If $iDist <= $iHitSize And $iDist < $iBestDist Then
        $iBest = 4
    EndIf

    Return $iBest
EndFunc

Func _Clamp($iValue, $iMin, $iMax)
    If $iValue < $iMin Then Return $iMin
    If $iValue > $iMax Then Return $iMax
    Return $iValue
EndFunc

Func _ApplySelectionHole($hWin, $iX, $iY, $iW, $iH)
    Local $aPos = WinGetPos($hWin)
    If @error Or Not IsArray($aPos) Then Return

    Local $hOuter = _WinAPI_CreateRectRgn(0, 0, $aPos[2], $aPos[3])
    Local $hInner = _WinAPI_CreateRectRgn($iX, $iY, $iX + $iW, $iY + $iH)
    Local $hCombined = _WinAPI_CreateRectRgn(0, 0, 0, 0)

    _WinAPI_CombineRgn($hCombined, $hOuter, $hInner, $RGN_DIFF)
    _WinAPI_SetWindowRgn($hWin, $hCombined)
    _WinAPI_DeleteObject($hOuter)
    _WinAPI_DeleteObject($hInner)
EndFunc

Func _EnableDoubleBuffering($hWnd)
    If $hWnd = 0 Then Return

    Local $iExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)
    If BitAND($iExStyle, $WS_EX_COMPOSITED) = 0 Then
        _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, BitOR($iExStyle, $WS_EX_COMPOSITED))
    EndIf

    _WinAPI_RedrawWindow($hWnd, 0, 0, BitOR($RDW_INVALIDATE, $RDW_FRAME, $RDW_UPDATENOW))
EndFunc

Func _ResizeBackBuffer($iWidth, $iHeight)
    If $iWidth <= 0 Or $iHeight <= 0 Then Return
    If $iWidth = $g_iPreviewW And $iHeight = $g_iPreviewH And $g_hBackDC <> 0 Then Return

    _DestroyBackBuffer()

    $g_hPreviewDC = _WinAPI_GetDC($g_hPreview)
    If $g_hPreviewDC = 0 Then Return

    $g_hBackDC = _WinAPI_CreateCompatibleDC($g_hPreviewDC)
    $g_hBackBitmap = _WinAPI_CreateCompatibleBitmap($g_hPreviewDC, $iWidth, $iHeight)

    If $g_hBackDC = 0 Or $g_hBackBitmap = 0 Or $g_hPreviewDC = 0 Then
        _DestroyBackBuffer()
        Return
    EndIf

    $g_hBackBitmapOld = _WinAPI_SelectObject($g_hBackDC, $g_hBackBitmap)
    $g_iPreviewW = $iWidth
    $g_iPreviewH = $iHeight

    _WinAPI_SetStretchBltMode($g_hPreviewDC, $COLORONCOLOR)
    _WinAPI_SetStretchBltMode($g_hBackDC, $COLORONCOLOR)
EndFunc

Func _DestroyBackBuffer()
    If $g_hBackDC <> 0 And $g_hBackBitmapOld <> 0 Then
        _WinAPI_SelectObject($g_hBackDC, $g_hBackBitmapOld)
    EndIf
    If $g_hBackBitmap <> 0 Then _WinAPI_DeleteObject($g_hBackBitmap)
    If $g_hBackDC <> 0 Then _WinAPI_DeleteDC($g_hBackDC)
    If $g_hPreviewDC <> 0 And $g_hPreview <> 0 Then _WinAPI_ReleaseDC($g_hPreview, $g_hPreviewDC)

    $g_hPreviewDC = 0
    $g_hBackDC = 0
    $g_hBackBitmap = 0
    $g_hBackBitmapOld = 0
    $g_iPreviewW = 0
    $g_iPreviewH = 0
EndFunc

Func _PresentFrame()
    If $g_hBackDC = 0 Or $g_hPreviewDC = 0 Then Return

    Local $hDesktop = _WinAPI_GetDesktopWindow()
    Local $hScreenDC = _WinAPI_GetWindowDC($hDesktop)
    If $hScreenDC = 0 Then Return

    _WinAPI_StretchBlt($g_hBackDC, 0, 0, $g_iPreviewW, $g_iPreviewH, $hScreenDC, $g_iSelX, $g_iSelY, $g_iSelW, $g_iSelH, $SRCCOPY)

    _WinAPI_ReleaseDC($hDesktop, $hScreenDC)
    _DrawCursorOnPreview()

    _WinAPI_StretchBlt($g_hPreviewDC, 0, 0, $g_iPreviewW, $g_iPreviewH, $g_hBackDC, 0, 0, $g_iPreviewW, $g_iPreviewH, $SRCCOPY)
EndFunc

Func _DrawCursorOnPreview()
    Local $tCursor = DllStructCreate("dword cbSize;dword flags;handle hCursor;long X;long Y")
    DllStructSetData($tCursor, "cbSize", DllStructGetSize($tCursor))

    Local $aResult = DllCall("user32.dll", "bool", "GetCursorInfo", "struct*", $tCursor)
    If @error Or Not IsArray($aResult) Then Return
    If BitAND(DllStructGetData($tCursor, "flags"), 1) = 0 Then Return

    Local $iMouseX = DllStructGetData($tCursor, "X")
    Local $iMouseY = DllStructGetData($tCursor, "Y")
    If $iMouseX < $g_iSelX Or $iMouseX >= ($g_iSelX + $g_iSelW) Then Return
    If $iMouseY < $g_iSelY Or $iMouseY >= ($g_iSelY + $g_iSelH) Then Return

    Local $hCursor = DllStructGetData($tCursor, "hCursor")
    Local $aCopy = DllCall("user32.dll", "handle", "CopyIcon", "handle", $hCursor)
    If @error Or Not IsArray($aCopy) Or $aCopy[0] = 0 Then Return

    Local $hIcon = $aCopy[0]
    Local $tIcon = DllStructCreate("bool Icon;dword XHotSpot;dword YHotSpot;handle hbmMask;handle hbmColor")
    Local $aIconInfo = DllCall("user32.dll", "bool", "GetIconInfo", "handle", $hIcon, "struct*", $tIcon)
    If @error Or Not IsArray($aIconInfo) Or Not $aIconInfo[0] Then
        DllCall("user32.dll", "bool", "DestroyIcon", "handle", $hIcon)
        Return
    EndIf

    Local $iDrawX = Int((($iMouseX - $g_iSelX) * $g_iPreviewW) / $g_iSelW) - DllStructGetData($tIcon, "XHotSpot")
    Local $iDrawY = Int((($iMouseY - $g_iSelY) * $g_iPreviewH) / $g_iSelH) - DllStructGetData($tIcon, "YHotSpot")

    DllCall("user32.dll", "bool", "DrawIconEx", _
        "handle", $g_hBackDC, _
        "int", $iDrawX, _
        "int", $iDrawY, _
        "handle", $hIcon, _
        "int", 0, _
        "int", 0, _
        "uint", 0, _
        "handle", 0, _
        "uint", $DI_NORMAL)

    If DllStructGetData($tIcon, "hbmMask") <> 0 Then _WinAPI_DeleteObject(DllStructGetData($tIcon, "hbmMask"))
    If DllStructGetData($tIcon, "hbmColor") <> 0 Then _WinAPI_DeleteObject(DllStructGetData($tIcon, "hbmColor"))
    DllCall("user32.dll", "bool", "DestroyIcon", "handle", $hIcon)
EndFunc

Func App_WMEraseBkgnd($hWnd, $iMsg, $wParam, $lParam)
    If $hWnd = $g_hPreview Then Return 1
    Return $GUI_RUNDEFMSG
EndFunc
