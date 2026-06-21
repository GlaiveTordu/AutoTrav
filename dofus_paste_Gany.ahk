#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetTitleMatchMode 2

; ==================== CONFIGURATION ====================
VersionActuelle := "0.0.8"
LienMaj := "https://gist.githubusercontent.com/GlaiveTordu/d9f5e8f15fd6e34626bc7ad91ae23eca/raw/script.ahk"
LienVersion := "https://raw.githubusercontent.com/GlaiveTordu/AutoTrav/main/version.txt"
LienExe := "https://github.com/GlaiveTordu/AutoTrav/releases/latest/download/AutoTravelerDofus%20%5BATD%5D.exe"
ConfigFile := A_ScriptDir "\config_swapper.ini"
; =======================================================

GetIconPath(name) {
    return A_ScriptDir "\" name
}

RecreerIcones()

TargetCharacter := ""
lastClip := ""
IsPaused := false
DofusWindows := []  
BindsMap := Map()   
CustomKeys := Map() 
RowData := []  
CurrentCycleIndex := 0
TravelAll := false
BtnMoveUp := ""
BtnMoveDown := ""
TravelAllCheckbox := ""
BtnInviteGroup := ""
BtnTradeGroup := ""
ImgPause := ""

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
        TravelAll := (IniRead(ConfigFile, "Config", "TravelAll", "0") == "1")
    }
} else {
    CycleHotkey := "Tab"
}

TrayTip "AutoTravelerDofus [ATD]", "Interface stable activée ! 🚀", 1

ControlGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow +E0x02000000 +E0x00080000")
ControlGui.BackColor := "1B1917"
ControlGui.Title := "AutoTravelerDofus [ATD] - Dofus 3 Unity Multi-Account Helper"

; --- En-tête (Header) ---
ControlGui.SetFont("s18 cE5C180 Bold", "Segoe UI")
ControlGui.Add("Text", "x15 y15 w400 h30 +BackgroundTrans", "AutoTravelerDofus [ATD]")

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
ControlGui.Add("Picture", "x261 y95 w16 h16 +Disabled +BackgroundTrans", GetIconPath("cycle.png"))
BtnSetCycle := ControlGui.Add("Text", "x255 y91 w135 h24 Left +0x0200 Background2D2A26 +Border vBtnSetCycle", "      Cycle : " CycleHotkey)

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
AccountList := ControlGui.Add("ListView", "x15 y125 w375 h290 -Hdr -Multi Background1E1C1A cWhite -LV0x10 vAccountList", ["Perso", "Raccourci"])

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
BtnMoveUp := ControlGui.Add("Text", "x400 y210 w26 h26 Center +0x0200 Background2D2A26 +Border vBtnMoveUp", "▲")
BtnMoveDown := ControlGui.Add("Text", "x400 y245 w26 h26 Center +0x0200 Background2D2A26 +Border vBtnMoveDown", "▼")

; --- Section Droite : Voyage & Logs ---
ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
TravelFrame := ControlGui.Add("GroupBox", "x440 y88 w275 h148", "Paramètre du Groupe")

ControlGui.SetFont("s8.5 cFFFFFF Norm", "Segoe UI")
ControlGui.Add("Text", "x450 y111 w250 h15 +BackgroundTrans", "Sélectionner le compte qui reçoit la commande :")

ChoicePerso := ControlGui.Add("DDL", "x450 y130 w255 Background1E1C1A vChoicePerso", ["Aucun compte"])

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
ControlGui.Add("Picture", "x456 y166 w16 h16 +Disabled +BackgroundTrans", GetIconPath("invite.png"))
BtnInviteGroup := ControlGui.Add("Text", "x450 y162 w120 h24 Left +0x0200 Background2D2A26 +Border vBtnInviteGroup", "      Inviter Groupe")
ControlGui.Add("Picture", "x591 y166 w16 h16 +Disabled +BackgroundTrans", GetIconPath("trade.png"))
BtnTradeGroup := ControlGui.Add("Text", "x585 y162 w120 h24 Left +0x0200 Background2D2A26 +Border vBtnTradeGroup", "      Échange Général")

ControlGui.SetFont("s8.5 cFFFFFF Norm", "Segoe UI")
TravelAllCheckbox := ControlGui.Add("Checkbox", "x450 y199 w250 h18 vTravelAllCheckbox", "Envoyer à toute l'équipe")
TravelAllCheckbox.Value := TravelAll

ShowLogCheckbox := ControlGui.Add("Checkbox", "x450 y247 w250 h18 Checked", "Afficher le journal d'activité")

ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
LogTitle := ControlGui.Add("Text", "x450 y271 w250 h18 vLogTitle +BackgroundTrans", "Journal d'activité")

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
LogEdit := ControlGui.Add("Edit", "x450 y291 w255 h125 ReadOnly Multi Background1E1C1A vLogEdit")

; --- Barre de Statut (Bas) ---
ControlGui.Add("Text", "x15 y430 w690 h1 +Background33302D")

ControlGui.SetFont("s8.5 c8F8A85 Norm", "Segoe UI")
TxtVersion := ControlGui.Add("Text", "x15 y442 w80 h18 Left +BackgroundTrans vTxtVersion", "Version: v" VersionActuelle)

ControlGui.SetFont("s8.5 cFFFFFF Bold", "Segoe UI")
ControlGui.Add("Text", "x110 y442 w170 h18 Left +BackgroundTrans", "Surveillance du presse-papier :")
ControlGui.SetFont("s8.5 c55FF55 Bold", "Segoe UI")
StatusText := ControlGui.Add("Text", "x285 y442 w90 h18 Left +BackgroundTrans vStatusText", "Active")

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
ImgPause := ControlGui.Add("Picture", "x386 y441 w16 h16 +Disabled +BackgroundTrans", GetIconPath("pause.png"))
BtnPauseToggle := ControlGui.Add("Text", "x380 y437 w100 h24 Left +0x0200 Background2D2A26 +Border vBtnPauseToggle", "      Pause")

ControlGui.SetFont("s7 cFF3333 Italic Norm", "Segoe UI")
ControlGui.Add("Text", "x610 y442 w60 h18 Right +BackgroundTrans", "keyzome ♥")

ControlGui.SetFont("s9 cE5C180 Bold", "Segoe UI")
BtnMaj := ControlGui.Add("Text", "x675 y437 w30 h24 Center +0x0200 Background2D2A26 +Border vBtnMaj", "🔄")

; Événements
BtnRefresh.OnEvent("Click", (*) => ActualiserProcessDofus(false))
BtnSetCycle.OnEvent("Click", ModifierCycleHotkey)
BtnMoveUp.OnEvent("Click", (*) => DeplacerCompte("up"))
BtnMoveDown.OnEvent("Click", (*) => DeplacerCompte("down"))
TravelAllCheckbox.OnEvent("Click", ToggleTravelAll)
BtnInviteGroup.OnEvent("Click", InviterGroupe)
BtnTradeGroup.OnEvent("Click", LancerEchangeGeneral)
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

LogMessage("AutoTravelerDofus [ATD] démarré avec succès.")
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
        BtnSetCycle.Text := "      Cycle : " CycleHotkey
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
    tempList := []
    for hwnd in WinList {
        title := WinGetTitle(hwnd)
        ; Extraire seulement PSEUDO - CLASSE (retirer version, "Release", etc.)
        pseudo := RegExReplace(title, "\s*-\s*\d[^-]*-\s*Release.*$", "")
        pseudo := RegExReplace(pseudo, "\s*-\s*Dofus.*", "")
        if (pseudo != "" && !InStr(pseudo, "Dofus Updater")) {
            tempList.Push({hwnd: hwnd, name: pseudo})
        }
    }
    
    ; Tri par ordre personnalisé (CycleOrder)
    savedOrderStr := ""
    try savedOrderStr := IniRead(ConfigFile, "Config", "CycleOrder")
    if (savedOrderStr != "") {
        savedOrderArr := StrSplit(savedOrderStr, ",")
        orderedList := []
        
        ; Ajouter en premier les fenêtres correspondant à l'ordre sauvegardé
        for name in savedOrderArr {
            Loop tempList.Length {
                idx := A_Index
                if (tempList[idx].name == name) {
                    orderedList.Push(tempList[idx])
                    tempList.RemoveAt(idx)
                    break
                }
            }
        }
        ; Ajouter les nouvelles fenêtres restantes
        for win in tempList {
            orderedList.Push(win)
        }
        tempList := orderedList
    }
    
    ; Enregistrement et mise en place
    for win in tempList {
        pseudo := win.name
        hwnd := win.hwnd
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
        AccountList.Add(, TronquerTexte(pseudo, 40), bindKey != "" ? "[ " bindKey " ]" : "")
        BindsMap[bindKey] := hwnd
        try Hotkey(bindKey, ActiverFenetreDofus, "On")
        
        LogMessage("Nouvelle instance détectée : " pseudo)
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
    AccountList.ModifyCol(1, 260)
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
                        newExe := A_Temp "\AutoTravelerDofus_update.exe"
                        Download(LienExe, newExe)
                        batPath := A_Temp "\atd_updater.bat"
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
    global lastClip, TargetCharacter, IsPaused, TravelAll, DofusWindows
    if (IsPaused || TargetCharacter == "" || TargetCharacter == "Aucun compte")
        return
    current := Trim(A_Clipboard)
    if (current != lastClip && current != "") {
        if RegExMatch(current, "i)(/travel\s*)?-?\d+,-?\d+") {
            lastClip := current
            if (TravelAll && DofusWindows.Length > 0) {
                LogMessage("Coordonnées détectées : " current " -> Envoi à TOUTE l'équipe")
                for win in DofusWindows {
                    if WinExist(win.hwnd) {
                        GoToDofusAndPaste(current, win.name)
                        Sleep Random(400, 600)
                    }
                }
            } else {
                LogMessage("Coordonnées détectées : " current " -> Envoi à " TargetCharacter)
                GoToDofusAndPaste(current, TargetCharacter)
            }
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
    global IsPaused, StatusText, BtnPauseToggle, ImgPause
    IsPaused := true
    StatusText.SetFont("cFF5555") 
    StatusText.Text := "En pause"
    BtnPauseToggle.Text := "      Activer"
    ImgPause.Value := GetIconPath("play.png")
    LogMessage("Surveillance du presse-papier mise en pause.")
}

DesactiverPause(*) {
    global IsPaused, StatusText, BtnPauseToggle, ImgPause
    IsPaused := false
    StatusText.SetFont("c55FF55") 
    StatusText.Text := "Active"
    BtnPauseToggle.Text := "      Pause"
    ImgPause.Value := GetIconPath("pause.png")
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
    global BtnRefresh, BtnSetCycle, BtnPauseToggle, BtnMaj, BtnMoveUp, BtnMoveDown, BtnInviteGroup, BtnTradeGroup
    try {
        if (hwnd == BtnRefresh.Hwnd || hwnd == BtnSetCycle.Hwnd || hwnd == BtnPauseToggle.Hwnd || hwnd == BtnMaj.Hwnd 
            || hwnd == BtnMoveUp.Hwnd || hwnd == BtnMoveDown.Hwnd || hwnd == BtnInviteGroup.Hwnd || hwnd == BtnTradeGroup.Hwnd) {
            DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))
            return String(true)
        }
    }
}

ToggleTravelAll(Ctrl, *) {
    global TravelAll, ConfigFile
    TravelAll := Ctrl.Value
    IniWrite(TravelAll ? "1" : "0", ConfigFile, "Config", "TravelAll")
    LogMessage("Option voyage de groupe " (TravelAll ? "activée" : "désactivée"))
}

DeplacerCompte(direction) {
    global DofusWindows, RowData, ConfigFile, BindsMap, CustomKeys
    RowNumber := AccountList.GetNext(0, "Focused")
    if (RowNumber = 0)
        return
    
    targetIndex := RowNumber
    swapIndex := (direction == "up") ? RowNumber - 1 : RowNumber + 1
    
    if (swapIndex < 1 || swapIndex > DofusWindows.Length)
        return
        
    ; Intervertir dans les tableaux
    tempWin := DofusWindows[targetIndex]
    DofusWindows[targetIndex] := DofusWindows[swapIndex]
    DofusWindows[swapIndex] := tempWin
    
    tempRow := RowData[targetIndex]
    RowData[targetIndex] := RowData[swapIndex]
    RowData[swapIndex] := tempRow
    
    ; Reconstruire la liste et réattribuer les hotkeys
    ReconstruireBindsEtListView()
    
    ; Sauvegarder l'ordre
    SaveCycleOrder()
    
    ; Sélectionner l'élément déplacé
    AccountList.Modify(swapIndex, "+Focus +Select")
}

ReconstruireBindsEtListView() {
    global DofusWindows, RowData, BindsMap
    AccountList.Delete()
    
    for key, hwnd in BindsMap
        try Hotkey(key, "Off")
    BindsMap := Map()
    
    Loop DofusWindows.Length {
        pseudo := RowData[A_Index].pseudo
        bindKey := RowData[A_Index].bind
        
        AccountList.Add(, TronquerTexte(pseudo, 40), bindKey != "" ? "[ " bindKey " ]" : "")
        BindsMap[bindKey] := DofusWindows[A_Index].hwnd
        try Hotkey(bindKey, ActiverFenetreDofus, "On")
    }
}

SaveCycleOrder() {
    global DofusWindows, ConfigFile
    orderStr := ""
    for item in DofusWindows {
        orderStr .= (orderStr == "" ? "" : ",") item.name
    }
    IniWrite(orderStr, ConfigFile, "Config", "CycleOrder")
}

InviterGroupe(*) {
    global DofusWindows
    if (DofusWindows.Length < 2) {
        LogMessage("Pas assez de comptes détectés pour former un groupe.")
        return
    }
    
    chefWin := DofusWindows[1]
    if !WinExist(chefWin.hwnd) {
        LogMessage("Le compte principal n'existe pas.")
        return
    }
    
    LogMessage("Lancement des invitations de groupe depuis " chefWin.name "...")
    WinActivate(chefWin.hwnd)
    if WinWaitActive(chefWin.hwnd, , 3) {
        Sleep 200
        for idx, win in DofusWindows {
            if (idx == 1)
                continue
            
            cmd := "/invite " win.name
            A_Clipboard := cmd
            Sleep 50
            
            Send "{Enter down}"
            Sleep Random(25, 45)
            Send "{Enter up}"
            Sleep Random(100, 150)
            Send "^v"
            Sleep Random(100, 150)
            Send "{Enter down}"
            Sleep Random(25, 45)
            Send "{Enter up}"
            Sleep Random(300, 500)
        }
        LogMessage("Invitations de groupe envoyées !")
    }
}

LancerEchangeGeneral(*) {
    global DofusWindows
    if (DofusWindows.Length < 2) {
        LogMessage("Pas assez de comptes détectés pour lancer un échange.")
        return
    }
    
    chefName := DofusWindows[1].name
    LogMessage("Lancement des invitations d'échange vers " chefName "...")
    
    for idx, win in DofusWindows {
        if (idx == 1)
            continue
        
        if WinExist(win.hwnd) {
            WinActivate(win.hwnd)
            if WinWaitActive(win.hwnd, , 3) {
                Sleep 200
                cmd := "/exchange " chefName
                A_Clipboard := cmd
                Sleep 50
                
                Send "{Enter down}"
                Sleep Random(25, 45)
                Send "{Enter up}"
                Sleep Random(100, 150)
                Send "^v"
                Sleep Random(100, 150)
                Send "{Enter down}"
                Sleep Random(25, 45)
                Send "{Enter up}"
                Sleep Random(300, 500)
            }
        }
    }
    LogMessage("Demandes d'échanges envoyées vers " chefName " !")
}

WriteHexToFile(hex, filepath) {
    len := StrLen(hex) // 2
    buf := Buffer(len)
    Loop len {
        byteHex := SubStr(hex, (A_Index - 1) * 2 + 1, 2)
        NumPut("UChar", Integer("0x" byteHex), buf, A_Index - 1)
    }
    file := FileOpen(filepath, "w")
    file.RawWrite(buf)
    file.Close()
}

RecreerIcones() {
    cycleHex := "89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF61000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000F649444154384FB592A10EC23010862791481E018944227904241289C4DD39241E33C923E0B8740689442E61BBF108939063B7E5DA6D0412F8928AFE77FDDBFE6D14FD9B9460146A5FC10E901D1E52826158FB083578E40EAF39C124ACB7C8083629C1A09ED7063ACADB09F6B6EE712398B3C3A3D58C419913ACAA39A0ED696087F7303469B6C797DDD9E18509C6B62F920629786275A56918202718E7044BAB89C142D2F6C41E32827591E02E14A7ECF0EC893DC86231F14439A666D09DB0811D5246300B754DBC2761A5EBA51A34616A05A4E8E24BF8521EAFAB24184B6391E056CCF42F90ECFC76B1459E557E656506D879E75FF004B15CC41F48B9F9DD0000000049454E44AE426082"
    inviteHex := "89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF61000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000EF49444154384FD591A14E034110862B2B91C84A1441565656F611780424A2C9FFBF412D6F518969323725A41259D55CC2ED141C028184CCA577BD1B16B0F44B26D9D99B996F776F3038192AC1A4140CE3FE9F7853526E4DF969CAB752701E6BB234C624B83E34D751096E636D8F68DCAD7069CA8FCE8071ECE991339AE0C2147C164C63FD37FC8E5D632AB830A51C032C0567B1AF871B5381BBAAC0EB7ECD85BF47133E2029CBEC69FCFE95E0C6941B53BEDB9A8F39A3E7A6BCF781ED66125CF9E4DA58F02109E6BF19BDDE944F75F2221879D2FCE3C3BAB5668D3E44B96C172698753F467AC64834FE446BFC577C01716CEAB8192078B20000000049454E44AE426082"
    tradeHex := "89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF61000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000A349444154384F63601832E0FEFE7A09743192C0D383F50D4F0F362CBFBFBF5E005D8E280035E0FF93830DD79FECAF37409767787AB0613F480191F8FBE3FDF50EE866E005301780343FD95F9F812E4F10800CC0E97C6C003DB01EEFAFB74017C30AEEEFAFE7787AA8613AC846743982E0E9FE7A8DA7071BCE43FC4AA20120BF3D3DD8F01E4B88E3C2FBD1CD0019128130844417C000C21B641A0002A080243ABA280500BEFAA8DE05E385390000000049454E44AE426082"
    pauseHex := "89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF61000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA8640000005149444154384FDD92C10900200CC41CCDCDDACDC459C43914F19BFCC5C0410979B694FF182DEAEC9167E736A7DC30D75DA4398562720AC5E4148AC9291493532826A7504C4EA1989C42313985BE8EDC3B6CBB5DF8995CD595BB0000000049454E44AE426082"
    playHex := "89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF61000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA8640000008249444154384F6360187EE0F9FE7A05743192C0D383F50D4F0F361C7FBABF5E035D8E280035E03F083F3BD4D07E7F7F3D07BA1ABC00D900107E72B0E1FEA3FDF51EE8EA7002740390F0F2FBFBEB25D0D563003C0680F0FB27FBEB0DD0F5A0005C0610ED156C069014986806901E9D5003407ECD4097230A3CDE5FEF4054680F1A0000A575A2886BCB2BD30000000049454E44AE426082"
    
    if (!FileExist(A_ScriptDir "\cycle.png"))
        WriteHexToFile(cycleHex, A_ScriptDir "\cycle.png")
    if (!FileExist(A_ScriptDir "\invite.png"))
        WriteHexToFile(inviteHex, A_ScriptDir "\invite.png")
    if (!FileExist(A_ScriptDir "\trade.png"))
        WriteHexToFile(tradeHex, A_ScriptDir "\trade.png")
    if (!FileExist(A_ScriptDir "\pause.png"))
        WriteHexToFile(pauseHex, A_ScriptDir "\pause.png")
    if (!FileExist(A_ScriptDir "\play.png"))
        WriteHexToFile(playHex, A_ScriptDir "\play.png")
}