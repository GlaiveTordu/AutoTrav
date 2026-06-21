#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetTitleMatchMode 2

; ==================== CONFIGURATION ====================
VersionActuelle := "0.0.5"
LienMaj := "https://gist.githubusercontent.com/GlaiveTordu/d9f5e8f15fd6e34626bc7ad91ae23eca/raw/script.ahk"
LienVersion := "https://raw.githubusercontent.com/GlaiveTordu/AutoTrav/main/version.txt"
LienExe := "https://github.com/GlaiveTordu/AutoTrav/releases/latest/download/AutoTrav.exe"
ConfigFile := A_ScriptDir "\config_swapper.ini"
; =======================================================

TargetCharacter := ""
lastClip := ""
IsPaused := false
DofusWindows := []  
BindsMap := Map()   
CustomKeys := Map() 
RowData := []  
CurrentCycleIndex := 0

; Chargement des configurations
if FileExist(ConfigFile) {
    try {
        bindsText := IniRead(ConfigFile, "Binds")
        Loop Parse, bindsText, "`n", "`r" {
            if (A_LoopField != "") {
                part := StrSplit(A_LoopField, "=")
                if (part.Length = 2)
                    CustomKeys[Trim(part[1])] := Trim(part[2])
            }
        }
        CycleHotkey := IniRead(ConfigFile, "Config", "CycleHotkey", "Tab")
    }
} else {
    CycleHotkey := "Tab"
}

TrayTip "AutoTrav", "Interface stable activée ! 🚀", 1

ControlGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow +E0x02000000 +E0x00080000")
ControlGui.BackColor := "1B1917"
ControlGui.Title := "AutoTrav - Dofus 3 Unity Multi-Account Helper"

; --- En-tête (Header) ---
ControlGui.SetFont("s18 cD4A34F Bold", "Segoe UI")
ControlGui.Add("Text", "x15 y15 w400 h30 +BackgroundTrans", "AUTOTRAV")

ControlGui.SetFont("s8.5 c8F8A85 Norm", "Segoe UI")
ControlGui.Add("Text", "x15 y45 w450 h15 +BackgroundTrans", "Outil de voyage et de gestion multicompte Dofus 3 Unity")

; Bouton Rafraîchir les processus (en haut à droite)
ControlGui.SetFont("s9 c1B1917 Bold", "Segoe UI")
BtnRefresh := ControlGui.Add("Text", "x535 y18 w170 h28 Center +0x0200 BackgroundD4A34F +Border vBtnRefresh", "Rafraîchir les processus")

; Ligne de séparation sous l'en-tête
ControlGui.Add("Text", "x15 y75 w690 h1 +Background33302D")

; --- Section Gauche : Instances Dofus ---
ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
ControlGui.Add("Text", "x15 y95 w250 h20 +BackgroundTrans", "Instances Dofus détectées")

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
BtnSetCycle := ControlGui.Add("Text", "x295 y91 w135 h24 Center +0x0200 Background2D2A26 +Border vBtnSetCycle", "⚙ Cycle : " CycleHotkey)

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
AccountList := ControlGui.Add("ListView", "x15 y125 w415 h290 -Hdr -Multi Background1E1C1A cWhite -LV0x10 vAccountList", ["Perso", "Raccourci"])

; --- Section Droite : Voyage & Logs ---
ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
ControlGui.Add("Text", "x450 y95 w250 h20 +BackgroundTrans", "Paramètres du Voyage (/travel)")

ControlGui.SetFont("s8.5 cFFFFFF Norm", "Segoe UI")
ControlGui.Add("Text", "x450 y123 w250 h15 +BackgroundTrans", "Sélectionner le compte qui reçoit la commande :")

ChoicePerso := ControlGui.Add("DDL", "x450 y143 w255 Background1E1C1A vChoicePerso", ["Aucun compte"])

ControlGui.SetFont("s8.5 cFFFFFF Norm", "Segoe UI")
ShowLogCheckbox := ControlGui.Add("Checkbox", "x450 y180 w250 h20 Checked", "Afficher le journal d'activité")

ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
LogTitle := ControlGui.Add("Text", "x450 y215 w250 h20 vLogTitle +BackgroundTrans", "Journal d'activité")

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
LogEdit := ControlGui.Add("Edit", "x450 y238 w255 h177 ReadOnly Multi Background1E1C1A vLogEdit")

; --- Barre de Statut (Bas) ---
ControlGui.Add("Text", "x15 y430 w690 h1 +Background33302D")

ControlGui.SetFont("s8.5 c8F8A85 Norm", "Segoe UI")
TxtVersion := ControlGui.Add("Text", "x15 y442 w80 h18 Left +BackgroundTrans vTxtVersion", "Version: v" VersionActuelle)

ControlGui.SetFont("s8.5 cFFFFFF Bold", "Segoe UI")
ControlGui.Add("Text", "x110 y442 w170 h18 Left +BackgroundTrans", "Surveillance du presse-papier :")
ControlGui.SetFont("s8.5 c55FF55 Bold", "Segoe UI")
StatusText := ControlGui.Add("Text", "x285 y442 w90 h18 Left +BackgroundTrans vStatusText", "Active")

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
BtnPauseToggle := ControlGui.Add("Text", "x380 y437 w100 h24 Center +0x0200 Background2D2A26 +Border vBtnPauseToggle", "⏸ Pause")

ControlGui.SetFont("s7 cFF3333 Italic Norm", "Segoe UI")
ControlGui.Add("Text", "x610 y442 w60 h18 Right +BackgroundTrans", "keyzome ♥")

ControlGui.SetFont("s9 cE5C180 Bold", "Segoe UI")
BtnMaj := ControlGui.Add("Text", "x675 y437 w30 h24 Center +0x0200 Background2D2A26 +Border vBtnMaj", "🔄")

; Événements
BtnRefresh.OnEvent("Click", (*) => ActualiserProcessDofus(false))
BtnSetCycle.OnEvent("Click", ModifierCycleHotkey)
ShowLogCheckbox.OnEvent("Click", ToggleLog)
StatusText.OnEvent("Click", TogglePause)
BtnPauseToggle.OnEvent("Click", TogglePause)
BtnMaj.OnEvent("Click", ForcerVerification)
AccountList.OnEvent("DoubleClick", ModifierBindManuel)
ChoicePerso.OnEvent("Change", ChangerDePersonnage)

ControlGui.Show("X10 Y10 W720 H475 NoActivate")
WinSetTransparent(130, ControlGui.Hwnd)

SetTimer(VerifierMiseAJour, -500)
SetTimer(WatchMouse, 100)
SetTimer(CheckClipboard, 250)
OnMessage(0x0201, WM_LBUTTONDOWN)
OnMessage(0x0020, WM_SETCURSOR)

LogMessage("AutoTrav démarré avec succès.")
ActualiserProcessDofus(false)
return

; ==================== FONCTIONS ====================

LogMessage(msg) {
    global LogEdit
    timeStr := FormatTime(, "[HH:mm:ss] ")
    currentText := LogEdit.Value
    if (currentText = "")
        LogEdit.Value := timeStr msg
    else
        LogEdit.Value := currentText "`r`n" timeStr msg
    
    ; Défilement vers le bas
    SendMessage(0x00B6, 0, 9999, LogEdit.Hwnd) ; EM_LINESCROLL
}

ToggleLog(Ctrl, *) {
    if (Ctrl.Value == 1) {
        ControlGui["LogTitle"].Opt("-Hidden")
        ControlGui["LogEdit"].Opt("-Hidden")
    } else {
        ControlGui["LogTitle"].Opt("+Hidden")
        ControlGui["LogEdit"].Opt("+Hidden")
    }
}

ModifierCycleHotkey(*) {
    global CycleHotkey, ConfigFile, BtnSetCycle
    IB := InputBox("Entrez la touche pour passer au compte suivant (ex: Tab, F2) :", "Configuration Cycle", "w300 h130", CycleHotkey)
    if (IB.Result == "OK" && IB.Value != "") {
        try Hotkey(CycleHotkey, "Off")
        CycleHotkey := IB.Value
        IniWrite(CycleHotkey, ConfigFile, "Config", "CycleHotkey")
        BtnSetCycle.Text := "⚙ Cycle : " CycleHotkey
        try Hotkey(CycleHotkey, CycleFenetresDofus, "On")
        LogMessage("Touche de cycle modifiée : " CycleHotkey)
    }
}

ModifierBindManuel(Ctrl, RowNumber) {
    if (RowNumber = 0)
        return
    pseudo := RowData[RowNumber].pseudo
    currentBind := RowData[RowNumber].bind
    IB := InputBox("Entrez le raccourci pour : " pseudo, "Modifier le raccourci", "w300 h130", currentBind)
    if (IB.Result == "OK" && IB.Value != "") {
        CustomKeys[pseudo] := IB.Value
        IniWrite(IB.Value, ConfigFile, "Binds", pseudo)
        LogMessage("Raccourci modifié pour " pseudo " -> " IB.Value)
        ActualiserProcessDofus(false)
    }
}

ActualiserProcessDofus(DemanderBinds := false) {
    global DofusWindows, BindsMap, TargetCharacter, CustomKeys, RowData, CycleHotkey
    AccountList.Delete() 
    for key, hwnd in BindsMap
        try Hotkey(key, "Off")
    BindsMap := Map()
    DofusWindows := []
    RowData := []
    ListePseudos := []
    
    WinList := WinGetList("ahk_exe Dofus.exe")
    for hwnd in WinList {
        title := WinGetTitle(hwnd)
        ; Extraire seulement PSEUDO - CLASSE (retirer version, "Release", etc.)
        pseudo := RegExReplace(title, "\s*-\s*\d[^-]*-\s*Release.*$", "")
        pseudo := RegExReplace(pseudo, "\s*-\s*Dofus.*", "")
        if (pseudo != "" && !InStr(pseudo, "Dofus Updater")) {
            DofusWindows.Push({hwnd: hwnd, name: pseudo})
            ListePseudos.Push(pseudo)
            
            bindKey := CustomKeys.Has(pseudo) ? CustomKeys[pseudo] : IniRead(ConfigFile, "Binds", pseudo, "")
            
            if (bindKey == "" || DemanderBinds) {
                IB := InputBox("Entrez la touche de raccourci pour : " pseudo, "Binds", "w300 h130", bindKey == "" ? "F1" : bindKey)
                if (IB.Result == "OK" && IB.Value != "") {
                    bindKey := IB.Value
                    CustomKeys[pseudo] := bindKey
                    IniWrite(bindKey, ConfigFile, "Binds", pseudo) 
                } else if (bindKey == "")
                    bindKey := "F" DofusWindows.Length
            } else {
                CustomKeys[pseudo] := bindKey
            }
            
            RowData.Push({pseudo: pseudo, bind: bindKey})
            AccountList.Add(, TronquerTexte(pseudo, 40), bindKey)
            BindsMap[bindKey] := hwnd
            try Hotkey(bindKey, ActiverFenetreDofus, "On")
            
            LogMessage("Nouvelle instance détectée : " pseudo)
        }
    }
    
    ChoicePerso.Delete()
    if (ListePseudos.Length > 0) {
        ChoicePerso.Add(ListePseudos)
        if (TargetCharacter != "" && HasValue(ListePseudos, TargetCharacter)) {
            ChoicePerso.Text := TargetCharacter
        } else {
            ChoicePerso.Choose(1)
            TargetCharacter := ListePseudos[1]
        }
        LogMessage("Compte cible voyage défini sur : " TargetCharacter)
    } else {
        ChoicePerso.Add(["Aucun compte"])
        ChoicePerso.Choose(1)
        TargetCharacter := ""
        AccountList.Add(, "Aucun compte", "")
    }
    
    try Hotkey(CycleHotkey, CycleFenetresDofus, "On")
    AccountList.ModifyCol(1, 300)
    AccountList.ModifyCol(2, 90)
}

CycleFenetresDofus(*) {
    global DofusWindows, CurrentCycleIndex
    if (DofusWindows.Length == 0) {
        ActualiserProcessDofus(false)
    }
    if (DofusWindows.Length > 0) {
        CurrentCycleIndex++
        if (CurrentCycleIndex > DofusWindows.Length)
            CurrentCycleIndex := 1
        target := DofusWindows[CurrentCycleIndex]
        if WinExist(target.hwnd) {
            WinActivate(target.hwnd)
            LogMessage("Cycle : activation de " target.name)
        }
    }
}

TronquerTexte(txt, maxLen := 15) {
    if (StrLen(txt) > maxLen)
        return SubStr(txt, 1, maxLen - 1) "…"
    return txt
}

ActiverFenetreDofus(HotkeyName := "") {
    global BindsMap
    if BindsMap.Has(HotkeyName) {
        targetHwnd := BindsMap[HotkeyName]
        if WinExist(targetHwnd) {
            WinActivate(targetHwnd)
            title := WinGetTitle(targetHwnd)
            pseudo := RegExReplace(title, "\s*-\s*Dofus.*", "")
            LogMessage("Raccourci activé : focus sur " pseudo)
        }
    }
}

HasValue(arr, val) {
    for index, value in arr
        if (value = val)
            return true
    return false
}

ForcerVerification(*) {
    global LienVersion, LienMaj, LienExe, VersionActuelle, BtnMaj
    LogMessage("Recherche de mise à jour...")
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", LienVersion, false)
        whr.Send()
        VersionInternet := Trim(whr.ResponseText, " `t`r`n")
        if (VersionInternet != "" && VerCompare(VersionInternet, VersionActuelle) > 0) {
            BtnMaj.SetFont("cFFFF00")
            LogMessage("Mise à jour disponible : v" VersionInternet " !")
            if (MsgBox("Mise à jour disponible (v" VersionInternet ").`nInstaller maintenant ?", "MAJ", 4 + 32) == "Yes") {
                if A_IsCompiled {
                    ; === Mise à jour .exe via GitHub Releases ===
                    LogMessage("Téléchargement de la mise à jour en cours...")
                    try {
                        newExe := A_Temp "\AutoTrav_update.exe"
                        Download(LienExe, newExe)
                        batPath := A_Temp "\autotrav_updater.bat"
                        currentExe := A_ScriptFullPath
                        batContent := "@echo off`r`n"
                            . "timeout /t 2 /nobreak >nul`r`n"
                            . "copy /y `"" newExe "`" `"" currentExe "`" >nul`r`n"
                            . "del `"" newExe "`"`r`n"
                            . "start `"`" `"" currentExe "`"`r`n"
                            . "del `"%~0`"`r`n"
                        FileOpen(batPath, "w").Write(batContent)
                        Run(batPath,, "Hide")
                        ExitApp
                    } catch as e {
                        LogMessage("Erreur lors du téléchargement : " e.Message)
                    }
                } else {
                    ; === Mise à jour .ahk via Gist ===
                    try {
                        whr2 := ComObject("WinHttp.WinHttpRequest.5.1")
                        whr2.Open("GET", LienMaj, false)
                        whr2.Send()
                        FileOpen(A_ScriptFullPath, "w", "UTF-8").Write(whr2.ResponseText)
                        Reload()
                    } catch as e {
                        LogMessage("Erreur lors de la mise à jour : " e.Message)
                    }
                }
            }
        } else if (VersionInternet != "") {
            LogMessage("Le script est à jour (v" VersionActuelle ").")
        } else {
            LogMessage("Impossible de lire la version sur le serveur.")
        }
    } catch as e {
        LogMessage("Erreur de connexion : " e.Message)
    }
}

ChangerDePersonnage(GuiCtrl, *) {
    global TargetCharacter
    TargetCharacter := GuiCtrl.Text
    LogMessage("Compte cible voyage défini sur : " TargetCharacter)
}

CheckClipboard() {
    global lastClip, TargetCharacter, IsPaused
    if (IsPaused || TargetCharacter == "" || TargetCharacter == "Aucun compte")
        return
    current := Trim(A_Clipboard)
    if (current != lastClip && current != "") {
        if RegExMatch(current, "i)(/travel\s*)?-?\d+,-?\d+") {
            lastClip := current
            LogMessage("Coordonnées détectées : " current " -> Envoi à " TargetCharacter)
            GoToDofusAndPaste(current, TargetCharacter)
            A_Clipboard := ""
            lastClip := ""
        }
    }
}

GoToDofusAndPaste(coords, charName) {
    if !InStr(coords, "/travel")
        coords := "/travel " coords
    A_Clipboard := coords
    Sleep Random(50, 100)
    if WinExist(charName " ahk_exe Dofus.exe") {
        WinActivate(charName " ahk_exe Dofus.exe")
        if WinWaitActive(charName " ahk_exe Dofus.exe", , 3) {
            Sleep Random(180, 350)
            Send "{Enter down}"
            Sleep Random(25, 45)
            Send "{Enter up}"
            Sleep Random(95, 170)
            Send "^v"
            Sleep Random(115, 220)
            Send "{Enter down}"
            Sleep Random(25, 45)
            Send "{Enter up}"
        }
    }
}

TogglePause(*) {
    global IsPaused
    if (IsPaused)
        DesactiverPause()
    else
        ActiverPause()
}

ActiverPause(*) {
    global IsPaused, StatusText, BtnPauseToggle
    IsPaused := true
    StatusText.SetFont("cFF5555") 
    StatusText.Text := "En pause"
    BtnPauseToggle.Text := "▶ Activer"
    LogMessage("Surveillance du presse-papier mise en pause.")
}

DesactiverPause(*) {
    global IsPaused, StatusText, BtnPauseToggle
    IsPaused := false
    StatusText.SetFont("c55FF55") 
    StatusText.Text := "Active"
    BtnPauseToggle.Text := "⏸ Pause"
    LogMessage("Surveillance du presse-papier réactivée.")
}

VerifierMiseAJour() {
    global LienVersion, VersionActuelle, BtnMaj
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", LienVersion, false)
        whr.Send()
        VersionInternet := Trim(whr.ResponseText, " `t`r`n")
        if (VersionInternet != "" && VerCompare(VersionInternet, VersionActuelle) > 0) {
            BtnMaj.SetFont("cFFFF00")
            LogMessage("Mise à jour disponible : v" VersionInternet " ! Cliquez sur 🔄 pour l'installer.")
        }
    }
}

WatchMouse() {
    static isHovered := false
    MouseGetPos ,, &MouseWin
    if (MouseWin == ControlGui.Hwnd) {
        if (!isHovered) {
            WinSetTransparent(255, ControlGui.Hwnd)
            isHovered := true
        }
    } else if (isHovered) {
        WinSetTransparent(130, ControlGui.Hwnd)
        isHovered := false
    }
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd == ControlGui.Hwnd)
        PostMessage(0xA1, 2, , ControlGui.Hwnd)
}

QuitterScript(*) {
    ExitApp
}

WM_SETCURSOR(wParam, lParam, msg, hwnd) {
    global BtnRefresh, BtnSetCycle, BtnPauseToggle, BtnMaj
    try {
        if (hwnd == BtnRefresh.Hwnd || hwnd == BtnSetCycle.Hwnd || hwnd == BtnPauseToggle.Hwnd || hwnd == BtnMaj.Hwnd) {
            DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
            return String(true)
        }
    }
}