; JSSatchell 2023
; https://github.com/JSSatchell/HyperSearch

#Requires AutoHotkey v2.0

; Set icon
if FileExist("HyperSearch.ico")
   TraySetIcon("HyperSearch.ico")
else
   TraySetIcon "shell32.dll", 210 ; Magnifying glass

SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#SingleInstance force
CoordMode "Mouse"

;;;;;;;;;;;;;;;;;;;;;;;;;
; UPDATE VERSION NUMBER 
version:="0.3.2"        
;;;;;;;;;;;;;;;;;;;;;;;;;

; Use default browser
ProgID := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice", "Progid")
Browser := "msedge.exe"
if (ProgID = "ChromeHTML")
   Browser := "chrome.exe"
if (ProgID ~= "FirefoxURL.*")
   Browser := "firefox.exe"
if (ProgID = "BraveHTML")
   Browser := "brave.exe"

; Initialize global variables
lastIndex:=1
lastLinkIndex:=1
mouseKeep:=0
todayQuick := FormatTime(, "yyMMdd")
controlColor := ""
urlTxtColor := ""
guiFont := ""
UsrIn := ""
linkArray := []
linkString := ""
mouseX:=""
mouseY:=""
hsrDup:=0
guiReload:=1

; Check for settings File
if !FileExist("HS_Settings.ini")
   GenerateSettings()
else
   CheckSettings()

; Read Settings
searchEngine := IniRead("HS_Settings.ini", "Search Engine", "Default")
GUIHotkey := IniRead("HS_Settings.ini", "Settings", "GUIHotkey")
hiHotkey := IniRead("HS_Settings.ini", "Settings", "HighlightHotkey")
jump := IniRead("HS_Settings.ini", "Settings", "jump")
sMode := IniRead("HS_Settings.ini", "Settings", "SearchMode")
repo := sMode = "web" ? IniRead("HS_Settings.ini", "Settings", "Repository") : IniRead("HS_Settings.ini", "Settings", "DirRepo")
modeTxt := sMode = "web" ? "Web Mode: " : "File Mode: "
urlDisplay := modeTxt
minMode := IniRead("HS_Settings.ini", "Settings", "MinMode")
currentGui := minMode = 1 ? "LiteGui" : "MainGui"

; Check for repo file
if !FileExist(repo) {
   if (sMode = "web")
      GenerateHSR("HSR_Master.csv",1)
   else if (sMode = "dir")
      GenerateHSR("HFR_Master.csv",2)
}

Loop Files, repo
   repoName := A_LoopFileName

; Initialize GUI variables
MainGui := Gui()
LiteGui := Gui()

; Initialize Hotkeys
Hotkey GUIHotkey, loadGUI
Hotkey hiHotkey, searchHighlight
LocalHotkeysOff()

!s::
{
   currentControl := WinGetClass(%currentGui%.FocusedCtrl)
   if (currentControl~="ListBox") {
      send "{down}"
   } else if (currentControl=="Edit") {
      send "+{tab}"
   } else
      send "!s"
}

!a::
{
   currentControl := WinGetClass(%currentGui%.FocusedCtrl)
   if (currentControl~="ListBox") {
      send "+{tab}"
   } else if (currentControl=="Edit") {
      send "{tab}"
   } else
      send "!a"
}

!w::
{
   currentControl := WinGetClass(%currentGui%.FocusedCtrl)
   if (currentControl~="ListBox") {
      send "{up}"
   } else if (currentControl=="Edit") {
      send "+{tab}{up}"
   } else
      send "!a"
}

!d::
{
   currentControl := WinGetClass(%currentGui%.FocusedCtrl)
   if (currentControl~="ListBox") {
      send "{tab}"
   } else if (currentControl=="Edit") {
      send "+{tab}"
   } else
      send "!d"
}

!q::
{
   currentControl := WinGetClass(%currentGui%.FocusedCtrl)
   if (currentControl=="Edit") {
      send "^a"
      send "{backspace}"
   } else
      send "!q"
}

Tab::
{
   currentControl := WinGetClass(%currentGui%.FocusedCtrl)
   if (currentControl=="Edit") {
      send "   "
   } else
      send "{tab}"
}

LocalHotkeysOff()
{
   Hotkey "RButton", RMenu, "off"
   Hotkey "!s", "off", "I2"
   Hotkey "!a", "off", "I2"
   Hotkey "!w", "off", "I2"
   Hotkey "!d", "off", "I2"
   Hotkey "^c", CopyLink, "off"
   Hotkey "!e", ButtonSubmit, "off I2"
   Hotkey "!q", "off", "I2"
   Hotkey "LButton", ClickOff, "off I2"
   ;Hotkey "LButton", "off", "I2"
   Hotkey "tab", "off", "I2"
}

LocalHotkeysOn()
{
   Hotkey "RButton", "on"
   Hotkey "LButton", "on"
   Hotkey "!s", "on"
   Hotkey "!a", "on"
   Hotkey "!w", "on"
   Hotkey "!d", "on"
   Hotkey "^c", "on"
   Hotkey "!e", "on"
   Hotkey "!q", "on"
   Hotkey "tab", "on", "I2"
}

;;;;; INTIALIZE GUI

LoadGUI(*)
{ 
   DestroyGui(0)
   minMode := IniRead("HS_Settings.ini", "Settings", "MinMode")
   global currentGui := minMode = 1 ? "LiteGui" : "MainGui"
   LoadMenu()
   if (minMode == 1) { ; Activate minimal UI
      BuildLiteGUI()
   } else { ; Activate main UI
      BuildMainGUI()
   }
   %currentGui%.OnEvent("Close", destroyGui)
   %currentGui%.OnEvent("Escape", destroyGui)
}

BuildLiteGUI(*)
{
   Hotkey "LButton", "on"
   global LiteGui := Gui("-Caption +ToolWindow -SysMenu","HyperSearch Lite")
   SetTheme()
   global editBar := LiteGui.Add("Edit", "r1 vUsrIn x10 y10 w230 h30 background" controlColor " " guiFont)
   global submitButton := LiteGui.Add("Button", "Default x250 y10 w50 h20", "Submit")
   LiteGui.MenuBar := MainMenu
   submitButton.OnEvent("Click", ButtonSubmit)
   h:=40
   w:=310
   finalXY := SetMonitorBounds(h, w)
   LiteGui.Show("x" finalXY[1] " y" finalXY[2] " h" h " w" w)
}

BuildMainGUI(*)
{
   ; Initially Generated Using SmartGUI Creator 4.0
   global guiReload:=1
   LocalHotkeysOn()
   global lastIndex
   global lastLinkIndex
   global MainGui := Gui("-Caption +ToolWindow -SysMenu","HyperSearch")
   SetTheme()
   global editBar := MainGui.Add("Edit", "r1 vUsrIn x160 y10 w220 h30 Background" controlColor " " guiFont)
   global catListbox := MainGui.Add("ListBox", "vIndex x10 y10 w140 h315 0x100 VScroll sort -AltSubmit Background" controlColor " " guiFont)
   global linksListbox := MainGui.Add("ListBox", "vLink x160 y45 w280 h280 0x100 AltSubmit Background" controlColor " " guiFont)
   global submitButton := MainGui.Add("Button", "Default x390 y10 w50 h20 -Tabstop", "Submit")
   global urlTextGui := MainGui.Add("Text", "x10 y330 w430 -Wrap " urlTxtColor, urlDisplay)
   MainGui.MenuBar := MainMenu
   if (hsrDup==0)
      BuildHSRArray()
   submitButton.OnEvent("Click", ButtonSubmit)
   editBar.OnEvent("Change", InputAlgorithm)
   catListbox.OnEvent("Change", LoadLinks)
   linksListbox.OnEvent("Change", SetLinkHighlight)
   linksListbox.OnEvent("DoubleClick", ActivateLinks)
   h:=350
   w:=450
   finalXY := SetMonitorBounds(h, w)
   MainGui.Show("h" h " w" w " x" finalXY[1] " y" finalXY[2])
   ControlChooseIndex lastIndex, catListbox
   try linksListbox.Choose(lastLinkIndex)
   catch {
      sleep 50
      linksListbox.Choose(1)
   }
   SetLinkHighlight()
   guiReload:=0
}

BuildHSRArray(*)
{
   global HSR_Array:=[]
   indexList:=""
   global repo
   global hsrDup
   global sMode
   try {
      HSR_String := FileRead(repo)
   } catch {
      noRepo := InputBox('Repo file "' repo '" not found. Please provide a path to an existing repo, or enter the name for a new one.','Repository Not Found')
      if (noRepo.Result == "Cancel" || noRepo.Value=="") {
         MsgBox "Default repository will be used."
         if (sMode=="web") {
            if FileExist("HSR_Master.csv") {
               LoadRepo("HSR_Master.csv")
            } else
               GenerateHSR("HSR_Master.csv",1)
         } else if (sMode=="dir")
            if FileExist("HFR_Master.csv") {
               LoadRepo("HFR_Master.csv")
            } else
               GenerateHSR("HFR_Master.csv",2)
         hsrDup:=1
         LoadGUI()
         hsrDup:=0
      } else {
         if (noRepo.value~="i).*csv$")
            repo:=noRepo.value
         else
            repo:=noRepo.value ".csv"
         if FileExist(repo) {
            LoadRepo(repo)
         } else {
            MsgBox "No file found at:`n" repo "`n`nA new file will be created."
            kind := sMode="web" ? 1 : 2
            GenerateHSR(repo,kind)
            LoadRepo(repo)
         }
         DestroyGui(0)
         hsrDup:=1
         LoadGUI()
         hsrDup:=0
      }
      HSR_String := FileRead(repo)
   }
   Loop Parse HSR_String, "`n", "`r" ; Build HSR_Array
   {
      r:=A_Index ; Row number
      newRow := []
      Loop Parse A_LoopField, "CSV"
      {
         c:=A_Index ; Column number
         if (A_Index==1) ; Only search first column
         {
            chck:=A_LoopField . "|"
            dup := InStr(indexList,chck) ; Detect duplicates
            if (dup==0){
               indexList .= A_LoopField "|" ; Build index list for listbox
               catListbox.Add([A_LoopField])
            }
         }
         newRow.Push(A_LoopField)
      }
      HSR_Array.Push(newRow)
   }
}

;;;;; SEARCH FUNCTIONS

goSearch(searchQuery,override)
{
   ; Override code:
   ;   0 = pass based on search mode (sMode)
   ;   1 = always open in web
   ;   2 = always open as folder
   global sMode
   global linkArray
   if (sMode = "web" && override != 2 || override = 1) { ; Search web
      ;;;;;Adapted from this thread: https://www.autohotkey.com/board/topic/13404-google-search-on-highlighted-text/
      if (searchQuery != "" && searchQuery != " "){
         searchQuery := StrReplace(searchQuery, "`n`r", A_Space)
         searchQuery := Trim(searchQuery)
         searchQuery := StrReplace(searchQuery, "\", "`%5C")
         searchQuery := StrReplace(searchQuery, A_Space, "+")
         searchQuery := StrReplace(searchQuery, "`%", "`%25")
         If InStr(searchQuery, ".")
         {
            If InStr(searchQuery, "+")
               Run browser " " searchEngine searchQuery  
            else
               Run browser " " searchQuery 
         } else
            Run browser " " searchEngine searchQuery
         DestroyGui(0)
      }
   } else if (sMode = "dir" && override != 1 || override = 2) { ; Search files
      if (searchQuery != "" && searchQuery != " ") {
         searchQuery := RestoreLinks(searchQuery)
         if !FileExist(searchQuery) {
            searchQuery := FindDrive(subStr(searchQuery,4))
            if (searchQuery!=false) {
               contMsg := MsgBox("It looks like the file path has changed. Would you like to reassign the path?`n`nOld Path:`n" linkArray[linksListbox.value][2] "`n`nNew path:`n" searchQuery " ", "Reassign File Path?", 260)
               if (contMsg = "Yes"){
                  linkArray[linksListbox.value][2] := searchQuery
                  UpdateLinkList()
               }
            } else
               return
         }
         dirCheck := InStr(FileExist(searchQuery), "D")
         useDopus := FileExist("C:\Program Files\GPSoftware\Directory Opus\dopusrt.exe") && dirCheck != 0 ? 1 : 0
         if(useDopus=1) {
            Run 'C:\Program Files\GPSoftware\Directory Opus\dopusrt.exe /acmd Go "' searchQuery '" NEWTAB=findexisting OPENINDUAL'
            if WinExist("ahk_exe dopus.exe")
               WinActivate "ahk_exe dopus.exe"
         } else 
            Run '"' searchQuery '"'
         DestroyGui(0)
      }
   }
}

searchHighlight(ThisHotkey)
{ 
   BlockInput 1 
   prevClipboard := A_Clipboard
   A_Clipboard := "" 
   Send "^c" 
   BlockInput 0
   if !ClipWait(1) 
   { 
      MsgBox "Could not perform search."
      return
   }
   goSearch(A_Clipboard,1)
   A_Clipboard := prevClipboard
}

;;;;; GUI CONTROL FUNCTIONS

ButtonSubmit(*)
{
   lastSub := %currentGui%.Submit(0)
   global mouseKeep
   activeControl := %currentGui%.FocusedCtrl

   if (minMode == 0) {
      if (activeControl == linksListbox || activeControl == catListbox) {
         if (linkArray[linksListbox.value][2] == "*") {
            linkLabel:=linkArray[linksListbox.value][1]
            RegExMatch(linkLabel, "<(.*?)>", &match) ; Open category via crosslink
            try {
               ControlChooseString match[1], catListbox
               ;editBar.value:=""
               return
            } catch {
               MsgBox 'Category "' match[1] '" not found.'
               return
            }
         } else {
            goSearch(linkArray[linksListbox.value][2],0)
            return
         }
      } else if (activeControl == catListbox) {
         linksListbox.Focus()
      } else if (activeControl == editBar || activeControl == submitButton) {
         if (lastSub.UsrIn != ""){
            cleanIn := StrReplace(lastSub.UsrIn,"``+","><")
            if (cleanIn ~= "^ .*" || editBar.value ~= "^#.*") { ; Set focus to links listbox without opening link
               lastLinkIndex:=SubStr(editBar.value,2)
               linksListbox.focus()
               editBar.value:=""
               return
            } else if (cleanIn ~= "^\^[0-9]*") { ; Load current link into edit bar
               if (SubStr(cleanIn,2)!=""){
                  try {
                     loadPos:=Integer(SubStr(cleanIn,2))
                  } catch TypeError {
                     MsgBox "Please only enter number values."
                     return
                  }
                  if (loadPos>linkArray.length)
                     loadPos:=linkArray.length
                  editBar.value:=RestoreLinks(linkArray[loadPos][2])
               } else
                  editBar.value:=RestoreLinks(linkArray[linksListbox.value][2])
               Send "{End}"
               return
            } else if (cleanIn ~= "i)^import>.*") {
               if (cleanIn ~= "i).*html`"?$") {
                  ImportChrome()
               } else if (cleanIn ~= "i).*csv`"?$") {
                  ImportCSV()
               } else
                  MsgBox "Unsupported format."
               DestroyGui(0)
               LoadGui()
               return
            } else if (cleanIn ~= "i)^load>.*") {
               LoadRepo()
               DestroyGui(1)
               LoadGui()
               return
            } else if (cleanIn ~= "i)^new>.*") {
               NewRepo()
               DestroyGui(1)
               LoadGui()
               return
            } else if (cleanIn ~= "i)^export>cat.{0,5}>h.{0,4}s.{0,5}") {
               ShareCat()
               DestroyGui(0)
               Run A_WorkingDir
               return
            } else if (cleanIn ~= "i)^export>cat.{0,5}") {
               ExportCat()
               DestroyGui(0)
               Run A_WorkingDir
               return
            } else if (cleanIn ~= "i)^export>repo.{0,6}") {
               ExportRepo()
               DestroyGui(0)
               Run A_WorkingDir
               return
            } else if (cleanIn ~= ".*\+.*"){
               AppendLinks(cleanIn)
               LoadLinks("AppendLinks")
               editBar.Value := ""
               return
            } else if (cleanIn ~= "i)del.{0,3}\-[0-9|cat.{0,5}]*"){
               RemoveLinks()
               LoadLinks("RemoveLinks")
               editBar.Value := ""
               return
            } else if (cleanIn ~= "[1-9]*~[1-9]*" || cleanIn ~= "[1-9]*%[1-9]*"){
               ReorderLinks()
               LoadLinks("ReorderLinks")
               editBar.Value := ""
               return
            }
         } else if (lastSub.UsrIn == "") {
            if (linkArray[linksListbox.value][2] == "*") {
               linkLabel:=linkArray[linksListbox.value][1]
               RegExMatch(linkLabel, "<(.*?)>", &match)
               try {
                  ControlChooseString match[1], catListbox
               } catch {
                  MsgBox 'Category "' match[1] '" not found.'
                  return
               }
            } else {
               searchURL := linkArray[linksListbox.value][2]
               goSearch(searchURL,0)
            }
         }
      }
   }
   ; Commands that can be activated via Lite GUI as well as Main GUI
   if (RegExMatch(lastSub.UsrIn, "^[1-9]>.*")){
      mouseKeep:=1
      EditFav()
      DestroyGui(0)
      LoadGUI()
      mouseKeep:=0
   } else if (lastSub.UsrIn ~= "i)^set>.*"){
      mouseKeep:=1
      EditSettings()
      DestroyGui(0)
      LoadGUI()
      mouseKeep:=0
   } else {
      if (minMode == 1 && lastSub.UsrIn == "")
            return
      else {
         goSearch(lastSub.UsrIn,1)
      }
   }
}

InputAlgorithm(*)
{
   global lastLinkIndex
   global linkArray
   if (minMode == 0) {
      if(RegExMatch(editBar.value, "^ .+")) ; Search category list
      {
         try {
            ControlChooseString SubStr(editBar.value,2), catListbox
         } catch {
            sleep 50
         }
      } else if(RegExMatch(editBar.value, "^#.+")) ; Highlight for specified link position
         {
            try {
               if(RegExMatch(editBar.value, "^#v.*")) {
                  linksListbox.choose(linkArray.length)
                  lastLinkIndex:=linksListbox.value
               } else {
                  try {
                     usrIndex := Integer(SubStr(editBar.value,2))
                     if (usrIndex>linkArray.length)
                        usrIndex:=linkArray.length
                     linksListbox.choose(usrIndex)
                     lastLinkIndex:=linksListbox.value
                  } catch {
                     linksListbox.choose(SubStr(editBar.value,2))
                  }
               }
               SetLinkHighlight()
            } catch {
               sleep 50
            }
         }
   }
}

CopyLink(*)
{
   global linkArray
   currentControl := %currentGui%.FocusedCtrl
   if (currentControl!="Edit1") {
      activeLink:=linkArray[linksListbox.value][2]
      A_Clipboard := activeLink
   } else {
      hotkey "^c", "off"
      Send "^c"
      hotkey "^c", "on"
   }
   DestroyGui(0)
}

LoadLinks(prev*)
{
   lastSub := %currentGui%.Submit(0)
   linkCell:=""
   thisLink:=[]
   global linkArray := []
   linksListbox.Opt("-Redraw")
   linksListbox.Delete()
   global lastLinkIndex
   global guiReload
   global urlDisplay
   if (guiReload == 0 && prev[1]==catListbox)
      lastLinkIndex:=1
   Loop HSR_Array.Length
   {
      if (lastSub.index ==HSR_Array[A_Index][1]) {
         linkCell .= HSR_Array[A_Index][2]
         break
      }
   }
   if (linkCell == "")
      linkCell:="[]()"

   newPos:=1
   labelIndex:=1
   while (RegExMatch(linkCell, "\[(.*?)]", &currentLabel, newPos) != 0) {
      if (labelIndex<10) {
         linksListbox.Add(["0" . labelIndex . ".  " . currentLabel[1]])
      } else {
         linksListbox.Add([labelIndex . ".  " . currentLabel[1]])
      }   
      newPos+=2
      RegExMatch(linkCell, "\((.*?)\)", &currentLink, newPos)
      linkArray.Push([currentLabel[1],currentLink[1]])
      newPos := currentLink.Pos(1)
      labelIndex++
   }

   linksListbox.Opt("+Redraw")
   try {
      linksListbox.Choose(lastLinkIndex)
   } catch {
      linksListbox.Choose(1)
   }

   SetLinkHighlight()
}

ActivateLinks(*)
{
   if (linkArray[linksListbox.value][2] == "*") {
      linkLabel:=linkArray[linksListbox.value][1]
      RegExMatch(linkLabel, "<(.*?)>", &match)
      ControlChooseString match[1], catListbox
   } else {
      goSearch(linkArray[linksListbox.value][2],0)
   }
}

SetLinkHighlight(*)
{
   global sMode
   global urlDisplay
   global modeTxt
   try {
      urlDisplay := modeTxt . RestoreLinks(linkArray[linksListbox.value][2])
   } catch {
      urlDisplay := modeTxt
   }
   urlTextGui.value := urlDisplay
}

;;;;; CATEGORY & LINK MODIFICATION

AppendLinks(input*)
{
   lastSub := %currentGui%.Submit(0)
   global HSR_Array
   global linkString:=""
   global lastLinkIndex:=linksListbox.value
   ; Sample: 1Category+2LinkIndex+3LinkName+4URL
   linkTxt:=StrSplit(input[1],"+",,4)
   linkIndex:=linkTxt[2]
   if (linkTxt[1]!="") { ; Add new category
      Loop HSR_Array.Length
      {
         if (linkTxt[1]=HSR_Array[A_Index][1]) {
            MsgBox "Category already exists."
            return
         }
      }
      
      if (linkTxt.Has(2) && linkTxt.Has(3) && linkTxt[2] != "") { ; Add link in first position
         cleanLabel := CleanLabels(linkTxt[2])
         cleanLink := CleanLinks(linkTxt[3])
         appendTxt:= '`n"' . linkTxt[1] . '",' . '"[' . cleanLabel . "](" . cleanLink . ')"'
         FileAppend appendTxt, repo
         ;return
      } else if (linkTxt.Has(3) && linkTxt[2]="" && linkTxt[3]="") { ; Rename current category
         Loop HSR_Array.Length
         {
            if (lastSub.Index=HSR_Array[A_Index][1]) {
               HSR_Array[A_Index][1]:=linkTxt[1] ; Add cell text to array
               MsgBox "Category " . lastSub.Index . " has been renamed to " . linkTxt[1] . "."
               SaveHSR()
               break
            }
         }
      } else if (SubStr(input[1],-1) == "+") { ; Add category with blank first entry
         appendTxt:= '`n"' . linkTxt[1] . '",' . '"[ ]()"'
         FileAppend appendTxt, repo
      } else {
         return
      }
      global mouseKeep:=1
      newCat:=linkTxt[1]
      DestroyGui(0)
      BuildMainGUI()
      catListbox.Choose(newCat)
      linksListbox.Choose(1)
      mouseKeep:=0
      return
   } else if (linkIndex == "v") { ; Add link in last position
      cleanLabel := CleanLabels(linkTxt[3])
      cleanLink := CleanLinks(linkTxt[4])
      if (linkTxt.Has(4))
         linkArray.push([cleanLabel,cleanLink])
      else
         linkArray.push([cleanLabel,""])
      lastLinkIndex:=linkArray.length
   } else if IsNumber(linkIndex) ; Position specific Link
   {
      linkIndex := Integer(linkIndex)
      if (linkIndex>linkArray.length) {
         diff := linkIndex - linkArray.length
         i:=1
         while i< diff {
            linkArray.InsertAt(0,["",""])
            i++
         }
      }
      lastLinkIndex := linkIndex
      if (linkTxt[3] != "" && linkTxt.Has(4)) {
         cleanLabel := CleanLabels(linkTxt[3])
         cleanLink := CleanLinks(linkTxt[4])
         linkArray.InsertAt(linkIndex,[cleanLabel,cleanLink]) ; Insert at specified position
      } else if (linkTxt[3]=="") {
         cleanLink := CleanLinks(linkTxt[4])
         if (!linkTxt.Has(4)) {
            linkArray.InsertAt(linkIndex,[linkTxt[3],cleanLink]) 
         } else if (linkTxt[4]=="") {
            linkArray.InsertAt(linkindex,["",""])
         } else {
            linkArray[linkIndex][2]:=cleanLink ; Update URL at position
            MsgBox linkArray[linkIndex][1] . " now links to " . RestoreLinks(linkArray[linkIndex][2])
         }
      } else if (!linkTxt.Has(4)) {
         if (linkIndex>linkArray.length) {
            diff := linkIndex - linkArray.length
            i:=1
            while i<= diff {
               linkArray.InsertAt(0,["",""])
               i++
            }
         }
         lastLinkIndex := linkIndex
         oldLabel:=linkArray[linkIndex][1]
         cleanLabel := CleanLabels(linkTxt[3])
         linkArray[linkIndex][1]:=cleanLabel ; Update label at position
         MsgBox oldLabel . " is now labelled " . linkArray[linkIndex][1]
      }
   } else { ; Unspecified position number
      if (linkTxt[2] != "" && linkTxt.Has(3)) {
         cleanLabel := CleanLabels(linkTxt[2])
         cleanLink := CleanLinks(linkTxt[3])
         linkArray.InsertAt(1,[cleanLabel,cleanLink]) ; Insert in first position
         lastLinkIndex := 1
      } else if (linkTxt[2]=="") {
         linkArray[linksListbox.value][2]:=CleanLinks(linkTxt[3]) ; Update URL of current
         MsgBox linkArray[linksListbox.value][1] . " now links to " . RestoreLinks(linkTxt[3])
      } else if (!linkTxt.Has(3)) {
         oldLabel:=linkArray[linksListbox.value][1]
         cleanLabel := CleanLabels(linkTxt[2])
         linkArray[linksListbox.value][1]:=cleanLabel ; Update label of current
         MsgBox oldLabel . " is now labelled " . linkArray[linksListbox.value][1]
      }
   }
   UpdateLinkList()
}

RemoveLinks(*)
{
   %currentGui%.Submit(0)
   global linkArray
   removeTxt:=StrSplit(editBar.value,"-",,3)
   global linkString:=""
   global lastLinkIndex:=linksListbox.value
   removeTxtIndex:=removeTxt[2]
   ;Sample: 1DELETE-2LinkIndex
   if (removeTxt[2] ~= "i)cat.{0,5}") { ; remove cateogry
      delCat()
   } else if (removeTxt[2] != "" && removeTxt.length==3) { ; Remove list of links
      try {
         val1:=Integer(removeTxt[2])
         val2:=Integer(removeTxt[3])
      } catch TypeError {
         MsgBox "Please only enter number values."
         return
      }
      start:=min(val1,val2)
      stop:=max(val1,val2)
      if (stop>linkArray.length)
         stop:=linkArray.length
      lastLinkIndex:=start
      numRemove := stop-start + 1
      i:=start
      chckList := ""
      while i <= stop
      {
         if (A_Index<=10) {
            chckList .= linkArray[i][1] . "`n"
            i++
         } else {
            if (A_Index>10) {
               andMore:=numRemove-10
               chckList .= "and " . andMore . " others"
               break
            }
         }
      }
      
      contMsg := MsgBox("Do you want to remove the links`n" . RTrim(chckList,"`n") . "?", "Continue?",260)
      If (contMsg = "No")
         Return
      If (contMsg = "Yes")
      {
         Loop numRemove
         {
            linkArray.RemoveAt(start)
         }
      }
   } else if (removeTxt[2] == "") { ; Remove current link
      contMsg := MsgBox("Do you want to remove the link " . Trim(linkArray[linksListbox.value][1]) . "?", "Continue?",260)
      If (contMsg = "No")
         Return
      If (contMsg = "Yes")
      {
         linkArray.RemoveAt(linksListbox.value)
      }
   } else { ; Remove specified link
      contMsg := MsgBox("Do you want to remove the link " . Trim(linkArray[removeTxt[2]][1]) . "?","Continue?",260)
      If (contMsg = "No")
         Return
      If (contMsg = "Yes")
      {
         lastLinkIndex:=removeTxt[2]
         linkArray.RemoveAt(removeTxt[2])
      }
   }

   UpdateLinkList()
}

DelLink(*)
{
   global linkArray
   global linkString:=""
   linksListbox.Opt("-redraw")
   contMsg := MsgBox("Do you want to remove the link " . Trim(linkArray[linksListbox.value][1]) . "?", "Continue?", 260)
   If (contMsg = "no")
      Return
   If (contMsg = "Yes")
      linkArray.RemoveAt(linksListbox.value)
   UpdateLinkList()
   LoadLinks("DelLink")
   linksListbox.Opt("+redraw")
   editBar.value := ""
}

DelCat(*)
{
   lastSub := %currentGui%.Submit(0)
   global linkArray
   global HSR_Array
   global mouseKeep
   contMsg := MsgBox("Do you want to delete all of the data in " lastSub.index "?", "Continue?", 260)
   If (contMsg = "No")
      return
   If (contMsg = "Yes")
   {
      Loop HSR_Array.Length
      {
         if (lastSub.Index=HSR_Array[A_Index][1]) {
            HSR_Array.RemoveAt(A_Index)
            linkArray:=[]
            linkString:=""
            break
         }
      }
      mouseKeep:=1
      linksListbox.Opt("-redraw")
      UpdateLinkList()
      DestroyGui(0)
      global lastIndex-=1
      LoadGUI()
      linksListbox.Opt("+redraw")
      mouseKeep:=0
   }
   editBar.Value := ""
}

ReorderLinks(*)
{
   global linkArray
   global lastLinkIndex
   if (instr(editBar.value, "~"))
      swapTxt:=StrSplit(editBar.value,"~",,2)
   else if (instr(editBar.value, "%"))
      swapTxt:=StrSplit(editBar.value,"`%",,2)
   try {
      swapTxt2 := Integer(swapTxt[2])
      lastLinkIndex:=swapTxt2
   } catch TypeError {
      MsgBox "Please ony use number values."
      return
   }
   global linkString:=""
   swap:=[]
   if (instr(swapTxt[1],"-")) { ; Reorder multiple links
      swapVal:=StrSplit(swapTxt[1],"-",,2)
      try {
         swapVal1 := Integer(swapVal[1])
         swapVal2 := Integer(swapVal[2])
      } catch TypeError {
         MsgBox "Please ony use number values."
         return
      }
      frst:=min(swapVal1,swapVal2)
      lst:=max(swapVal1,swapVal2)
      amt:=lst-frst+1
      i:=1
      while i<=amt
      {
         swapPos:=(frst-1)+i
         swap.InsertAt(1,linkArray[swapPos])
         i++
      }
      linkArray.RemoveAt(frst,amt)
      Loop swap.Length
      {
         try {
            linkArray.InsertAt(swapTxt2,[swap[A_Index][1],swap[A_Index][2]])
         } catch ValueError {
            diff := swapTxt2 - linkArray.length
            i:=1
            while i< diff {
               linkArray.InsertAt(0,["",""])
               i++
            }
            linkArray.InsertAt(0,[swap[A_Index][1],swap[A_Index][2]])
         }   
      }
   } else { ; Reorder single link
      try {
         swapTxt1 := Integer(swapTxt[1])
      } catch TypeError {
         MsgBox "Please ony use number values."
         return
      }
      swap:=linkArray[swapTxt1]
      linkArray.RemoveAt(swapTxt1)
      try {
         linkArray.InsertAt(swapTxt2,[swap[1],swap[2]])
      } catch ValueError {
         diff := swapTxt2 - linkArray.length
         i:=1
         while i< diff {
            linkArray.InsertAt(0,["",""])
            i++
         }
         linkArray.InsertAt(0,[swap[1],swap[2]])
      }
   }
   UpdateLinkList()
}

UpdateLinkList(*)
{
   global linkArray
   global HSR_Array
   global linkString
   lastSub := %currentGui%.Submit(0)
   Loop linkArray.Length
   {
      linkString .= "[" . linkArray[A_Index][1] . "](" . linkArray[A_Index][2] . ")"
   }
   
   Loop HSR_Array.Length
   {
      if (lastSub.index==HSR_Array[A_Index][1]) {
         HSR_Array[A_Index][2]:=linkString
         break
      }
   }

   SaveHSR()
}

SaveHSR(*)
{
   HSR_String:=""
   Loop HSR_Array.Length   ; Concat string array
   {
      r:=A_Index
      Loop HSR_Array[A_Index].Length
      {
         HSR_String .= A_Index == HSR_Array[r].Length ? '"' . HSR_Array[r][A_Index] . '"' : '"' . HSR_Array[r][A_Index] . '",'
      }
      if (A_Index!=HSR_Array.Length)
         HSR_String .= "`n"
   }
   FileDelete repo
   FileAppend HSR_String, repo
}

;;;;; REPO & CATEGORY IMPORT & EXPORT

ExportCat(*)
{
   addLink := ""
   Loop linkArray.Length {
      if (linkArray[A_Index][1] != "" && linkArray[A_Index][1] != " ")
         addLink .= linkArray[A_Index][1] . "," . linkArray[A_Index][2] . "`n"
      else
         addLink .= "`n"
   }
   newFile := Trim(HSR_Array[catListbox.value][1]) . "_" . todayQuick . ".csv"
   If FileExist(newFile) {
      FileDelete newFile
   }
   FileAppend addLink, newFile
}

ShareCat(*)
{
   shareCell := ""
   global HSR_Array
   Loop HSR_Array.Length
   {
      if (catListbox.value==A_Index) {
         shareCell .= HSR_Array[A_Index][2]
         break
      }
   }
   shareLinks := HSR_Array[catListbox.value][1] . "," . shareCell
   newShareFile := Trim(HSR_Array[catListbox.value][1]) . ".csv"
   If FileExist(newShareFile) {
      FileDelete newShareFile
   }
   FileAppend shareLinks, newShareFile
}

ExportRepo(*)
{
   %currentGui%.Submit(0)
   exportCell:=""
   repoTrim := SubStr(repo,1,-4)
   exportFile := repoTrim . "_Export_" . todayQuick . ".csv"
   If FileExist(exportFile) {
      FileDelete exportFile
   }
   Loop HSR_Array.Length
   {
      exportArray := []
      exportCell := HSR_Array[A_Index][2]
      exportCat := HSR_Array[A_Index][1]
      exportCat := Trim(exportCat)
      exportCat := StrReplace(exportCat, ",", "")
      newPos:=1
      labelExportIndex:=1
      while (RegExMatch(exportCell, "\[(.*?)]", &currentExportLabel, StartingPos := newPos) != 0) {
         newPos+=2
         RegExMatch(exportCell, "\((.*?)\)", &currentExportLink, StartingPos := newPos)
         if (currentExportLink[1] != "*" && currentExportLink[1] != "" && currentExportLink[1] != " ") {
            expLink := currentExportLink[1]
            expLabel := currentExportLabel[1]
            expLabel := Trim(expLabel)
            expLink := Trim(expLink)
            expLabel := StrReplace(expLabel, ",", A_Space)
            expLink := StrReplace(expLink, ",", A_Space)
            exportArray.Push([expLabel,expLink])
         }
         newPos := currentExportLink.Pos(1)
         labelExportIndex++
      }
      Loop exportArray.Length {
         if (exportArray[A_Index][1] != "" && exportArray[A_Index][1] != " ")
            exportLinks .= exportCat . "," . exportArray[A_Index][1] . "," . exportArray[A_Index][2] . "`n"
      }
   }
   FileAppend exportLinks, exportFile
}

ImportChrome(*)
{
   replace:=0
   otherChk:=0
   search:=StrSplit(editBar.value,">",,2)
   bkmkLines:=[]
   global HSR_Array
   bkmkPath:=Trim(search[2], '"')
   if !FileExist(bkmkPath) {
      Msgbox "File could not be read."
      return
   }
   bkmk := FileRead(bkmkPath)
   importMsg := MsgBox("Import options, How would you like to import?`nYes: Append to current links`nNo: Replace all links with bookmarks",,3)
   If (importMsg = "No")
      replace:=1
   If (importMsg = "Cancel")
      return
   Loop Parse, bkmk, "`n", "`r" ; Build HSR_Array
   {
      bkmkLines.push(A_LoopField)
   }
   fullArray := []
   catRow := []
   catIndex:=1

   Loop bkmkLines.Length
   {
      numTabs:=0
      charPos:=6
      currentLine:=bkmkLines[A_Index]
      Loop Parse, currentLine
      {
         if (A_LoopField == A_Space) {
               numTabs++
               charPos++
         } else 
               break
      }
      head:=SubStr(currentLine,charPos,2)
      numTabs := round(numTabs/4)

      if (head == "H3") { ; New category
         RegExMatch(currentLine, "<H3 .*>(.*?)</H3>", &catScan)
         thisCat:=catScan[1]
         if (thisCat = "Bookmarks bar") {
            thisCat :=  " Bookmarks bar"
         } else if (thisCat = "Bookmarks Toolbar")
            thisCat := " Bookmarks Toolbar"
         Loop HSR_Array.Length
         {
            if (replace = 0 && thisCat == HSR_Array[A_Index][1]) {
               ogCat := thisCat
               thisCat.="_1"
            }
         }
         fullArray.InsertAt(catIndex,[thisCat])
         nxtTab:=numTabs+1
         i:=A_Index+2
         subTabs:=numTabs+1
         while  subTabs > numTabs
         {
               subLine:=bkmkLines[i]
               subTabs:=0
               subCharPos:=6
               Loop Parse, subLine
               {
                  if (A_LoopField == A_Space) {
                     subTabs++
                     subCharPos++
                  } else 
                     break
               }
               subTabs := round(subTabs/4)
               subHead:=SubStr(subLine,subCharPos,2)
               if (subTabs == nxtTab) {
                  if (subHead=="H3") {
                     RegExMatch(subLine, "<H3 .*>(.*?)</H3>", &subCat)
                     fullArray[catIndex].push("[<" . subCat[1] . ">](*)")
                  } else if (subHead == "A ") {
                     RegExMatch(subLine, '<A HREF="(.*?)"', &subLink)
                     RegExMatch(subLine, "<A .*>(.*?)</A>", &subLabel)
                     if (subLabel[1] != "") {
                        labelReplace := CleanLabels(subLabel[1])
                     } else {
                        labelReplace := subLink[1]
                     }
                     checkLink:=subLink[1]
                     if (RegExMatch(checkLink, "javascript.*") != 0) {
                        checkLink := " "
                     }

                     fullArray[catIndex].Push("[" . labelReplace . "](" . checkLink . ")")
                  }
               }
               i++                                        
         }
         catIndex++
      } else if (head == "A " && numTabs == 1) {
         if (otherChk=0) {
            fullArray.Push([" Other bookmarks",""])
            otherChk:=1
            otherCat:=catIndex
         }
         RegExMatch(currentLine, '<A HREF="(.*?)"', &subLink)
         RegExMatch(currentLine, "<A .*>(.*?)</A>", &subLabel)
         if (subLabel[1] != "") {
            labelReplace := CleanLabels(subLabel[1])
         } else {
            labelReplace := subLink[1]
         }
         checkLink:=subLink[1]
         if (RegExMatch(checkLink, "javascript.*") != 0) {
            checkLink := " "
         }

         fullArray[otherCat][2] .= "[" . labelReplace . "](" . checkLink . ")"
         nxtTab:=1
         i:=A_Index+1
         subTabs:=numTabs+1
         while  subTabs > numTabs
         {
            subLine:=bkmkLines[i]
            subTabs:=0
            subCharPos:=6
            Loop Parse, subLine
            {
               if (A_LoopField == A_Space) {
                  subTabs++
                  subCharPos++
               } else 
                  break
            }
            subTabs := round(subTabs/4)
            subHead:=SubStr(subLine,subCharPos,2)
            if (subTabs == nxtTab) {
               if (subHead=="H3") {
                  RegExMatch(subLine, "<H3 .*>(.*?)</H3>", &subCat)
                  fullArray[otherCat][2] .= "[<" . subCat[1] . ">](*)"
               }
            }
            i++
         }
         catIndex++
      }
      
   }

   if (replace==1)
      HSR_ImportString:=""
   else
      HSR_ImportString:="`n"
   
   Loop fullArray.Length   ; concat string array
   {
      r:=A_Index
      Loop fullArray[A_Index].Length
      {
         if (A_Index ==1) {
            HSR_ImportString .= fullArray[r][A_Index] ","
         } else {
            HSR_ImportString .= fullArray[r][A_Index]
         }
      }
      if (A_Index!=fullArray.Length)
         HSR_ImportString .= "`n"
   }
   if (replace==1)
      FileDelete repo
   FileAppend HSR_ImportString, repo
   HSRImportString:=""
   bkmk:=""
   bkmkLines:=[]
   fullArray := []
}

ImportCSV(*)
{
   global repo
   newCSVLines:=[]
   replace:=0
   search:=StrSplit(editBar.value,">",,2)
   newCSVPath:=Trim(search[2],'"')
   if (newCSVPath~="i).*csv$"==0)
      newCSVPath.=".csv"

   if FileExist(newCSVPath) {
      newCSV := FileRead(newCSVPath)
      newCSV:="`n" . newCSV
      FileAppend newCSV, repo
   } else {
      MsgBox "Specified file could not be found.`n" newCSVPath
   }
}

LoadRepo(path*)
{
   global repo
   global sMode
   if (path.Has(1)) {
      repoIn:=path[1]
   } else {
      search:=StrSplit(editBar.value,">",,2)
      repoIn:=Trim(search[2], '"')
      if (repoIn~="i).*csv$"==0)
         repoIn.= ".csv"
   }

   if FileExist(repoIn) {
      Loop Files, repoIn {
         global repoName:=A_LoopFileName
         repo:=A_LoopFilePath
      }
      if (sMode=="web")
         IniWrite repo, "HS_Settings.ini", "Settings", "Repository"
      else if (sMode=="dir")
         IniWrite repo, "HS_Settings.ini", "Settings", "DirRepo"
   } else {
      MsgBox "Specified file could not be found.`n" repoIn
   }
}

NewRepo(*)
{
   global repo
   global sMode
   search:=StrSplit(editBar.value,">",,2)
   if(search[2]=="") {
      newRepo:="HSR_Master.csv"
   } else if (search[2]~="i).*csv$") {
      newRepo:=search[2]
   } else {
      newRepo:=search[2] ".csv"
   }

   if FileExist(newRepo) {
      MsgBox newRepo " already exists. The file will be loaded."
      LoadRepo(newRepo)
      return
   }

   if (sMode == "web")
      GenerateHSR(newRepo,1)
   else if (sMode == "dir")
      GenerateHSR(newRepo,2)

   LoadRepo(newRepo)
}

;;;;; FAVORITES BAR

LoadMenu(*)
{
   global MainMenu := MenuBar()
   global ExitMenu := Menu()
   global HelpMenu := Menu()
   global repoName
   global minMode
   global sMode
   i:=1
   favMax := minMode = 1 ? 5 : 9
   while i <= favMax {
      favKey := "Favorite" i
      currentFav := IniRead("HS_Settings.ini", "Favorite Labels", favKey)
      if (currentFav != "")
         MainMenu.Add(currentFav, FavButton)
      i++
   }
   ExitMenu.Add("Close Window", DestroyGui)
   ExitMenu.Add("Exit App", ExitAppFunc)
   HelpMenu.Add("Support and updates", helpLinks)
   HelpMenu.Add(repoName, helpLinks)
   HelpMenu.Add("v" version,helpLinks)
   if (minMode == 0)
      MainMenu.Add("&!", SwapMode, "+right")
   MainMenu.Add("&?", HelpMenu, "+right")
   MainMenu.Add("&X", ExitMenu, "+right")
}

FavButton(favName, favPos, FavMenu)
{
   URL := IniRead("HS_Settings.ini", "Favorite Links", "FavLink" favPos, A_Space)
   if(URL == "")
      MsgBox "Favorite " . favPos . " is undefined."
   else {
      goSearch(URL,1)
      DestroyGui(0)
   }
}

EditFav(*)
{
   MainMenu.Delete()
   try {
      indx:=Integer(SubStr(editBar.value,1,1))
   } catch {
      MsgBox "Invalid index."
   }
   val := StrSplit(editBar.value,">",,3)
   if (val.Has(3))
      newLnk := val[3]
   else
      newLnk:=""
   if (val[2] != "" || newLnk != "") {
      newLbl := "&" . indx . " " . val[2]
      if (val[2] != ""){
         if (newLnk = "")
            MsgBox "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&" . indx . " ") . ".", "Favorite Reassigned"
         else
            MsgBox "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&" . indx . " ") . " and links to " . newLnk . ".", "Favorite Reassigned"
      } else
         MsgBox "Favorite " . indx . " now links to " . newLnk . ".","Favorite Reassigned"
   } else {
      newLbl:=""
      MsgBox "Favorite " . indx . " has been removed.","Favorite Erased"
   }
   if (val[2] = "" && newLnk = "" || val[2] != "")
      IniWrite newLbl, "HS_Settings.ini", "Favorite Labels", "Favorite" indx
   if (val[2] = "" && newLnk = "" || newLnk != "")
      IniWrite newLnk, "HS_Settings.ini", "Favorite Links", "FavLink" indx
   DestroyGui(0)
}

helpLinks(choice*)
{
   if (choice[1]="Support and updates")
      goSearch("https://github.com/JSSatchell/HyperSearch",1)
   else if (choice[1]=repoName) {
      if (repo!=repoName)
         repoPath := RTrim(repo,repoName)
      else
         repoPath := A_WorkingDir
      goSearch(repoPath,2)
   } else if (choice[1]="v" version)
      goSearch(A_WorkingDir,2)
   DestroyGui(0)
}

;;;;; MODIFY SETTINGS

EditSettings(*)
{
   global minMode
   search:=StrSplit(editBar.value,">",,3)
   if (search[2] ~= "i)d.{0,1}rk") {
      IniWrite 1, "HS_Settings.ini", "Settings", "DkMd"
   } else if (search[2] ~= "i)light") {
      IniWrite 0, "HS_Settings.ini", "Settings", "DkMd"
   } else if (search[2] ~= "i)min") {
      IniWrite 1, "HS_Settings.ini", "Settings", "MinMode"
      minMode := 1
   } else if (search[2] ~= "i)max") {
      IniWrite 0, "HS_Settings.ini", "Settings", "MinMode"
      minMode := 0
   } else if (search[2] ~= "i)j.mp") {
      if (search[3]~="i)on") {
         IniWrite "1", "HS_Settings.ini", "Settings", "jump"
         global jump := IniRead("HS_Settings.ini", "Settings", "jump")
      } else if (search[3]~="i)off") {
         IniWrite "0", "HS_Settings.ini", "Settings", "jump"
         jump := IniRead("HS_Settings.ini", "Settings", "jump")
      }
   } else if (search[2] ~= "i)s.{0,2}rch") {
      if (search[3] ~= "i)D.{0,4}D.{0,4}G.{0,1}") {
         DDG := IniRead("HS_Settings.ini", "Search Engine", "DuckDuckGo")
         global searchEngine:='"' . DDG . '"'
         IniWrite searchEngine, "HS_Settings.ini", "Search Engine", "Default"
         MsgBox "Your default search engine is now set to Duck Duck Go."
      } else if (search[3] ~= "i)G.{0,2}gl.{0,1}") {
         Google := IniRead("HS_Settings.ini", "Search Engine", "Google")
         searchEngine:='"' . Google . '"'
         IniWrite searchEngine, "HS_Settings.ini", "Search Engine", "Default"
         MsgBox "Your default search engine is now set to Google."
      } else if (search[3] ~= "i)B.{0,1}ng") {
         Bing := IniRead("HS_Settings.ini", "Search Engine", "Bing")
         searchEngine:='"' . Bing . '"'
         IniWrite searchEngine, "HS_Settings.ini", "Search Engine", "Default"
         MsgBox "Your default search engine is now set to Bing."
      } else
         MsgBox "Invalid search engine. Available options:`n-Google`n-Duck Duck Go`n-Bing"
   } else if (search[2] ~= "i)h.{0,2}k.{0,2}1") {
      global GUIHotkey
      failsafe:=GUIHotkey
      newHotkey1 := translateHotkey(search[3])
      IniWrite newHotkey1, "HS_Settings.ini", "Settings", "GUIHotkey"
      Hotkey GUIHotkey, "off"
      GUIHotkey:=newHotkey1
      try {
         Hotkey GUIHotkey, LoadGUI
      } catch TargetError {
         MsgBox "Invalid Hotkey"
         IniWrite failsafe, "HS_Settings.ini", "Settings", "GUIHotkey"
         GUIHotkey:=failsafe
         Hotkey GUIHotkey, searchHighlight
      }
      Hotkey GUIHotkey, "on"
      MsgBox "Hotkey 1 has been set to " . GUIHotkey
   } else if (search[2] ~= "i)h.{0,2}k.{0,2}2") {
      global hiHotkey
      failsafe:=hiHotkey
      newHotkey2:=translateHotkey(search[3])
      IniWrite newHotkey2, "HS_Settings.ini", "Settings", "HighlightHotkey"
      Hotkey hiHotkey, "off"
      hiHotkey:=newHotkey2
      try {
         Hotkey hiHotkey, searchHighlight
      } catch TargetError {
         MsgBox "Invalid Hotkey"
         IniWrite failsafe, "HS_Settings.ini", "Settings", "HighlightHotkey"
         hiHotkey:=failsafe
         Hotkey hiHotkey, searchHighlight
      }
      Hotkey hiHotkey, "on"
      MsgBox "Hotkey 2 has been set to " . hiHotkey
   } else if (search[2] ~= "i)op.{0,5}") {
      opVal := search[3]
      try
      {
         opVal := Integer(opVal)
         opPercent := Round((opVal / 100) * 255)
         IniWrite opPercent, "HS_Settings.ini", "Settings", "Opacity"
      } catch TypeError {
         MsgBox "Value should be a number."
         return
      }
   } else {
      MsgBox "Invalid settings option."
   }
}

SetTheme(*)
{
   themeSel := IniRead("HS_Settings.ini", "Settings", "DkMd")
   opSel := IniRead("HS_Settings.ini", "Settings", "Opacity")
   if (themeSel == 1) {
      global guiFont := "cWhite"
      %currentGui%.BackColor := ("c404040")
      global controlColor := "1A1A1A"
      MainMenu.SetColor("c808080")
      global urlTxtColor := "cSilver"
   } else {
      global guiFont := "cBlack"
      %currentGui%.BackColor := ("Silver")
      global controlColor := "White"
      MainMenu.SetColor("White")
      global urlTxtColor := "c595959"
   }
   %currentGui%.Opt("+LastFound")
   WinSetTransparent opSel
}

SwapMode(*)
{
   global sMode
   if (sMode=="dir")
      IniWrite "web", "HS_Settings.ini", "Settings","SearchMode"
   else if (sMode == "web")
      IniWrite "dir", "HS_Settings.ini", "Settings","SearchMode"

   global sMode := IniRead("HS_Settings.ini", "Settings", "SearchMode")
   global modeTxt := sMode = "web" ? "Web Mode: " : "File Mode: "
   global repo := sMode = "web" ? IniRead("HS_Settings.ini", "Settings", "Repository") : IniRead("HS_Settings.ini", "Settings", "DirRepo")
   LoadRepo(repo)
   global mouseKeep := 1
   DestroyGui(1)
   LoadGUI()
   mouseKeep := 0
}

;;;;; MOUSE HOTKEYS

ClickOff(ThisHotkey)
{
   ;;;;;;;; WHY DO SOME DIALOGS NOT ACCEPT CLICKING AND SOME DO ?!?!?!?!

   hsID := WinExist("HyperSearch")
   contID := WinExist("Continue?")
   reassignID := WinExist("Reassign File Path?")
   MouseGetPos ,,&winClick
   if (winClick!=hsID && winClick!=contID && winClick!=reassignID && winClick != A_ScriptName) {
      DestroyGui(0)
   }
   Click "Down"
   Keywait A_ThisHotkey
   Click "Up"
   ;ToolTip WinGetPID(winClick) " - " WinGetID(winClick) "`n" WinGetPID(A_ScriptHwnd) " - " WinGetID(A_ScriptHwnd)
   ;SetTimer () => ToolTip(), -5000

   ;if (WinGetPID(winClick)!=WinGetPID(A_ScriptHwnd))
   ;   DestroyGui(0)
}

RMenu(ThisHotkey)
{
   MouseGetPos ,,,&currentControl
   RCLB2 := Menu()
   RCLB2.Add "Copy Link", CopyLink
   RCLB2.Add "Delete", DelLink
   RCLB1 := Menu()
   RCLB1.Add "Delete", DelCat
   if (currentControl=="ListBox2"){
      Click
      RCLB2.Show()
   } else if (currentControl=="ListBox1") {
      Click
      RCLB1.Show()
   } else
      Click "Right"
}

;;;;; INITIALIZE & MAINTAIN SUPPORT FILES

CheckSettings(*)
{
   global version
   newSettings:=""
   sections := IniRead("HS_Settings.ini")
   sectionsArray:=StrSplit(sections,"`n")
   firstSection:=sectionsArray[1]
   lastSection:=sectionsArray[sectionsArray.Length]
   if (lastSection == "Theme") {
      themeContent := IniRead(themeContent, "HS_Settings.ini", "Theme")
      themeContent := "[Settings]`n" . themeContent
      IniDelete("HS_Settings.ini", "Theme")
      FileAppend(themeContent, "HS_Settings.ini")
   }
   settingsContent := IniRead("HS_Settings.ini", "Settings")
   settingsArray:=StrSplit(settingsContent,"`n")
   lastSetting:=settingsArray[settingsArray.Length]
   lastSettingArray:=StrSplit(lastSetting,"=")
   if (lastSettingArray[1]=="MinMode") {
      newSettings:="`nGUIHotkey=#Space`nHighlightHotkey=^#Space`nJump=1"
   } else if (lastSettingArray[1]=="HighlightHotkey") {
      newSettings:="`nJump=1"
   } else if (lastSettingArray[1]=="Jump") {
      newSettings:="`nRepository=HSR_Master.csv"
   }
   if (newSettings!="")
      FileAppend newSettings, "HS_Settings.ini"
   if (sectionsArray[1]!="Version") {
      oldOpVal := IniRead("HS_Settings.ini", "Settings", "Trans")
      IniDelete("HS_Settings.ini", "Settings", "Trans")
      FileAppend("Opacity=" oldOpVal, "HS_Settings.ini")
      oldIni := FileRead("HS_Settings.ini")
      newIni:="[Version]`nCurrentVersion=0.2.2`n`n" oldIni
      FileDelete("HS_Settings.ini")
      FileAppend(newIni,"HS_Settings.ini")
   }
   
   prevVer := IniRead("HS_Settings.ini", "Version", "CurrentVersion")

   if (prevVer == "0.2.2") {
      FileAppend("`nDirRepo=HFR_Master.csv`nSearchMode=web","HS_Settings.ini")
   }

   IniWrite(version, "HS_Settings.ini","Version","CurrentVersion")
}

GenerateSettings(*)
{
   global version
   FileAppend "[Version]`nCurrentVersion=" version "`n`n", "HS_Settings.ini"

   FileAppend "
   (
[Search Engine]
Default="https://duckduckgo.com/?q="
DuckDuckGo="https://duckduckgo.com/?q="
Google="http://www.google.com/search?hl=en&q="
Bing="https://www.bing.com/search?q="

[Favorite Labels]
Favorite1=Fav &1
Favorite2=Fav &2
Favorite3=Fav &3
Favorite4=Fav &4
Favorite5=Fav &5
Favorite6=
Favorite7=
Favorite8=
Favorite9=

[Favorite Links]
FavLink1=
FavLink2=
FavLink3=
FavLink4=
FavLink5=
FavLink6=
FavLink7=
FavLink8=
FavLink9=

[Settings]
DkMd=1
Opacity=230
MinMode=0
GUIHotkey=#Space
HighlightHotkey=^#Space
Jump=1
Repository=HSR_Master.csv
DirRepo=HFR_Master.csv
SearchMode=web
   )", "HS_Settings.ini"
}

GenerateHSR(hsrFile,kind)
{
   global repo
   repo:=hsrFile
   if (kind==1) {
      FileAppend
      (
'" Quick Access","[<Quick Start Guide>](*)"
"Quick Start Guide","[Use the `'!`' in the upper right to switch to file mode]()[]()[NAVIGATION REFERENCE](https://github.com/JSSatchell/HyperSearch#navigation)[Press Space to search the category index on the left]()[Tab between control windows]()[Press Enter after typing Space to set focus to links]()[Use Enter or double click links to activate URL]()[ ]()[TEXT ENTRY REFERENCE](https://github.com/JSSatchell/HyperSearch#adding--removing-categories--links)[Edit Favorites - `'Favorite#>Label>URL`'](https://github.com/JSSatchell/HyperSearch#update-favorites)[Add Index Category - `'Category Name+`']()[Add link - `'+Link Name+Link URL`']()[Add at Position - `'+Position#+Link Name+LinkURL`']()[Remove Selected Link - `'Delete-`']()[Remove at Position - `'Delete-Position#`']()[Delete Category - `'Delete-Category`']()[ ]()[SETTINGS](https://github.com/JSSatchell/HyperSearch#update-the-settings)[Min/Max Mode - `'Set>Min/Max`']()[Dark/Light Mode - `'Set>Dark/Light`']()[Transparency - `'Set>Opacity>Percentage`']()[]()[CLICK HERE for full feature list & updates](https://github.com/JSSatchell/HyperSearch)"'
      ), repo
      IniWrite repo, "HS_Settings.ini", "Settings", "Repository"
   } else if (kind==2){
      RegExMatch(A_Desktop, ".:\\Users\\(.+)\\Desktop", &usr)
      noOD := usr[1]
      if (usr[1] ~= ".+\\OneDrive")
         noOD := SubStr(usr[1],1,(StrLen(usr[1])-9))
      FileAppend
      (
'" Quick Access","[Desktop](' CleanLinks(A_Desktop) ')[My Documents](' CleanLinks(A_MyDocuments) ')[Downloads](C:\Users\' CleanLinks(noOD) '\Downloads)[Pictures](C:\Users\' CleanLinks(usr[1]) '\Pictures)[]()[HyperSearch Folder](' CleanLinks(A_WorkingDir) ')[   Open Repository](' CleanLinks(repo) ')[]()[<Quick Start Guide>](*)"
"Quick Start Guide","[Use the `'!`' in the upper right to switch to web mode]()[]()[NAVIGATION REFERENCE]()[Press Space to search the category index on the left]()[Tab between control windows]()[Press Enter after typing Space to set focus to links]()[Use Enter or double click labels to activate path]()[ ]()[TEXT ENTRY REFERENCE]()[Edit Favorites - `'Favorite#>Label>URL`']()[Add Index Category - `'Category Name+`']()[Add file/folder - `'+File/folder Name+Path`']()[Add at Position - `'+Position#+File/Folder Name+Path`']()[Remove Selected File/Folder Reference - `'Delete-`']()[Remove at Position - `'Delete-Position#`']()[Delete Category - `'Delete-Category`']()[ ]()[SETTINGS]()[Min/Max Mode - `'Set>Min/Max`']()[Dark/Light Mode - `'Set>Dark/Light`']()[Transparency - `'Set>Opacity>Percentage`']()"'
      ), repo
      IniWrite repo, "HS_Settings.ini", "Settings", "DirRepo"
   }
}

;;;;; UTILITY

translateHotkey(usrHotkey)
{
   ahkKey := StrReplace(usrHotkey, "win", "#")
   ahkKey := StrReplace(ahkKey, "ctrl", "^")
   ahkKey := StrReplace(ahkKey, "alt", "!")
   ahkKey := StrReplace(ahkKey, "+", "")
   ahkKey := StrReplace(ahkKey, "=", "+")
   ahkKey := StrReplace(ahkKey, "shift", "+")
   Return  ahkKey
}

CleanLabels(uncleanLabel)
{
   labelReplace := StrReplace(uncleanLabel, ")", "}")
   labelReplace := StrReplace(labelReplace, "(", "{")
   labelReplace := StrReplace(labelReplace, "[", "{")
   labelReplace := StrReplace(labelReplace, "]", "}")
   labelReplace := StrReplace(labelReplace, "`%5C", "\")
   labelReplace := StrReplace(labelReplace, "+", A_Space)
   labelReplace := StrReplace(labelReplace, "`%25", "`%")
   labelReplace := StrReplace(labelReplace, "&amp;", "&")
   labelReplace := StrReplace(labelReplace, "&gt;", ">")
   labelReplace := StrReplace(labelReplace, "&#39;", "``")
   labelReplace := StrReplace(labelReplace, "&#150;", "-")
   labelReplace := StrReplace(labelReplace, ",", "-")
   Return labelReplace
}

CleanLinks(uncleanLink)
{
   uncleanLink := Trim(uncleanLink)
   uncleanLink := Trim(uncleanLink, '"')
   linkReplace := StrReplace(uncleanLink, "[", "<")
   linkReplace := StrReplace(linkReplace, "]", ">")
   linkReplace := StrReplace(linkReplace, "(", "<<")
   linkReplace := StrReplace(linkReplace, ")", ">>")
   Return linkReplace
}

RestoreLinks(cleanedLink)
{
   linkReplace := StrReplace(cleanedLink, "<<", "(")
   linkReplace := StrReplace(linkReplace, ">>", ")")
   linkReplace := StrReplace(linkReplace, "><", "+")
   linkReplace := StrReplace(linkReplace, "<", "[")
   linkReplace := StrReplace(linkReplace, ">", "]")
   Return linkReplace
}

FindDrive(filePath)
{
   MsgBox "Checking drives.", ,"T1"
   driveList := DriveGetList()
   Loop Parse driveList
   {
      concatDrive := A_LoopField ":\" filePath
      if FileExist(concatDrive)
         return concatDrive
   }
   MsgBox "File not found."
   return false
}

SetMonitorBounds(guiH, guiW)
{
   ;;;;;; Adapted from this thread: https://www.autohotkey.com/boards/viewtopic.php?t=54557
   global mouseX
   global mouseY
   ; get the mouse coordinates first
   if (mouseKeep==0) {
      MouseGetPos &mouseX, &mouseY
   }

	MonitorCount := SysGet(80)	; monitorcount, so we know how many monitors there are, and the number of loops we need to do
	Loop MonitorCount
	{
      MonitorGet A_Index, &monLeft, &monTop, &monRight,&monBottom
		if ( mouseX >= monLeft ) && ( mouseX < monRight ) && ( mouseY >= monTop ) && ( mouseY < monBottom )
		{
			ActiveMon := A_Index
			break
		}
	}

   MonitorGetWorkArea ActiveMon, &mwaLeft, &mwaTop, &mwaRight, &mwaBottom
   
   ; add multiplication factor to adjust for monitor resolution
   adj := A_ScreenDPI/96
   xAdj:=(guiW/2)*adj
   yAdj:=(guiH/2)*adj
   xPos:=mouseX - xAdj
   yPos:=mouseY - yAdj
   buff := 15*adj
   Final_x := jump==1 ? max(mwaLeft, min(xPos, mwaRight-(guiW*adj))) : ((((mwaRight - mwaLeft) / 2) + mwaLeft)-xAdj)
	Final_y := jump==1 ? max(mwaTop, min(yPos, mwaBottom-buff-(guiH*adj))) : ((((mwaBottom - mwaTop) / 2) + mwaTop)-yAdj)
   return [Final_x, Final_y]
}

DestroyGui(reset*)
{
   LocalHotkeysOff()
   global lastIndex
   global lastLinkIndex
   if (reset[1]==1) {
      lastIndex := 1
      lastLinkIndex := 1
   } else {
      try lastIndex := catListbox.value
      try lastLinkIndex := linksListbox.value
   }
   HSR_String:=""
   HSR_Array:=""
   linkArray:=""
   %currentGui%.Destroy()
   Hotkey GUIHotkey, loadGUI
}

ExitAppFunc(*)
{
   ExitApp
}
