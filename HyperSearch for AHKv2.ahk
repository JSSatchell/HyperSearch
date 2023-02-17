#Requires AutoHotkey v2.0

TraySetIcon "shell32.dll", 210
;TraySetIcon("HyperSearch.ico")

SendMode "Input"  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#SingleInstance force
CoordMode "Mouse" ; Screen

;;;;;USE DEFAULT BROWSER;;;;;
ProgID := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice", "Progid")
Browser := "msedge.exe"
if (ProgID = "ChromeHTML")
   Browser := "chrome.exe"
if (ProgID ~= "FirefoxURL.*")
   Browser := "firefox.exe"
if (ProgID = "BraveHTML")
   Browser := "brave.exe"

if !FileExist("HS_Settings.ini")
   GenerateSettings()
else
   CheckSettings()

searchEngine := IniRead("HS_Settings.ini", "Search Engine", "Default")
GUIHotkey := IniRead("HS_Settings.ini", "Settings", "GUIHotkey")
hiHotkey := IniRead("HS_Settings.ini", "Settings", "HighlightHotkey")
jump := IniRead("HS_Settings.ini", "Settings", "jump")
repo := IniRead("HS_Settings.ini", "Settings", "Repository")
minMode := IniRead("HS_Settings.ini", "Settings", "MinMode")
currentGui := minMode = 1 ? "LiteGui" : "MainGui"

MainGui := Gui()
LiteGui := Gui()

if !FileExist(repo) {
   GenerateHSR()
}

index:=1
lastIndex:=1
lastLinkIndex:=1
mouseKeep:=0
urlDisplay:=""
todayQuick := FormatTime(, "yyMMdd")
controlColor := ""
urlTxtColor := ""
guiFont := ""
themeSel := ""
UsrIn := ""
linkArray := []

Hotkey GUIHotkey, loadGUI
Hotkey hiHotkey, searchHighlight
LocalHotkeysOff()

;;;;; Initialize hotkeys
!s::
{
   ;currentControl := %currentGui%.FocusedCtrl
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
      send "{tab}"
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
   Hotkey "LButton", ClickOff, "off"
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

LoadGUI(*)
{ 
   DestroyGUI()
   minMode := IniRead("HS_Settings.ini", "Settings", "MinMode")
   if (minMode == 1) { ; Activate minimal UI
      BuildLiteGUI()
   } else { ; Activate main UI
      BuildMainGUI()
   }
   %CurrentGui%.OnEvent("Close", destroyGui)
   %currentGui%.OnEvent("Escape", destroyGui)

}

searchHighlight(ThisHotkey)
{ 
   ;MsgBox "DING"
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
   GoogleSearch(A_Clipboard)
   A_Clipboard := prevClipboard
}

BuildLiteGUI(*)
{
   LoadMenu()
   Hotkey "LButton", "on"
   ;GoSub, BuildLinksArray
   global LiteGui := Gui("-Caption +ToolWindow -SysMenu","HyperSearch Lite")
   SetTheme()
   global editBar := LiteGui.Add("Edit", "r1 vUsrIn x10 y10 w230 h30 background" controlColor " " guiFont)
   ;Gui, Add, ComboBox, vUsrIn x10 y10 w230 h30 simple r5 gAutoComplete, %allLabelList%
   global submitButton := LiteGui.Add("Button", "Default x250 y10 w50 h20", "Submit")
   LiteGui.MenuBar := MainMenu
   submitButton.OnEvent("Click", ButtonSubmit)
   ;Gui -Caption
   ;Gui +ToolWindow
   ;MouseGetPos, mouseX, mouseY
   h:=40
   w:=310
   finalXY := SetMonitorBounds(h, w)
   LiteGui.Show("x" finalXY[1] " y" finalXY[2] " h" h " w" w)
   index:=lastIndex
}

BuildMainGUI(*)
{
   LoadMenu()
   LocalHotkeysOn()
   ;indexIndex:=0
   ;MsgBox HSR_String
   global MainGui := Gui("-Caption +ToolWindow -SysMenu","HyperSearch")
   SetTheme()
   global editBar := MainGui.Add("Edit", "r1 vUsrIn x160 y10 w220 h30 Background" controlColor " " guiFont)
   global catListbox := MainGui.Add("ListBox", "vIndex x10 y10 w140 h315 0x100 VScroll Choose" lastIndex " sort -AltSubmit Background" controlColor " " guiFont)
   global linksListbox := MainGui.Add("ListBox", "vLink x160 y45 w280 h280 0x100 Choose1 AltSubmit Background" controlColor " " guiFont)
   global submitButton := MainGui.Add("Button", "Default x390 y10 w50 h20 -Tabstop", "Submit")
   global urlTextGui := MainGui.Add("Text", "x10 y330 w430 " urlTxtColor, urlDisplay)
   MainGui.MenuBar := MainMenu
   BuildHSRArray()
   submitButton.OnEvent("Click", ButtonSubmit)
   editBar.OnEvent("Change", InputAlgorithm)
   catListbox.OnEvent("Change", LoadLinks)
   linksListbox.OnEvent("Change", SetLinkHighlight)
   linksListbox.OnEvent("DoubleClick", ActivateLinks)
   ; Generated Using SmartGUI Creator 4.0
   h:=350
   w:=450

   finalXY := SetMonitorBounds(h, w)
   MainGui.Show("h" h " w" w " x" finalXY[1] " y" finalXY[2])
   ControlChooseIndex lastIndex, catListbox
}

SetMonitorBounds(guiH, guiW)
{
   ;;;;;;Adapted from this thread: https://www.autohotkey.com/boards/viewtopic.php?t=54557
	global mouseX
   global mouseY
   ; get the mouse coordinates first
   if (mouseKeep==0) {
      MouseGetPos &mouseX, &mouseY
   }

	MonitorCount := SysGet(80)	; monitorcount, so we know how many monitors there are, and the number of loops we need to do
	Loop MonitorCount
	{
		;SysGet, mon%A_Index%, Monitor, %A_Index%	; "Monitor" will get the total desktop space of the monitor, including taskbars
      MonitorGet A_Index, &monLeft, &monTop, &monRight,&monBottom
		if ( mouseX >= monLeft ) && ( mouseX < monRight ) && ( mouseY >= monTop ) && ( mouseY < monBottom )
		{
			ActiveMon := A_Index
			break
		}
	}

   ;SysGet, mwa%ActiveMon%, MonitorWorkArea, %ActiveMon% ; "MonitorWorkArea" will get the desktop space of the monitor EXcluding taskbars
   MonitorGetWorkArea ActiveMon, &mwaLeft, &mwaTop, &mwaRight, &mwaBottom
   ;MsgBox % A_ScreenDPI
   ;;;;; mult * 2 for 4K monitors
   adj := A_ScreenDPI/96
   xAdj:=(guiW/2)*adj
   yAdj:=(guiH/2)*adj
   xPos:=mouseX - xAdj
   yPos:=mouseY - yAdj
   buff := 15*adj
   Final_x := jump==1 ? max(mwaLeft, min(xPos, mwaRight-(guiW*adj))) : ((((mwaRight - mwaLeft) / 2) + mwaLeft)-xAdj) ; /adj
	Final_y := jump==1 ? max(mwaTop, min(yPos, mwaBottom-buff-(guiH*adj))) : ((((mwaBottom - mwaTop) / 2) + mwaTop)-yAdj)
   ;msgbox % final_x . ", " . final_y
   return [Final_x, Final_y]
}

BuildHSRArray(*)
{
   global HSR_Array:=[]
   indexList:=""
   ;IniRead, repo, "HS_Settings.ini", Settings, Repository
   HSR_String := FileRead(repo)
   Loop Parse HSR_String, "`n", "`r" ; Build HSR_Array
   {
      r:=A_Index ; Row number
      newRow := []
      ;MsgBox A_LoopField
      Loop Parse A_LoopField, "CSV"
      {
         c:=A_Index ; Column number
         ;if (A_Index==1 && r>1)
         if (A_Index==1) ; Only search first column
         {
            chck:=A_LoopField ; . "|"
            dup := InStr(indexList,chck) ; Detect duplicates
            if (dup==0){
               indexList .= A_LoopField "|" ; Build index list for listbox
               catListbox.Add([A_LoopField])
            }
         }
         newRow.Push(A_LoopField)
      }
      HSR_Array.Push(newRow)
      ;MsgBox HSR_Array[r][1] "`n`n" HSR_Array[r][2]
   }
}

SaveHSR(*)
{
   HSR_String:=""
   Loop HSR_Array.Length   ; concat string array
   {
      r:=A_Index
      Loop HSR_Array[A_Index].Length
      {
         HSR_String .= A_Index == HSR_Array[r].Length ? '"' . HSR_Array[r][A_Index] . '"' : '"' . HSR_Array[r][A_Index] . '",'
      }
      if (A_Index!=HSR_Array.Length)
         HSR_String .= "`n"
   }
   ;MsgBox % HSR_String
   FileDelete repo
   FileAppend HSR_String, repo
}

ClickOff(ThisHotkey)
{
   hsID := WinExist("HyperSearch")
   contID := WinExist("Continue?")
   ;scriptName := A_ScriptName
   MouseGetPos ,,&winClick
   ;MsgBox A_ScriptName
   if (winClick!=hsID && winClick!=contID && winClick != A_ScriptName) {
      DestroyGUI()
   }
   Click "Down"
   Keywait A_ThisHotkey
   Click "Up"
}

RMenu(ThisHotkey)
{
   MouseGetPos ,,,&currentControl
   ;MsgBox % cont
   ;MsgBox "Right click!"
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
}

DelLink(*)
{
   global linkArray
   linkString:=""
   linksListbox.Opt("-redraw")
   contMsg := MsgBox("Do you want to remove the link " . Trim(linkArray[linksListbox.value][1]) . "?", "Continue?", 260)
   If (contMsg = "no")
      Return
   If (contMsg = "Yes")
      linkArray.RemoveAt(linksListbox.value)
   UpdateLinkList()
   LoadLinks()
   linksListbox.Opt("+redraw")
   editBar.value := ""
}

DelCat(*)
{
   lastSub := %currentGui%.Submit()
   global linkArray
   global HSR_Array
   contMsg := MsgBox("Do you want to delete all of the data in " lastSub.index "?", "Continue?", 260)
   If (contMsg = "No")
      return
   If (contMsg, "Yes")
   {
      Loop HSR_Array.Length
      {
         ;MsgBox catListbox.value
         ;match := InStr(index,HSR_Array[A_Index,1])
         ;MsgBox % HSR_Array[xPos,2] . "`n" . index
         if (lastSub.index==HSR_Array[A_Index][1]) {
            ;MsgBox catListbox.value
            HSR_Array.RemoveAt(A_Index)
            linkArray:=[]
            linkString:=""
            ;MsgBox % linkString
            break
         }
      }
      mouseKeep:=1
      linksListbox.Opt("-redraw")
      UpdateLinkList()
      DestroyGui()
      LoadGUI()
      linksListbox.Opt("+redraw")
      mouseKeep:=0
   }
   ;UpdateLinkList()
   ;LoadLinks()
   editBar.Value := ""
}

GoogleSearch(searchQuery)
{
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
      DestroyGui()
   }
}

ButtonSubmit(*)
{
   lastSub := %currentGui%.Submit(0)
   global mouseKeep
   ;MsgBox lastSub.UsrIn
   ;MsgBox "Ding"
   ;GuiControlGet, activeControl, Focus
   activeControl := %currentGui%.FocusedCtrl
   if (activeControl == linksListbox) {
      ;MsgBox "DING"
      if (linkArray[linksListbox.value][2] == "*") {
         linkLabel:=linkArray[linksListbox.value][1]
         RegExMatch(linkLabel, "<(.*?)>", &match)
         ;GuiControl, ChooseString, index, % "|" . match[1]
         ;catListbox.Choose(match[1])
         try {
            ControlChooseString match[1], catListbox
         } catch {
            MsgBox 'Category "' match[1] '" not found.'
         }
         return
      } else {
         ;searchQuery := linkArray[Link,2]
         GoogleSearch(linkArray[linksListbox.value][2])
      }
   } else if (activeControl == catListbox) {
      linksListbox.Focus()
   } else if (activeControl == editBar || activeControl == submitButton) {
      if (lastSub.UsrIn != ""){
         if (lastSub.UsrIn ~= "^ .*") {
            linksListbox.focus()
         } else if (RegExMatch(lastSub.UsrIn, "^[1-9]>.*")){
            mouseKeep:=1
            EditFav()
            DestroyGui()
            LoadGUI()
            mouseKeep:=0
         } else if (lastSub.UsrIn ~= "i)^set>.*"){
            mouseKeep:=1
            setMax:=0
            EditSettings()
            DestroyGui()
            LoadGUI()
            ;if (setMax=1)
            ;   GuiControl, Choose, index, % "|" . lastIndex
            mouseKeep:=0
         } else if (lastSub.UsrIn ~= "i)^import>.*") {
            if (lastSub.UsrIn ~= "i).*html$") {
               ImportChrome()
            } else if (lastSub.UsrIn ~= "i).*csv$") {
               ImportCSV()
            } else
               MsgBox "Unsupported format"
            DestroyGui()
            LoadGui()
         } else if (lastSub.UsrIn ~= "i)^load>.*") {
            LoadRepo()
            DestroyGui()
            LoadGui()
         } else if (lastSub.UsrIn ~= "i)^export>cat.{0,5}>h.{0,4}s.{0,5}") {
            ShareCat()
            DestroyGui()
            openSource()
         } else if (lastSub.UsrIn ~= "i)^export>cat.{0,5}") {
            ExportCat()
            DestroyGui()
            OpenSource()
         } else if (lastSub.UsrIn ~= "i)^export>repo.{0,6}") {
            ExportRepo()
            DestroyGui()
            OpenSource()
         } else if (lastSub.UsrIn ~= ".*\+.*"){
            linksListbox.Opt("-redraw")
            AppendLinks()
            LoadLinks()
            linksListbox.Opt("+redraw")
            editBar.Value := ""
         } else if (lastSub.UsrIn ~= "i)del.{0,3}\-[0-9|cat.{0,5}]*"){
            linksListbox.Opt("-redraw")
            RemoveLinks()
            LoadLinks()
            linksListbox.Opt("+redraw")
            editBar.Value := ""
         } else if (lastSub.UsrIn ~= "[1-9]*~[1-9]*" || lastSub.UsrIn ~= "[1-9]*%[1-9]*"){
            linksListbox.Opt("-redraw")
            ReorderLinks()
            LoadLinks()
            linksListbox.Opt("+redraw")
            editBar.Value := ""
         } else {
            GoogleSearch(lastSub.UsrIn)
         } 
      } else if (linkArray[linksListbox.value][2] == "*") {
         linkLabel:=linkArray[linksListbox.value][1]
         RegExMatch(linkLabel, "<(.*?)>", &match)
         ;GuiControl, ChooseString, index, % "|" . match[1]
         ;catListbox.choose(match[1])
         try {
            ControlChooseString match[1], catListbox
         } catch {
            MsgBox 'Category "' match[1] '" not found.'
         }
         return
      } else {
         searchURL := linkArray[linksListbox.value][2]
         GoogleSearch(searchURL)
      }
   }
}

InputAlgorithm(*)
{
   ;lastSub := %currentGui%.Submit(0)
   if(RegExMatch(editBar.value, "^ .+"))
   {
      try {
         ControlChooseString SubStr(editBar.value,2), catListbox
      } catch {
         sleep 50
      }
   }
}

LoadMenu(*)
{
   global MainMenu := MenuBar()
   global ExitMenu := Menu()
   global HelpMenu := Menu()
   i:=1
   while i <= 9 {
      ;Msgbox i
      favKey := "Favorite" . i
      currentFav := IniRead("HS_Settings.ini", "Favorite Labels", favKey)
      ;MsgBox currentFav
      if (currentFav != "")
         MainMenu.Add(currentFav, FavButton)
      i++
      ;MsgBox i
   }
   ExitMenu.Add("Close Window", DestroyGui)
   ExitMenu.Add("Exit App", ExitAppFunc)
   HelpMenu.Add("Support and updates", openGit)
   HelpMenu.Add("Open source folder", openSource)
   MainMenu.Add("[&?]", HelpMenu, "+right")
   MainMenu.Add("[&X]", ExitMenu, "+right")
}

LoadLinks(*)
{
   lastSub := %currentGui%.Submit(0)
   linkCell:=""
   thisLink:=[]
   ;labelList:=""
   global linkArray := []
   linksListbox.Opt("-Redraw")
   linksListbox.Delete()
   Loop HSR_Array.Length
   {
      ;MsgBox HSR_Array[A_Index][1] "`n`n" HSR_Array[A_Index][2]
      ;match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
      if (lastSub.index ==HSR_Array[A_Index][1]) {
         linkCell .= HSR_Array[A_Index][2]
         ;MsgBox linkCell
         break
      }
   }
   newPos:=1
   labelIndex:=1
   while (RegExMatch(linkCell, "\[(.*?)]", &currentLabel, newPos) != 0) {
      ;MsgBox linkCell
      if (labelIndex<10) {
         ;labelList .= "0" . labelIndex . ".  " . currentLabel[1] . "|"
         linksListbox.Add(["0" . labelIndex . ".  " . currentLabel[1]])
         ;MsgBox currentLabel[1]
      } else {
         ;labelList .= labelIndex . ".  " . currentLabel[1] . "|"
         linksListbox.Add([labelIndex . ".  " . currentLabel[1]])
         ;MsgBox currentLabel[1]
      }   
      newPos+=2
      RegExMatch(linkCell, "\((.*?)\)", &currentLink, newPos)
      ;MsgBox currentLabel[1] "`n" currentLink[1]
      ;thisLink.Push(currentLabel[1])
      ;thisLink.Push(currentLink[1])
      linkArray.Push([currentLabel[1],currentLink[1]])
      ;MsgBox linkArray[A_Index][1] "`n" linkArray[A_Index][2]
      newPos := currentLink.Pos(1)
      labelIndex++
   }
   urlDisplay:=linkArray[1][2]
   urlTextGui.value := urlDisplay
   ;GuiControl,,Link, |
   ;GuiControl,,Link, %labelList%
   ;GuiControl, Choose, Link, 1
   linksListbox.Opt("+Redraw")
   linksListbox.Choose(1)
}

ActivateLinks(*)
{
   if (linkArray[linksListbox.value][2] == "*") {
      linkLabel:=linkArray[linksListbox.value][1]
      RegExMatch(linkLabel, "<(.*?)>", &match)
      ;GuiControl, ChooseString, index, % "|" . match[1]
      ControlChooseString(match[1], catListbox)
   } else {
      ;searchQuery := linkArray[Link,2]
      GoogleSearch(linkArray[linksListbox.value][2])
   }
}

SetLinkHighlight(*)
{
   urlDisplay:=linkArray[linksListbox.value][2]
   urlTextGui.value := urlDisplay
}

AppendLinks(*)
{
   lastSub := %currentGui%.Submit(0)
   ;global HSR_Array
   linkString:=""
   ; Sample: 1Category+2LinkIndex+3LinkName+4URL
   linkTxt:=StrSplit(lastSub.UsrIn,"+",,4)
   linkIndex:=linkTxt[2]
   ;MsgBox linkTxt.length
   if (linkTxt[1]!="") { ; Add new category
      Loop HSR_Array.Length
      {
         ;match := InStr(index,HSR_Array[A_Index,1])
         ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
         if (linkTxt[1]=HSR_Array[A_Index][1]) {
            MsgBox "Category already exists."
            return
         }
      }
      ;MsgBox % SubStr(UsrIn,-1)
      
      if (linkTxt[2]!="" && linkTxt.Has(3)) { ; Add link in first position
         cleanLabel := CleanLabels(linkTxt[2])
         appendTxt:= '`n"' . linkTxt[1] . '",' . '"[' . cleanLabel . "](" . linkTxt[3] . ')"'
         FileAppend appendTxt, repo
         ;return
      } else if (SubStr(lastSub.UsrIn,-2) == "++") { ; Rename current category
         Loop HSR_Array.Length
         {
            ;match := InStr(index,HSR_Array[A_Index,1])
            if (catListbox.value==A_Index) {
               HSR_Array[A_Index][1]:=linkTxt[1] ; Add cell text to array
               MsgBox "Category " . lastSub.Index . " has been renamed to " . linkTxt[1] . "."
               SaveHSR()
               break
            }
         }
      } else if (SubStr(lastSub.UsrIn,-1) == "+") { ; Add category with blank first entry
         appendTxt:= '`n"' . linkTxt[1] . '",' . '"[ ]()"'
         FileAppend appendTxt, repo
         ;return
      } else {
         ;searchQuery := UsrIn
         ;GoogleSearch(lastSub.UsrIn)
         return
      }
      mouseKeep:=1
      newCat:=linkTxt[1]
      DestroyGui()
      BuildMainGUI()
      ;GuiControl, ChooseString, index, %newCat%
      catListbox.Choose(newCat)
      mouseKeep:=0
      return
   } else if (linkIndex == "v") {
      ;uncleanLabel := linkTxt[3]
      cleanLabel := CleanLabels(linkTxt[3])
      linkArray.push([cleanLabel,linkTxt[4]]) ; Add link in last position
   } else if IsNumber(linkIndex) ; Position specific Link
   {
      linkIndex := Integer(linkIndex)
      if (linkTxt.Has(3) && linkTxt.Has(4)) {
         MsgBox "Ding"
         ;uncleanLabel := linkTxt[3]
         cleanLabel := CleanLabels(linkTxt[3])
         linkArray.InsertAt(linkIndex,[cleanLabel,linkTxt[4]]) ; Insert at specified position
      } else if (!linkTxt.Has(3)) {
         if (!linkTxt.Has(4)) {
            linkArray.InsertAt(linkIndex,[linkTxt[3],linkTxt[4]]) 
         } else {
            linkArray[linkIndex][2]:=linkTxt[4] ; Update URL at position
            MsgBox linkArray[linkIndex][1] . " now links to " . linkArray[linkIndex][2]
         }

      ;} else if (linkTxt[4] == "" && SubStr(UsrIn,0) == "+") {
      } else if (!linkTxt.Has(4)) {
         oldLabel:=linkArray[linkIndex][1]
         ;uncleanLabel := linkTxt[3]
         cleanLabel := CleanLabels(linkTxt[3])
         linkArray[linkIndex][1]:=cleanLabel ; Update label at position
         MsgBox oldLabel . " is now labelled " . linkArray[linkIndex][1]
      }
   } else { ; Unspecified position number
      if (linkTxt.Has(2) && linkTxt.Has(3)) {
         ;uncleanLabel := linkTxt[2]
         cleanLabel := CleanLabels(linkTxt[2])
         linkArray.InsertAt(1,[cleanLabel,linkTxt[3]]) ; Insert in first position
      } else if (!linkTxt.Has(2)) {
         linkArray[linksListbox.value][2]:=linkTxt[3] ; Update URL of current
         MsgBox linkArray[linksListbox.value][1] . " now links to " . linkArray[linksListbox.value][2]
      ;} else if (linkTxt[3] == "" && SubStr(UsrIn,0) == "+") {
      } else if (!linkTxt.Has(3)) {
         oldLabel:=linkArray[linksListbox.value][1]
         ;uncleanLabel := linkTxt[2]
         cleanLabel := CleanLabels(linkTxt[2])
         linkArray[linksListbox.value][1]:=cleanLabel ; Update label of current
         MsgBox oldLabel . " is now labelled " . linkArray[linksListbox.value][1]
      }
   }
   
   UpdateLinkList()

   ;MsgBox % appendTxt
}

RemoveLinks(*)
{
   %currentGui%.Submit(0)
   global linkArray
   removeTxt:=StrSplit(editBar.value,"-",,3)
   linkString:=""
   removeTxtIndex:=removeTxt[2]
   ;Sample: 1DELETE-2LinkIndex
   if (removeTxt[2] ~= "i)cat.{0,5}") { ; remove cateogry
      delCat()
   } else if (removeTxt[2] != "" && removeTxt.length==3) { ; Remove list of links
      try { ; (IsNumber(removeTxt[2]) && IsNumber(removeTxt[3])) {
         val1:=Integer(removeTxt[2])
         val2:=Integer(removeTxt[3])
      } catch TypeError {
         MsgBox "Please only enter number values."
         return
      }
         
      start:=min(val1,val2)
      stop:=max(val1,val2)
      numRemove := stop-start + 1
      ;MsgBox % numRemove
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
         linkArray.RemoveAt(removeTxt[2])
      }
   }

   UpdateLinkList()
}

ReorderLinks(*)
{
   ;%currentGui%.Submit(0)
   global linkArray
   if (instr(editBar.value, "~"))
      swapTxt:=StrSplit(editBar.value,"~",,2)
   else if (instr(editBar.value, "%"))
      swapTxt:=StrSplit(editBar.value,"`%",,2)
   try {
      swapTxt2 := Integer(swapTxt[2])
   } catch TypeError {
      MsgBox "Please ony use number values."
      return
   }
   linkString:=""
   swap:=[]
   if (instr(swapTxt[1],"-")) { ;;;;; MULTIPLE LINKS
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
         linkArray.InsertAt(swapTxt2,[swap[A_Index][1],swap[A_Index][2]])   
      }
   } else {     ;;;;; SINGLE LINK
      try {
         swapTxt1 := Integer(swapTxt[1])
      } catch TypeError {
         MsgBox "Please ony use number values."
         return
      }
      swap:=linkArray[swapTxt1]
      linkArray.RemoveAt(swapTxt1)
      linkArray.InsertAt(swapTxt2,[swap[1],swap[2]])
   }
   UpdateLinkList()
}

UpdateLinkList(*)
{
   ;MsgBox "DING"
   global linkArray
   global HSR_Array
   Loop linkArray.Length
   {
      linkString .= "[" . linkArray[A_Index][1] . "](" . linkArray[A_Index][2] . ")"
   }
   
   Loop HSR_Array.Length
   {
      ;match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[xPos,2] . "`n" . index
      if (catListbox.value==A_Index) {
         HSR_Array[A_Index][2]:=linkString
         ;MsgBox % linkString
         break
      }
   }

   SaveHSR()
}

ExportCat(*)
{
   ;%currentGui%.Submit(0)
   addLink := ""
   Loop linkArray.Length {
      if (linkArray[A_Index][1] != "" && linkArray[A_Index][1] != " ")
         addLink .= linkArray[A_Index][1] . "," . linkArray[A_Index][2] . "`n"
      else
         addLink .= "`n"
   }
   ;MsgBox HSR_Array[catListbox.value][1]
   newFile := Trim(HSR_Array[catListbox.value][1]) . "_" . todayQuick . ".csv"
   If FileExist(newFile) {
      FileDelete newFile
   }
   FileAppend addLink, newFile
}

ShareCat(*)
{
   ;%currentGui%.Submit(0)
   shareCell := ""
   global HSR_Array
   Loop HSR_Array.Length
   {
      ;match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
      if (catListbox.value==A_Index) {
         shareCell .= HSR_Array[A_Index][2]
         ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
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
      ;MsgBox % index . "`n" . addLink
   }
   FileAppend exportLinks, exportFile
}

FavButton(favName, favPos, FavMenu)
{
   URL := IniRead("HS_Settings.ini", "Favorite Links", "FavLink" favPos, A_Space)
   if(URL == "")
      MsgBox "Favorite " . favPos . " is undefined."
   else {
      GoogleSearch(URL)
      DestroyGui()
   }
}

EditFav(*)
{
   MainMenu.Delete()
   indx:=SubStr(editBar.value,1,1)
   val := StrSplit(editBar.value,">",,3)
   newLnk := val[3]
   if (val[2] != "" || val[3] != "") {
      newLbl := "&" . indx . " " . val[2]
      if (val[2] != ""){
         if (val[3] = "")
            MsgBox "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&" . indx . " ") . ".", "Favorite Reassigned"
         else
            MsgBox "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&" . indx . " ") . " and links to " . newLnk . ".", "Favorite Reassigned"
      } else
         MsgBox "Favorite " . indx . " now links to " . newLnk . ".","Favorite Reassigned"
   } else {
      newLbl:=""
      MsgBox "Favorite " . indx . " has been removed.","Favorite Erased"
   }
   if (val[2] = "" && val[3] = "" || val[2] != "")
      IniWrite newLbl, "HS_Settings.ini", "Favorite Labels", "Favorite" indx
   if (val[2] = "" && val[3] = "" || val[3] != "")
      IniWrite newLnk, "HS_Settings.ini", "Favorite Links", "FavLink" indx
   DestroyGui()
}

EditSettings(*)
{
   search:=StrSplit(editBar.value,">",,3)
   if (search[2] ~= "i)d.{0,1}rk") {
      IniWrite 1, "HS_Settings.ini", "Settings", "DkMd"
   } else if (search[2] ~= "i)light") {
      IniWrite 0, "HS_Settings.ini", "Settings", "DkMd"
   } else if (search[2] ~= "i)min") {
      MsgBox "Under construction..."
      ;IniWrite 1, "HS_Settings.ini", "Settings", "MinMode"
   } else if (search[2] ~= "i)max") {
      IniWrite 0, "HS_Settings.ini", "Settings", "MinMode"
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
      ;IniRead, GUIHotkey, "HS_Settings.ini", Settings, GUIHotkey
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
      ;IniRead, hiHotkey, "HS_Settings.ini", Settings, HighlightHotkey
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
         ;MsgBox "Transparency is set to " . transVal . "%"
      } catch TypeError {
         MsgBox "Value should be a number."
         return
      }
   } else {
      MsgBox "Invalid settings option."
   }
}

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

ImportChrome(*)
{
   replace:=0
   otherChk:=0
   search:=StrSplit(editBar.value,">",,2)
   bkmkLines:=[]
   global HSR_Array
   ;MsgBox % "Link: " . search[2]
   bkmkPath:=search[2]
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
      ;MsgBox A_LoopField
      bkmkLines.push(A_LoopField)
   }
   ;MsgBox % bkmk
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
      ;MsgBox % head
      numTabs := round(numTabs/4)

      if (head == "H3") { ; New category
         RegExMatch(currentLine, "<H3 .*>(.*?)</H3>", &catScan)
         thisCat:=catScan[1]
         if (thisCat == "Bookmarks bar") {
            thisCat :=  " Bookmarks bar"
         }
         Loop HSR_Array.Length
         {
            ;match := InStr(index,HSR_Array[A_Index,1])
            ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
            if (thisCat == HSR_Array[A_Index][1]) {
               ogCat := thisCat
               thisCat.="_1"
               ;MsgBox % "Category " . ogCat . " already exists.`nThe category will be added as " . thisCat . "."
               ;return
            }
         }
         ;MsgBox fullArray.length
         fullArray.InsertAt(catIndex,[thisCat])
         ;catRow.Push(thisCat)
         nxtTab:=numTabs+1
         i:=A_Index+2
         subTabs:=numTabs+1
         while  subTabs > numTabs ;&& i != bkmkLines.maxIndex()
         {
               ;MsgBox % "Loop start`n" . subTabs . " > " . numTabs . "`n" . currentLine
               subLine:=bkmkLines[i]
               ;MsgBox % subLine
               subTabs:=0
               subCharPos:=6
               ;MsgBox % subLine
               Loop Parse, subLine
               {
                  if (A_LoopField == A_Space) {
                     subTabs++
                     subCharPos++
                  } else 
                     break
               }
               subTabs := round(subTabs/4)
               ;MsgBox % subLine . " : " . subTabs
               subHead:=SubStr(subLine,subCharPos,2)
               ;MsgBox % subTabs . " = " . nxtTab . "`n" . subLine . "`n" . currentLine
               if (subTabs == nxtTab) {
                  ;MsgBox % subHead
                  if (subHead=="H3") {
                     ;MsgBox % subTabs . " : " . nxtTab
                     RegExMatch(subLine, "<H3 .*>(.*?)</H3>", &subCat)
                     ;MsgBox % thisCat[1] . " : " . numTabs . "`n" . subCat[1] . " : " . subTabs
                     fullArray[catIndex].push("[<" . subCat[1] . ">](*)")
                     ;fullArray.InsertAt(catIndex, "[<" . subCat[1] . ">](*)")
                     ;catRow.Push("[<" . subCat[1] . ">](*)")
                     ;fullArray.Push([thisCat, "[<" . subCat[1] . ">](*)"])
                  } else if (subHead == "A ") {
                     RegExMatch(subLine, '<A HREF="(.*?)"', &subLink)
                     RegExMatch(subLine, "<A .*>(.*?)</A>", &subLabel)
                     ;MsgBox % "Current label: " . thisLabel[1] . "`nCurrent link: " . thisLink[1]
                     ;checkString:=subLabel[1]
                     if (subLabel[1] != "") {
                        ;uncleanLabel := subLabel[1]
                        labelReplace := CleanLabels(subLabel[1])
                     } else {
                        labelReplace := subLink[1]
                     }
                     checkLink:=subLink[1]
                     ;MsgBox % RegExMatch(checkLink, "javascript.*")
                     if (RegExMatch(checkLink, "javascript.*") != 0) {
                        checkLink := " "
                     }

                     fullArray[catIndex].Push("[" . labelReplace . "](" . checkLink . ")")
                     ;fullArray.InsertAt(catIndex, "[" . labelReplace . "](" . checkLink . ")")
                  }
               }
               i++                                        
         }
         catIndex++
      } else if (head == "A " && numTabs == 1) {
         if (otherChk==0) {
            fullArray[catIndex][1]:=" Other bookmarks"
            ;fullArray.InsertAt(catIndex, " Other bookmarks")
            otherChk:=1
            otherCat:=catIndex
         }
         RegExMatch(currentLine, '<A HREF="(.*?)"', &subLink)
         RegExMatch(currentLine, "<A .*>(.*?)</A>", &subLabel)
         ;MsgBox % "Current label: " . thisLabel[1] . "`nCurrent link: " . thisLink[1]
         ;checkString:=subLabel[1]
         if (subLabel[1] != "") {
            ;uncleanLabel := subLabel[1]
            labelReplace := CleanLabels(subLabel[1])
         } else {
            labelReplace := subLink[1]
         }
         checkLink:=subLink[1]
         ;MsgBox % RegExMatch(checkLink, "javascript.*")
         if (RegExMatch(checkLink, "javascript.*") != 0) {
            ;MsgBox "Ding"
            checkLink := " "
         }

         fullArray[otherCat][2] .= "[" . labelReplace . "](" . checkLink . ")"
         ;fullArray.InsertAt(otherCat, "[" . LabelReplace . "](" . checkLink . ")")
         ;catIndex++
         nxtTab:=1
         i:=A_Index+1
         subTabs:=numTabs+1
         while  subTabs > numTabs ;&& i != bkmkLines.maxIndex()
         {
            ;MsgBox % "Loop start`n" . subTabs . " > " . numTabs . "`n" . currentLine
            subLine:=bkmkLines[i]
            ;MsgBox % subLine
            subTabs:=0
            subCharPos:=6
            ;MsgBox % subLine
            Loop Parse, subLine
            {
               if (A_LoopField == A_Space) {
                  subTabs++
                  subCharPos++
               } else 
                  break
            }
            subTabs := round(subTabs/4)
            ;MsgBox % subLine . " : " . subTabs
            subHead:=SubStr(subLine,subCharPos,2)
            ;MsgBox % subTabs . " = " . nxtTab . "`n" . subLine . "`n" . currentLine
            if (subTabs == nxtTab) {
               ;MsgBox % subHead
               if (subHead=="H3") {
                  ;MsgBox % subTabs . " : " . nxtTab
                  RegExMatch(subLine, "<H3 .*>(.*?)</H3>", &subCat)
                  ;MsgBox % thisCat[1] . " : " . numTabs . "`n" . subCat[1] . " : " . subTabs
                  fullArray[otherCat][2] .= "[<" . subCat[1] . ">](*)"
                  ;fullArray.InsertAt(otherCat, "[<" . subCat[1] . ">](*)")
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
   ;MsgBox % HSR_ImportString
   if (replace==1)
      FileDelete repo
   FileAppend HSR_ImportString, repo
   HSRImportString:=""
   bkmk:=""
   bkmkLines:=[]
   fullArray := []
}

CleanLabels(uncleanLabel)
{
   cleanLabel := ""
   labelReplace := StrReplace(uncleanLabel, "|", "-")
   labelReplace := StrReplace(labelReplace, ")", "}")
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
   ;cleanLabel := labelReplace
   ;uncleanLabel:= ""
   Return labelReplace
}

ImportCSV(*)
{
   global repo
   replace:=0
   search:=StrSplit(editBar.value,">",,2)
   newCSVPath:=search[2]
   newCSV := FileRead(newCSVPath)
   newCSV:="`n" . newCSV
   FileAppend newCSV, repo
}

LoadRepo(*)
{
   global repo
   search:=StrSplit(editBar.value,">",,2)
   repo:=search[2]
   IniWrite repo, "HS_Settings.ini", "Settings", "Repository"
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

CheckSettings(*)
{
   newSettings:=""
   sections := IniRead("HS_Settings.ini")
   sectionsArray:=StrSplit(sections,"`n")
   lastSection:=sectionsArray[sectionsArray.Length]
   if (lastSection == "Theme") {
      themeContent := IniRead(themeContent, "HS_Settings.ini", "Theme")
      themeContent := "[Settings]`n" . themeContent
      IniDelete "HS_Settings.ini", "Theme"
      FileAppend themeContent, "HS_Settings.ini"
   }
   settingsContent := IniRead("HS_Settings.ini", "Settings")
   settingsArray:=StrSplit(settingsContent,"`n")
   lastSetting:=settingsArray[settingsArray.Length]
   lastSettingArray:=StrSplit(lastSetting,"=")
   ;MsgBox lastSettingArray[1]
   if (lastSettingArray[1]=="MinMode") {
      newSettings:="`nGUIHotkey=#Space`nHighlightHotkey=^#Space`nJump=1"
   } else if (lastSettingArray[1]=="HighlightHotkey") {
      newSettings:="`nJump=1"
   } else if (lastSettingArray[1]=="Jump") {
      newSettings:="`nRepository=HSR_Master.csv"
   }
   FileAppend newSettings, "HS_Settings.ini"

   ; ADD:
   ;    - Replace "Trans" property with "Opacity"
   ;    - Add version number property

}

GenerateSettings(*)
{
   FileAppend "
   (
[Version]
CurrentVersion=1.2.1

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
   )", "HS_Settings.ini"
}

GenerateHSR(*)
{
      FileAppend "
      (
" Quick Access","[<Quick Start Guide>](*)"
"Quick Start Guide","[NAVIGATION REFERENCE](https://github.com/JSSatchell/HyperSearch#navigation)[Press Space to search the category index on the left]()[Tab between control windows]()[Press Enter after typing Space to set focus to links]()[Use Enter or double click links to activate URL]()[ ]()[TEXT ENTRY REFERENCE](https://github.com/JSSatchell/HyperSearch#adding--removing-categories--links)[Edit Favorites - 'Favorite#>Label>URL'](https://github.com/JSSatchell/HyperSearch#update-favorites)[Add Index Category - 'Category Name+']()[Add link - '+Link Name+Link URL']()[Add at Position - '+Position#+Link Name+LinkURL']()[Remove Selected Link - 'Delete-']()[Remove at Position - 'Delete-Position#']()[Delete Category - 'Delete-Category']()[ ]()[SETTINGS](https://github.com/JSSatchell/HyperSearch#update-the-settings)[Min/Max Mode - 'Set>Min/Max']()[Dark/Light Mode - 'Set>Dark/Light']()[Transparency - 'Set>Opacity>Percentage']()[]()[CLICK HERE for full feature list & updates](https://github.com/JSSatchell/HyperSearch)"
   )", "HSR_Master.csv"
}

openGit(*)
{
   Run "https://github.com/JSSatchell/HyperSearch"
   DestroyGui()
}

; ^v^v^v^v^ Merge openGit() and openSource() to open(destination)

openSource(*)
{
   Run A_WorkingDir
   DestroyGui()
}

DestroyGui(*) {
   LocalHotkeysOff()
   try {
      global lastIndex := catListbox.value
   } catch {
      lastIndex := 1
   }
   try {
      global lastLinksIndex := linksListbox.value
   } catch {
      lastLinksIndex := 1
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
