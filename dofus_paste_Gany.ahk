#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetTitleMatchMode 2

; ==================== CONFIGURATION ====================
VersionActuelle := "1.0.1"
LienMaj := "https://gist.githubusercontent.com/GlaiveTordu/d9f5e8f15fd6e34626bc7ad91ae23eca/raw/script.ahk"
LienVersion := "https://raw.githubusercontent.com/GlaiveTordu/AutoTrav/main/version.txt"
LienExe := "https://github.com/GlaiveTordu/AutoTrav/releases/latest/download/AutoTravelerDofus%20%5BATD%5D.exe"
ConfigDir := A_ScriptDir "\ATDconfig"
if (!DirExist(ConfigDir))
    DirCreate(ConfigDir)
ConfigFile := ConfigDir "\config_swapper.ini"
; =======================================================

SetMenuTheme("ForceDark")


GetIconPath(name) {
    return A_ScriptDir "\ATDconfig\" name
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
MettreTitreFonce(ControlGui.Hwnd)

; --- Barre de Menu Custom (Couleur du logiciel) ---
AccueilMenu := Menu()
AccueilMenu.Add("Info", AfficherInfo)

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
BtnMenuAccueil := ControlGui.Add("Text", "x15 y0 w65 h28 Center +0x0200 +BackgroundTrans", "Acceuil")
BtnMenuUpdate := ControlGui.Add("Text", "x90 y0 w130 h28 Center +0x0200 +BackgroundTrans", "Forcer la mise à jour")
ControlGui.Add("Text", "x15 y28 w690 h1 +Background33302D")

BtnMenuAccueil.OnEvent("Click", (*) => AccueilMenu.Show(15, 28))
BtnMenuUpdate.OnEvent("Click", ForcerVerification)

; --- En-tête (Header) ---
ControlGui.SetFont("s18 cE5C180 Bold", "Segoe UI")
ControlGui.Add("Text", "x15 y45 w400 h30 +BackgroundTrans", "AutoTravelerDofus [ATD]")

ControlGui.SetFont("s8.5 c8F8A85 Norm", "Segoe UI")
ControlGui.Add("Text", "x15 y75 w450 h15 +BackgroundTrans", "Outil de voyage et de gestion multicompte Dofus 3 Unity")

; Bouton Rafraîchir les processus (en haut à droite)
ControlGui.SetFont("s9 c1B1917 Bold", "Segoe UI")
BtnRefresh := ControlGui.Add("Text", "x535 y48 w170 h28 Center +0x0200 BackgroundD4A34F +Border vBtnRefresh", "Rafraîchir les processus")

; Ligne de séparation sous l'en-tête
ControlGui.Add("Text", "x15 y105 w690 h1 +Background33302D")

; --- Section Gauche : Instances Dofus ---
ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
ControlGui.Add("Text", "x15 y125 w250 h20 +BackgroundTrans", "Instances Dofus détectées")

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
ControlGui.Add("Picture", "x260 y124 w18 h18 +Disabled +BackgroundTrans", GetIconPath("cycle.png"))
BtnSetCycle := ControlGui.Add("Text", "x255 y121 w135 h24 Left +0x0200 Background2D2A26 +Border vBtnSetCycle", "       Cycle : " CycleHotkey)

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
AccountList := ControlGui.Add("ListView", "x15 y155 w375 h290 -Hdr -Multi Background1E1C1A cWhite -LV0x10 vAccountList", ["Perso", "Raccourci"])

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
BtnMoveUp := ControlGui.Add("Text", "x400 y240 w26 h26 Center +0x0200 Background2D2A26 +Border vBtnMoveUp", "▲")
BtnMoveDown := ControlGui.Add("Text", "x400 y275 w26 h26 Center +0x0200 Background2D2A26 +Border vBtnMoveDown", "▼")

; --- Section Droite : Voyage & Logs ---
ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
TravelFrame := ControlGui.Add("GroupBox", "x440 y118 w275 h148", "Paramètre du Groupe")

ControlGui.SetFont("s8.5 cFFFFFF Norm", "Segoe UI")
ControlGui.Add("Text", "x450 y141 w250 h15 +BackgroundTrans", "Sélectionner le compte qui reçoit la commande :")

ChoicePerso := ControlGui.Add("DDL", "x450 y160 w255 Background1E1C1A vChoicePerso", ["Aucun compte"])

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
ControlGui.Add("Picture", "x455 y195 w18 h18 +Disabled +BackgroundTrans", GetIconPath("invite.png"))
BtnInviteGroup := ControlGui.Add("Text", "x450 y192 w255 h24 Left +0x0200 Background2D2A26 +Border vBtnInviteGroup", "       Inviter Groupe")

ControlGui.SetFont("s8.5 cFFFFFF Norm", "Segoe UI")
TravelAllCheckbox := ControlGui.Add("Checkbox", "x450 y229 w250 h18 vTravelAllCheckbox", "Envoyer à toute l'équipe")
TravelAllCheckbox.Value := TravelAll

ShowLogCheckbox := ControlGui.Add("Checkbox", "x450 y277 w250 h18 Checked", "Afficher le journal d'activité")

ControlGui.SetFont("s10 cFFFFFF Bold", "Segoe UI")
LogTitle := ControlGui.Add("Text", "x450 y301 w250 h18 vLogTitle +BackgroundTrans", "Journal d'activité")

ControlGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
LogEdit := ControlGui.Add("Edit", "x450 y321 w255 h125 ReadOnly Multi Background1E1C1A vLogEdit")

; --- Barre de Statut (Bas) ---
ControlGui.Add("Text", "x15 y460 w690 h1 +Background33302D")

ControlGui.SetFont("s8.5 c8F8A85 Norm", "Segoe UI")
TxtVersion := ControlGui.Add("Text", "x15 y466 w100 h15 Left +BackgroundTrans vTxtVersion", "Version: v" VersionActuelle)

ControlGui.SetFont("s7 cFF3333 Italic Norm", "Segoe UI")
ControlGui.Add("Text", "x15 y484 w100 h14 Left +BackgroundTrans", "keyzome ♥")

ControlGui.SetFont("s8.5 cFFFFFF Bold", "Segoe UI")
ControlGui.Add("Text", "x125 y472 w170 h18 Left +BackgroundTrans", "Surveillance du presse-papier :")
ControlGui.SetFont("s8.5 c55FF55 Bold", "Segoe UI")
StatusText := ControlGui.Add("Text", "x300 y472 w90 h18 Left +BackgroundTrans vStatusText", "Active")

ControlGui.SetFont("s8.5 cE5C180 Bold", "Segoe UI")
ImgPause := ControlGui.Add("Picture", "x395 y471 w18 h18 +Disabled +BackgroundTrans", GetIconPath("pause.png"))
BtnPauseToggle := ControlGui.Add("Text", "x390 y467 w100 h24 Left +0x0200 Background2D2A26 +Border vBtnPauseToggle", "       Pause")

ControlGui.SetFont("s9 cE5C180 Bold", "Segoe UI")
BtnMaj := ControlGui.Add("Picture", "x680 y469 w20 h20 +BackgroundTrans +Hidden vBtnMaj", GetIconPath("update.png"))

; Événements
BtnRefresh.OnEvent("Click", (*) => ActualiserProcessDofus(false))
BtnSetCycle.OnEvent("Click", ModifierCycleHotkey)
BtnMoveUp.OnEvent("Click", (*) => DeplacerCompte("up"))
BtnMoveDown.OnEvent("Click", (*) => DeplacerCompte("down"))
TravelAllCheckbox.OnEvent("Click", ToggleTravelAll)
BtnInviteGroup.OnEvent("Click", InviterGroupe)
ShowLogCheckbox.OnEvent("Click", ToggleLog)
StatusText.OnEvent("Click", TogglePause)
BtnPauseToggle.OnEvent("Click", TogglePause)
BtnMaj.OnEvent("Click", ForcerVerification)
AccountList.OnEvent("DoubleClick", ModifierBindManuel)
ChoicePerso.OnEvent("Change", ChangerDePersonnage)
ControlGui.OnEvent("Close", QuitterScript)

ControlGui.Show("X10 Y10 W720 H505 NoActivate")
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
        BtnSetCycle.Text := "       Cycle : " CycleHotkey
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
        if RegExMatch(title, "^([^\-]+(?:-[^\-]+)*)\s+-\s+([A-Za-zÀ-ÿ]+)\s+-\s+\d[\d\.]+\s+-\s+Release", &Match) {
            pseudo := Match[1]
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
            BtnMaj.Opt("-Hidden")
            LogMessage("Mise à jour disponible : v" VersionInternet " !")
            if (MsgBox("Mise à jour disponible (v" VersionInternet ").`nInstaller maintenant ?", "MAJ", 4 + 32) == "Yes") {
                if A_IsCompiled {
                    ; === Mise à jour .exe via GitHub Releases ===
                    LogMessage("Téléchargement de la mise à jour en cours...")
                    try {
                        tags := ["v" VersionInternet, "V" VersionInternet]
                        filenames := ["AutoTravelerDofus.ATD.exe", "AutoTravelerDofus [ATD].exe"]
                        
                        LienExeDynamique := ""
                        whrCheck := ComObject("WinHttp.WinHttpRequest.5.1")
                        found := false
                        
                        for tag in tags {
                            for filename in filenames {
                                url := "https://github.com/GlaiveTordu/AutoTrav/releases/download/" tag "/" filename
                                try {
                                    whrCheck.Open("HEAD", url, false)
                                    whrCheck.Send()
                                    if (whrCheck.Status == 200) {
                                        LienExeDynamique := url
                                        found := true
                                        break 2
                                    }
                                }
                            }
                        }
                        
                        if (!found) {
                            LogMessage("Erreur : L'exécutable de mise à jour n'a pas pu être trouvé sur GitHub (404).")
                            MsgBox("L'exécutable de mise à jour n'a pas pu être trouvé sur GitHub (404).`n`nAssurez-vous d'avoir publié la release avec le tag 'v" VersionInternet "' (ou 'V" VersionInternet "') contenant le fichier 'AutoTravelerDofus.ATD.exe' ou 'AutoTravelerDofus [ATD].exe' sur GitHub.", "Erreur de mise à jour", 16)
                            return
                        }
                        
                        newExe := A_Temp "\AutoTravelerDofus_update.exe"
                        Download(LienExeDynamique, newExe)
                        batPath := A_Temp "\atd_updater.bat"
                        currentExe := A_ScriptFullPath
                        batContent := "@echo off`r`n"
                            . "chcp 65001 >nul`r`n"
                            . "timeout /t 2 /nobreak >nul`r`n"
                            . "copy /y `"" newExe "`" `"" currentExe "`" >nul`r`n"
                            . "del `"" newExe "`"`r`n"
                            . "start `"`" `"" currentExe "`"`r`n"
                            . "del `"%~0`"`r`n"
                        FileOpen(batPath, "w", "UTF-8-RAW").Write(batContent)
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
    BtnPauseToggle.Text := "       Activer"
    ImgPause.Value := GetIconPath("play.png")
    LogMessage("Surveillance du presse-papier mise en pause.")
}

DesactiverPause(*) {
    global IsPaused, StatusText, BtnPauseToggle, ImgPause
    IsPaused := false
    StatusText.SetFont("c55FF55") 
    StatusText.Text := "Active"
    BtnPauseToggle.Text := "       Pause"
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
            BtnMaj.Opt("-Hidden")
            LogMessage("Mise à jour disponible : v" VersionInternet " ! Cliquez sur l'icône de téléchargement en bas à droite pour l'installer.")
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
    global BtnRefresh, BtnSetCycle, BtnPauseToggle, BtnMaj, BtnMoveUp, BtnMoveDown, BtnInviteGroup
    try {
        if (hwnd == BtnRefresh.Hwnd || hwnd == BtnSetCycle.Hwnd || hwnd == BtnPauseToggle.Hwnd || hwnd == BtnMaj.Hwnd 
            || hwnd == BtnMoveUp.Hwnd || hwnd == BtnMoveDown.Hwnd || hwnd == BtnInviteGroup.Hwnd) {
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

AfficherInfo(*) {
    global VersionActuelle, ControlGui
    InfoGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +ToolWindow +Owner" ControlGui.Hwnd)
    InfoGui.BackColor := "1B1917"
    InfoGui.Title := "À propos"
    MettreTitreFonce(InfoGui.Hwnd)
    
    InfoGui.SetFont("s11 cE5C180 Bold", "Segoe UI")
    InfoGui.Add("Text", "x20 y20 w260 h22 Center", "AutoTravelerDofus [ATD]")
    
    InfoGui.SetFont("s9 cFFFFFF Norm", "Segoe UI")
    InfoGui.Add("Text", "x20 y52 w260 h18 Center", "Version : v" VersionActuelle)
    InfoGui.Add("Text", "x20 y75 w260 h18 Center", "Créateur : Glaive Tordu")
    
    InfoGui.SetFont("s8 c8F8A85 Norm", "Segoe UI")
    InfoGui.Add("Text", "x20 y105 w260 h36 Center", "Outil d'automatisation de trajet et de gestion multicompte Dofus 3 Unity.")
    
    InfoGui.SetFont("s9 c1B1917 Bold", "Segoe UI")
    BtnClose := InfoGui.Add("Text", "x100 y155 w100 h26 Center +0x0200 BackgroundD4A34F +Border", "Fermer")
    BtnClose.OnEvent("Click", (*) => InfoGui.Destroy())
    
    InfoGui.Show("w300 h200")
}

MettreTitreFonce(hwnd) {
    if (VerCompare(A_OSVersion, "10.0.17763") >= 0) {
        attr := (VerCompare(A_OSVersion, "10.0.18985") >= 0) ? 20 : 19
        DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", attr, "int*", true, "int", 4)
    }
}

SetMenuTheme(appMode := "ForceDark") {
    static preferredAppMode := {Default: 0, AllowDark: 1, ForceDark: 2, ForceLight: 3, Max: 4}
    if (preferredAppMode.HasProp(appMode))
        appMode := preferredAppMode.%appMode%
    hModule := DllCall("kernel32.dll\LoadLibrary", "str", "uxtheme.dll", "ptr")
    if (!hModule)
        return
    fnSetPreferredAppMode := DllCall("kernel32.dll\GetProcAddress", "ptr", hModule, "ptr", 135, "ptr")
    fnFlushMenuThemes := DllCall("kernel32.dll\GetProcAddress", "ptr", hModule, "ptr", 136, "ptr")
    if (fnSetPreferredAppMode && fnFlushMenuThemes) {
        DllCall(fnSetPreferredAppMode, "int", appMode)
        DllCall(fnFlushMenuThemes)
    }
}

RecreerIcones() {
    cycleHex := "89504E470D0A1A0A0000000D4948445200000018000000180806000000E0773DF8000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA8640000018649444154484BB5942F53C34010C52B9148241289442291957C0464256ED721917C844A64E4CED554222B3343728D8CAC2CF396BDCECD260D495B7E3367F2EEF2F6F6CFCD661329856EFCB78B1203715CF187FF7E31D420F03E069652E8DAEB679319ECEBC09B2874E7F79C456E60ABAD841EFDBE93E931D035C9A4125AD4422FFE3BE8372086C1A8E257420F31F04E732C74EF7567B0AB859E51EC18B8B19B2CFC9903A5D095162EF07EBBE237AF83CCA0C9038051323D5AF82834D7C8036F60E67560065F7D0317032F2DB877AF29887A287A80141E33FF167AB25BACBDA6C4C0856E109A7B6D0C560B4D93D7943A706906FD391C412A762374EB35886BEB84F13D9D81D4A50EEC4D23FAF8CF561B005D959AC46B0A86CB7258786D0C95D0AB9D5F7A4D41DED215D1115E1F223F8B99F0FA812C8A66CA738CE7DBD2F3E9B50ED9E60DFADEEB3918B8437BFF06D519C00EB86E7A32B03078DE08AD6C356B6D5F3B29AD68B334D96EA19535D7D92A4645DE87BDAECBFC46291DF8F160414F014338A5F8FFCE0FF9A4D84EF2D47F8D0000000049454E44AE426082"
    inviteHex := "89504E470D0A1A0A0000000D4948445200000018000000180806000000E0773DF8000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA8640000017C49444154484BED94AF4E433114C69148241289442291C84924121C0F4072CE138021990487E40D38EB428244226F425B26111393235F773BCAB76E778040C02F39A6A7FD7AFEB51B1B7F9268B2EB4D0E82C91EFB7E8C37398B4EA7D95E877AC97BBE0D222FC5B3BD981CF2DEB54129608DC966303961F19989F2B94E50DFE0F4B9107A0B26E78BE23A0D26C77C7E25295AA70D0B45A793E064406B8FD8CF1A2B8926BD8A78323439DCCB851FC88D37B96A4CB6F87C27489985B385C1E25A743AC2C5ACB394C6641BE5A808657B8A4EADB58FCB9D366BBF8DDAC404270FB57AA3A445CF4623931DDE53C5DBACA1DEE938989EB2BF0417E78C307DEC9F83DBE350AF97952838BDF326FB7C0EA0E1C820EDE35221023C7B168C4EC76D64E96079516D82DAE0D2B4B1A35F08DC221358192D9ADF0691B333EE497AA01C7DF1814DF02D7C72564865CC190DB5CFFE05F204049323F62D0399E54C6AA59AD3469366987D5DA00F290B931EFBE6A42F3835E6EB3F22326EA7AAB3ACFFFC1EEF4186102CD052E9880000000049454E44AE426082"
    tradeHex := "89504E470D0A1A0A0000000D4948445200000018000000180806000000E0773DF8000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000CB49444154484BED93310EC2300C457B04468ED1919191637013E7261C83D16D2F52893662E408A0AFA44A6A1440D899E0495E92D4FEBFFA6E9A3F351999B6F2CC14DF93F3BD3B571B1407DC7DEF6E33D351DEAF9898F6E183CF6BEEA88B03962ABBC9D4680B6E5AD9DFCAC1F5C27490BDBF66E57A70A7916923DFA888036C55E74C4C3B73D55528464F0B1A23DBF8D7F24E0D3613990E29311C9054A77C87BC3FEFC1ABC25EC9DE50DD26D5DA2AB846A691EDFCB1998305641B9BF9568D96E4A6D2000037D85879FE3B3C00236FA97A1744E9B70000000049454E44AE426082"
    pauseHex := "89504E470D0A1A0A0000000D4948445200000018000000180806000000E0773DF8000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA8640000006949444154484BEDD4B109C02014455147CB66FF6F2699253887218490F26867E1010BB9F84A4BD99675D538DA19F99DE73ED3E97D98FD3F91339D34A04E1A50270DA89306D44903EAA40175D2803A69409D34A04E1A50270DA89306D44903EAA40175D27FAFBE0DBB01B2B4EC82C8B91CBE0000000049454E44AE426082"
    playHex := "89504E470D0A1A0A0000000D4948445200000018000000180806000000E0773DF8000000017352474200AECE1CE90000000467414D410000B18F0BFC6105000000097048597300000EC300000EC301C76FA864000000D749444154484BED94A10EC2301445279148241289442291483E0389BB75483E81CF987CD9CC3E01B984AE9B9C9C1C2914425E96D27615889DE49AF5BE9E645D9724137F4B4358F26751511984CA445111D67C2D0A46D0EBD4B938978439EF8CE25B60D228C29EF7821910BC9346391F8B40A79384534998F139677E089EA9327193842D9F75C245F0492EAE2561C1F7B0E22578A5F5FAA47D04FA55DD093BBE87154741A77B4187ED20481561C5E79CB1089A8A70E07D6F8604752E2ED17E194C5048C28677466104AD241CF95A14F40DF5BE3C13213C006C0C816C2B525D730000000049454E44AE426082"
    updateHex := "89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7AF400000811494441547801C4567D6C54C7119F7DEF3EFC81ED58100A51A18E69AA821397D80E722590CF8DAB00364EF9B0AB60BB24240D7144D24A91FA478BEAE72AAD54297F3511B48454494502F81CA509B83104E2733E716D23426A406D49D2B3F00711363EDFF9EEDEEDEE74E6D977C1D801E2FC91D5CEBD79BB3BF3FBCDECCEBE33E01B6E73228008A2A5A5C64416B4E6E42319F74D1B33684787CF6559962104606DAD5F09166169041030C77653043852062D2F0F4822A087DE6F58D87FB866D5607B4DE5F9D6EA4242277E73237143029C6A8EF4FCEBD559C327EA1EBB78ACF6447C2C7656A2EA524A1DF1B8F0D4B996CA6287C4D476704690B2C519BB5162BE940085245838D503C7EBEBE6E7649FF6B88D3D195EF78FB2D3CDF919696CAA0151835448F804D54C429D5E5050B63863885373343E5B672F33C611399D16F901180C6CDB9D95E1DE0F08F94A2908856343A3A1E8CB6391F89308B0652C2C8BEF7AE01F3DA40B61599A6DB1E3C1B4FEF6079A3F3BBC79A7101407B23F476660CD4680806BE8A059FAD2DBDBFE969BE96E8C446D9052856D5BEDF208A330FFFED7EBBFB7F1F0B34B2AFFFE6A51C3D18F18948C90D32E04E0C5B85DF3EDC599BFCDC9CD7A76E4BD478FC0B95F2F42CB227ED60CBC190374E008DCAF863A1EDA754B8EA77E2C14478AE1D3785497DD76DFA1DF2F5EEFFF9CD6987C3692E130A8A377FA9C0C28C0530383A1610DA6CECD76579EFDF8740DA1EBA6157DC4D35999FA9946C0715AEBD723EF3C52E87681158AC43580BE141A573FCEAB3E740A7B1E7573B450E3D70500E670C7B667068ED73DD3D752E3E1710681664B7C67ED81BEF170AC6A627C2CDCDF3FA8E8ECFCF1426BD51D6C4799988639EDA586780900B413B2D9EB364CD06844A3EAE13B361EBAC0E0A2646FC2EFE7ED015CB868DE9D39F3DC4F6567B89ECACC36EEE42C70004C82B7E2FB5BDEE8094FC41B416B33DD63A4C5A4B2780D5C9385140166C6E5367C7C7B3E18B80EB5C6683CF1665ED5C13676C8E0C42FD59594EE2BA1A8624125DDA9095204550097E0F2CD875F0947E301AA0404A536F6BC54B194312C0B52B82905CA2607B521D7CE4B7779290BC214620F22880039E54E8E447E7EAEC191A2AD502B65B2B0CE633CC7EB792D0BEB02C573526A919E665022702D8F9795F952B829250093301AC53D2E1A8D4CD8A3C2860F396D3E5F40013541255542DBC07783145A7059B248650B1EE3394155404BC14736ACDB71F96E78C2BEE2328108EB529EBB5A086AF2D54727983503D412C78786E0E20D072EF318802580DA4067C3F2C8C9ED6F058FFEB4D18EC44751D1795712A88F7EF46259E37F5BCADFEA7DBE74392D056806C7A6B0E1D8E7A031483E05656B29CF25B1584F1180260B819A56988E943B2DF404796055F4EE1D30690AB4AD3765E4782A5442ED4603774D44E3321A4B48DB8EED5208BB73D28D0A5BEA4DBCB67771B1496E8420648D3282F482A0D3792E89C5FA17049A27A3D474F6B4D6800A33C9460872503CB8575916186EA1F7F57F76F94CBA47D081D10D5A29176D81CB10D8E075217C3A10FA58C4C53E5E5B3CD8ABD896A212E427830E3590DF28706B9EC46235452050167074A555502A854AEBA5175EDB782B2F8226203F00DFAA38303C3E1EDD108DDA41D40AA4944A91B01E8FDBC138E8AAD25F760D03B7A6499B7FBFE29BAF142E95CE76413F50A3F3E660914A81F02F898F84BBD0FA245DB922C36BDCA205AE21F62210F0991495E61BB0A0F648702C125BAFA4BAEC32D03485369594231331B57ECD8EDE205703AF0D34FB9C2D8849E387E95E914B3E0184FE275CD3524C9AA70EA1D4D03E168E450D4ABD56923E269391B01DD730D7F7CAAD47FBC2D1E806020E29A542A17062C3EA9DDD7D1D96CFC5D5C06B59780BA4948D26F91A9F48C4A96C8EF2782704E886650DBEC88065594E84CBAAFD41D0F81A228A3497F0F51DB86FABF359EDF0B9D8C4D1D1328AB6757E782994281C99C0C2B25F747FC01759B91590BCA6E72FC56ED67BF6ADA9F4B8C43ADA564AAC7EF39EC7BB3F496688D7B1A432C02F70B68070A97CA4698523F19816A0BC6E734FD70BBE12BEDDD09A244CDF5DCD80F7EEFCE07F2C3CEE5CC10882C14B76F426BAFFBA3ADFEB315ED0D46231A9C0842604F20DD3DB3402EC04E8AE5FB6E5D5FFD871FB5779794BCCAC050BE6657A45DBE917CB0BA0099081811AAFE5ED60C04099CFE0F3C12967F0D32F55DC9DE1711FD71A1752C51852A255FAF3AE33FE961AE3EA2D22379311B1929466CE8265192B5696B48E8E27DA543C6ADCB6207DA1465DC400C913CCD1F07630203FF97C9C6A5977EBF98315BF719BFA1DA5F4ED195E2146C6EDFDAB1E3BF9341324709DC4493EA7658007F92C507408CBFF30347FF5F3558317879E080E457E970BC2EF805A01C94F0180FF3A58F58381B69F6C3EE7AF7CE2DCA1B5FBD3A43AE332C5D37463CFF3B8058C47D49ED21D277FE6648D3EF3E49F4CE9F7AA3E83C0D41C72B4742044F1F6779F5BF96067D3ED0F05620CCACEF879A1B5BA242BD3D5AB105BB3D28C3F65659875F43F7111D98056FA934834515FF4C87B8F23435A16B2CD94EF698F2F23E02C12140A9716EF350D900FFA6D22A19E20A16D014A35456AC3D8B87D9940DFB66DD918BC12BBBBF8E1F75FE6132FA804C91069F9ACFDBA04D882CB89F79874C7891054AE00C2F9C311B68B48ADA274AFF2A68915057527EE2DA80FFC79FD935D2106A73D77BEA2709D764302B3D97244C446DCB5B5FD4CDEFD6FB42DDBDCDEFDDD4DC72E5916189C314ABBF3799ECDF6DAB1391160270E09B49CF2E36819940868CE18A79DD7DC8CCC99003BE7EDE0F2E3547F1550B64DCAD722907472BDE78DE6FE0F0000FFFFA11F6C5F000000064944415403000E4A8D7D8B29FFCC0000000049454E44AE426082"
    
    if (!FileExist(GetIconPath("cycle.png")))
        WriteHexToFile(cycleHex, GetIconPath("cycle.png"))
    if (!FileExist(GetIconPath("invite.png")))
        WriteHexToFile(inviteHex, GetIconPath("invite.png"))
    if (!FileExist(GetIconPath("pause.png")))
        WriteHexToFile(pauseHex, GetIconPath("pause.png"))
    if (!FileExist(GetIconPath("play.png")))
        WriteHexToFile(playHex, GetIconPath("play.png"))
    if (!FileExist(GetIconPath("update.png")))
        WriteHexToFile(updateHex, GetIconPath("update.png"))
}