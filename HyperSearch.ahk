Menu, Tray, Icon, shell32.dll, 210 ; Magnifying glass icon

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
CoordMode, Mouse ; , Screen
;#InstallMouseHook
;#InstallKeybdHook

;;;;;USE DEFAULT BROWSER;;;;;
RegRead, ProgID, HKEY_CURRENT_USER, Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice, Progid
Browser := "iexplore.exe"
if (ProgID = "ChromeHTML")
   Browser := "chrome.exe"
if (ProgID = "FirefoxURL")
   Browser := "firefox.exe"

If !FileExist("HS_Settings.ini")
   Gosub, GenerateSettings
else
   GoSub, CheckSettings

IniRead, searchEngine, HS_Settings.ini, Search Engine, Default
IniRead, GUIHotkey, HS_Settings.ini, Settings, GUIHotkey
IniRead, hiHotkey, HS_Settings.ini, Settings, HighlightHotkey
IniRead, jump, HS_Settings.ini, Settings, jump

If !FileExist("HSR_Master.csv") {
   GoSub, GenerateHSR
}

index:=1
lastIndex:=1
mouseKeep:=0
urlDisplay=

Hotkey, %GUIHotkey%, LoadGUI
Hotkey, %hiHotkey%, searchHighlight
GoSub, LocalHotkeysOff

;;;;; Initialize hotkeys
+s::
   GuiControlGet, currentControl, Focus
   if (currentControl=="ListBox1" || currentControl=="ListBox2") {
      send, {down}
   } else if (currentControl=="Edit1") {
      hotkey, +s, off
      Send, +s
      hotkey, +s, on
   }
return

+a::
   GuiControlGet, currentControl, Focus
   if (currentControl=="ListBox1") {
      send, {tab}
   } else if (currentControl=="ListBox2") {
      send, +{tab}
   } else if (currentControl=="Edit1") {
      hotkey, +a, off
      Send, +a
      hotkey, +a, on
   }
return

+w::
   GuiControlGet, currentControl, Focus
   if (currentControl=="ListBox1" || currentControl=="ListBox2") {
      send, {up}
   } else if (currentControl=="Edit1") {
      hotkey, +w, off
      Send, +w
      hotkey, +w, on
   }
return

+d::
   GuiControlGet, currentControl, Focus
   if (currentControl=="ListBox1") {
      send, {tab}
   } else if (currentControl=="ListBox2") {
      send, +{tab}
   } else if (currentControl=="Edit1") {
      hotkey, +d, off
      Send, +d
      hotkey, +d, on
   }
return

!e::
   Gui, Submit, noHide
   if (linkArray[Link,2] == "*") {
      linkLabel:=linkArray[Link,1]
      RegExMatch(linkLabel, "O)<(.*?)>", match)
      GuiControl, ChooseString, index, % "|" . match[1]
   } else {
      searchQuery := linkArray[Link,2]
      GoSub, GoogleSearch
   }
return

LocalHotkeysOff:
Hotkey, RButton, RMenu, off
Hotkey, +s, +s, off
Hotkey, +a, +a, off
Hotkey, +w, +w, off
Hotkey, +d, +d, off
Hotkey, ^c, CopyLink, off
Hotkey, !e, !e, off
Hotkey, LButton, ClickOff, off
return

LocalHotkeysOn:
Hotkey, RButton, on
Hotkey, LButton, on
Hotkey, +s, on
Hotkey, +a, on
Hotkey, +w, on
Hotkey, +d, on
Hotkey, ^c, on
Hotkey, !e, on
return

LoadGUI:
{ 
   GoSub, DestroyGUI
   IniRead, min, HS_Settings.ini, Settings, MinMode
   if (min == 1) { ; Activate minimal UI
      GoSub, BuildLiteGUI
      Return
   } else { ; Activate main UI
      GoSub, BuildMainGUI
      Return
   }
   GuiClose:
   GuiEscape:
      GoSub, DestroyGui
   Return
}

searchHighlight:
{ 
   BlockInput, on 
   prevClipboard = %clipboard% 
   clipboard = 
   Send, ^c 
   BlockInput, off 
   ClipWait, 2 
   if ErrorLevel = 0 
   { 
      searchQuery=%clipboard% 
      GoSub, GoogleSearch 
   } 
   clipboard = %prevClipboard% 
   return 
}

BuildLiteGUI:
   Gosub, LoadMenu
   GoSub, SetTheme
   Hotkey, LButton, on
   ;GoSub, BuildLinksArray
   Gui, Add, Edit, r1 vUsrIn x10 y10 w230 h30
   ;Gui, Add, ComboBox, vUsrIn x10 y10 w230 h30 simple r5 gAutoComplete, %allLabelList%
   Gui, Add, Button, Default x250 y10 w50 h20 , Submit
   Gui -Caption
   Gui +ToolWindow
   ;MouseGetPos, mouseX, mouseY
   w:=310
   h:=40
   GoSub, SetMonitorBounds
   Gui, Show, x%Final_x% y%Final_y% h%h% w%w%, HyperSearch Lite
   index:=lastIndex
return

BuildMainGUI:
   Gosub, LoadMenu
   GoSub, SetTheme
   GoSub, LocalHotkeysOn
   ;indexIndex:=0
   ;MsgBox, %HSR_String%
   GoSub, BuildHSRArray
   Gui, Add, Edit, r1 vUsrIn x160 y10 w220 h30 gInputAlgorithm
   Gui, Add, ListBox, vIndex x10 y10 w140 h315 0x100 VScroll Choose%lastIndex% sort -AltSubmit gLoadLinks, %indexList%
   Gui, Add, ListBox, vLink x160 y45 w280 h280 0x100 Choose1 AltSubmit gActivateLinks
   Gui, Add, Button, Default x390 y10 w50 h20 -Tabstop, Submit
   Gui, Add, Text, x10 y330 w430, %urlDisplay%
   if (themeSel==1)
      GuiControl, +cSilver, Static1
   else
      GuiControl, +c595959, Static1

   ; Generated UsrIng SmartGUI Creator 4.0
   Gui -Caption
   Gui +ToolWindow
   Gui -SysMenu
   ;MouseGetPos, mouseX, mouseY
   h:=350
   w:=450

   GoSub, SetMonitorBounds
   Gui, Show, h%h% w%w% x%Final_x% y%Final_y%, HyperSearch

   Control, Choose, %lastIndex%, Listbox1
return

SetMonitorBounds:
   ;;;;;;Adapted from this thread: https://www.autohotkey.com/boards/viewtopic.php?t=54557
	
   ; get the mouse coordinates first
   if (mouseKeep==0) {
      MouseGetPos, mouseX, mouseY
   }

	SysGet, MonitorCount, 80	; monitorcount, so we know how many monitors there are, and the number of loops we need to do
	Loop, %MonitorCount%
	{
		SysGet, mon%A_Index%, Monitor, %A_Index%	; "Monitor" will get the total desktop space of the monitor, including taskbars

		if ( mouseX >= mon%A_Index%left ) && ( mouseX < mon%A_Index%right ) && ( mouseY >= mon%A_Index%top ) && ( mouseY < mon%A_Index%bottom )
		{
			ActiveMon := A_Index
			break
		}
	}

   SysGet, mwa%ActiveMon%, MonitorWorkArea, %ActiveMon% ; "MonitorWorkArea" will get the desktop space of the monitor EXcluding taskbars
   ;MsgBox % A_ScreenDPI
   ;;;;; mult * 2 for 4K monitors
   adj := A_ScreenDPI/96
   xAdj:=(w/2)*adj
   yAdj:=(h/2)*adj
   xPos:=mouseX - xAdj
   yPos:=mouseY - yAdj
   buff := 15*adj
   Final_x := jump==1 ? max(mwa%ActiveMon%left, min(xPos, mwa%ActiveMon%right-(w*adj))) : ((((mwa%ActiveMon%right - mwa%ActiveMon%left) / 2) + mwa%ActiveMon%left)-xAdj) ; /adj
	Final_y := jump==1 ? max(mwa%ActiveMon%top, min(yPos, mwa%ActiveMon%bottom-buff-(h*adj))) : ((((mwa%ActiveMon%bottom - mwa%ActiveMon%top) / 2) + mwa%ActiveMon%top)-yAdj)
   ;msgbox % final_x . ", " . final_y
return

BuildHSRArray:
   HSR_Array:=[]
   indexList=
   indexArray:=[]
   FileRead, HSR_String, HSR_Master.csv
   Loop, Parse, HSR_String, `n, `r ; Build HSR_Array
   {
      r:=A_Index ; Row number
      ;MsgBox, % A_LoopField
      Loop, Parse, A_LoopField, CSV
      {
         c:=A_Index ; Column number
         if (A_Index==1 && r>1) ; Only search first column
         {
            chck:=A_LoopField . "|"
            dup := InStr(indexList,chck) ; Detect duplicates
            if (dup==0){
               indexList .= A_LoopField . "|" ; Build index list for listbox
               indexArray.Push(A_LoopField)
            }
         }
         HSR_Array[r,c]:=A_LoopField
      }
      indexIndex++
   }
return

SaveHSR:
   HSR_String=
   Loop, % HSR_Array.MaxIndex()   ; concat string array
   {
      r:=A_Index
      Loop, % HSR_Array[A_Index].MaxIndex()
      {
         HSR_String .= A_Index == HSR_Array[r].MaxIndex() ? """" . HSR_Array[r,A_Index] . """" : """" . HSR_Array[r,A_Index] . ""","
      }
      if (A_Index!=HSR_Array.MaxIndex())
         HSR_String .= "`n"
   }
   ;MsgBox % HSR_String
   FileDelete,HSR_Master.csv
   FileAppend,%HSR_String%, HSR_Master.csv
return

ClickOff:
   WinGet,hsID,ID,HyperSearch
   MouseGetPos,,,winClick
   ;MsgBox % hsID . "`n" . winClick
   if (winClick!=hsID)
      GoSub, DestroyGUI
   Click, L, down
   Keywait, %A_ThisHotkey%
   Click, L, Up
return

RMenu:
   MouseGetPos,,,,currentControl
   ;MsgBox % cont
   ;MsgBox, Right click!
   if (currentControl=="ListBox2"){
      Click,
      Menu, RCLB2, Add, Copy Link, CopyLink
      Menu, RCLB2, Add, Delete, DelLink
      Menu, RCLB2, Show
   } else if (currentControl=="ListBox1") {
      Click,
      Menu, RCLB1, Add, Delete, DelCat
      Menu, RCLB1, Show
   } else
      Click, R
return

CopyLink:
   GuiControlGet, currentControl, Focus
   if (currentControl!="Edit1") {
      activeLink:=linkArray[Link,2]
      clipboard = %activeLink%
   } else {
      hotkey, ^c, off
      Send, ^c
      hotkey, ^c, on
   }
return

DelLink:
   linkString=
   GuiControl, -redraw, Link
   MsgBox, 260, Continue?, % "Do you want to remove the link " . Trim(linkArray[Link,1]) . "?"
   IfMsgBox, No
      Return
   IfMsgBox, Yes
      linkArray.RemoveAt(Link)
   GoSub, UpdateLinkList
   GoSub, LoadLinks
   GuiControl, +redraw, Link
   GuiControl,,UsrIn,
return

DelCat:
   GuiControl, -redraw, Link
   MsgBox, 260, Continue?, Do you want to delete all of the data in %index%?
   ifMsgBox, No
      return
   IfMSgBox, Yes
   {
      Loop % HSR_Array.MaxIndex()
      {
         ;match := InStr(index,HSR_Array[A_Index,1])
         ;MsgBox % HSR_Array[xPos,2] . "`n" . index
         if (index==HSR_Array[A_Index,1]) {
            HSR_Array.RemoveAt(A_Index)
            linkArray:=[]
            linkString=
            ;MsgBox % linkString
            break
         }
      }
      mouseKeep:=1
      GoSub, UpdateLinkList
      GoSub, DestroyGui
      GoSub, BuildMainGUI
      mouseKeep:=0
   }
   GoSub, UpdateLinkList
   GoSub, LoadLinks
   GuiControl, +redraw, Link
   GuiControl,,UsrIn,
return

GoogleSearch:
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
            Run, %browser% %searchEngine%%searchQuery%  
         else
            Run, %browser% %searchQuery% 
      } else
         Run, %browser% %searchEngine%%searchQuery%
      GoSub, DestroyGui
   }
return

ButtonSubmit:
   Gui, Submit, noHide
   GuiControlGet, activeControl, Focus
   ;MsgBox % activeControl
   if (activeControl == "ListBox2") {
      if (linkArray[Link,2] == "*") {
         linkLabel:=linkArray[Link,1]
         RegExMatch(linkLabel, "O)<(.*?)>", match)
         GuiControl, ChooseString, index, % "|" . match[1]
         return
      } else {
         searchQuery := linkArray[Link,2]
         GoSub, GoogleSearch
      }
   } if (activeControl == "ListBox1") {
      GuiControl, focus, Link
   } else {
      if (UsrIn != ""){
         if (UsrIn ~= "^ .*"){
            GuiControl, focus, Link
         } else if (RegExMatch(UsrIn, "^[1-9]>.*")){
            mouseKeep=1
            GoSub, EditFav
            GoSub, DestroyGui
            GoSub, LoadGUI
            mouseKeep=0
         } else if (UsrIn ~= "i)^set>.*"){
            mouseKeep=1
            setMax=0
            GoSub, EditSettings
            GoSub, DestroyGui
            GoSub, LoadGUI
            ;if (setMax=1)
            ;   GuiControl, Choose, index, % "|" . lastIndex
            mouseKeep=0
         } else if (UsrIn ~= ".*\+.*"){
            GuiControl, -redraw, Link
            GoSub, AppendLinks
            GoSub, LoadLinks
            GuiControl, +redraw, Link
            GuiControl,,UsrIn,
         } else if (UsrIn ~= "i)del.{0,3}\-[0-9|cat.{0,5}]*"){
            GuiControl, -redraw, Link
            GoSub, RemoveLinks
            GoSub, LoadLinks
            GuiControl, +redraw, Link
            GuiControl,,UsrIn,
         } else if (UsrIn ~= "[1-9]*~[1-9]*" || UsrIn ~= "[1-9]*%[1-9]*"){
            GuiControl, -redraw, Link
            GoSub, ReorderLinks
            GoSub, LoadLinks
            GuiControl, +redraw, Link
            GuiControl,,UsrIn,
         } else {
            searchQuery = %UsrIn%
            GoSub, GoogleSearch
         } 
      } else {
         searchQuery := linkArray[Link,2]
         GoSub, GoogleSearch
      }
   }
Return

InputAlgorithm:
   Gui, Submit, noHide
   ;GuiControl, ChooseString, IndexList, |%UsrIn%
   if(RegExMatch(UsrIn, "^ .*"))
   {
      GuiControl, ChooseString, index, % "|" . SubStr(UsrIn,2)
   }
return

LoadMenu:
   ;Gui Menu
   i:=1
   while(i<=9){
      IniRead, currentFav, HS_Settings.ini, Favorite Labels, Favorite%i%
      if (currentFav != "")
         Menu, MainMenu, Add, %currentFav%, FavButtonClick
      i++
   }
   Menu, Exit, Add, Close Window, DestroyGui
   Menu, Exit, Add, Exit App, ExitApp
   Menu, MainMenu, Add, [&?], Help, +right
   Menu, MainMenu, Add, [&X], :Exit, +right
   Gui, Menu, MainMenu
return

LoadLinks:
   Gui, Submit, noHide
   linkCell=
   labelList=
   linkArray := []
   Loop % HSR_Array.MaxIndex()
   {
      ;match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
      if (index==HSR_Array[A_Index,1]) {
         linkCell .= HSR_Array[A_Index,2]
         ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
         break
      }
   }
   newPos:=1
   labelIndex:=1
   while (RegExMatch(linkCell, "O)\[(.*?)]", currentLabel, StartingPos := newPos) != 0) {
      if (labelIndex<10)
         labelList .= "0" . labelIndex . ".  " . currentLabel[1] . "|"
      else
         labelList .= labelIndex . ".  " . currentLabel[1] . "|"
      newPos+=2
      RegExMatch(linkCell, "O)\((.*?)\)", currentLink, StartingPos := newPos)
      linkArray[labelIndex,1]:=currentLabel[1]
      linkArray[labelIndex,2]:=currentLink[1]
      newPos := currentLink.Pos(1)
      labelIndex++
   }
   urlDisplay:=linkArray[1,2]
   GuiControl,,Static1, %urlDisplay%
   GuiControl,,Link, |
   GuiControl,,Link, %labelList%
   GuiControl, Choose, Link, 1
return

ActivateLinks:
   Gui, Submit, noHide
   if (A_GuiEvent == "DoubleClick") {
      if (linkArray[Link,2] == "*") {
         linkLabel:=linkArray[Link,1]
         RegExMatch(linkLabel, "O)<(.*?)>", match)
         GuiControl, ChooseString, index, % "|" . match[1]
      } else {
         searchQuery := linkArray[Link,2]
         GoSub, GoogleSearch
      }
   } else {
      urlDisplay:=linkArray[Link,2]
      GuiControl,,Static1,%urlDisplay%
   }
return

AppendLinks:
   Gui, Submit, noHide
   linkString=
   ; Sample: 1Category+2LinkIndex+3LinkName+4URL
   linkTxt:=StrSplit(UsrIn,"+",,4)
   linkIndex:=linkTxt[2]
   ;MsgBox % indexLabel . "`n" . linkIndex . "`n" . linkName . "`n" . linkURL
   if (linkTxt[1] != "") { ; Add new category
      Loop % HSR_Array.MaxIndex()
      {
         ;match := InStr(index,HSR_Array[A_Index,1])
         ;MsgBox % HSR_Array[A_Index,1] . "`n" . index
         if (linkTxt[1]=HSR_Array[A_Index,1]) {
            MsgBox, Category already exists.
            skip:=1
            return
         }
      }
      ;MsgBox % SubStr(UsrIn,-1)
      
      if (linkTxt[2] != "" && linkTxt[3] != "") { ; Add first link
         appendTxt:="`n""" . linkTxt[1] . """," . """[" . linkTxt[2] . "](" . linkTxt[3] . ")"""
         FileAppend, %appendTxt%, HSR_Master.csv
         ;return
      } else if (SubStr(UsrIn,-1) == "++") { ; Rename current category
         Loop % HSR_Array.MaxIndex()
         {
            ;match := InStr(index,HSR_Array[A_Index,1])
            if (index==HSR_Array[A_Index,1]) {
               HSR_Array[A_Index,1]:=linkTxt[1] ; Add cell text to array
               MsgBox % "Category " . index . " has been renamed to " . linkTxt[1] . "."
               GoSub, SaveHSR
               break
            }
         }
      } else { ; Add category with blank first entry
         appendTxt:="`n""" . linkTxt[1] . """," . """[ ]()"""
         FileAppend, %appendTxt%, HSR_Master.csv
         ;return
      }
      mouseKeep:=1
      GoSub, DestroyGui
      GoSub, BuildMainGUI
      mouseKeep:=0
      return
   } else if (linkIndex == "v") {
      linkArray.push([linkTxt[3],linkTxt[4]]) ; Add link in last position
   } else if linkIndex is integer ; Position specific Link
   {
      if (linkTxt[3] != "" && linkTxt[4] != "") {
         linkArray.InsertAt(linkTxt[2],[linkTxt[3],linkTxt[4]]) ; Insert at position
      } else if (linkTxt[3] == "") {
         if (linkTxt[4]=="") {
            linkArray.InsertAt(linkTxt[2],[linkTxt[3],linkTxt[4]]) 
         } else {
            linkArray[linkTxt[2],2]:=linkTxt[4] ; Update URL at position
            MsgBox % linkArray[linkTxt[2],1] . " now links to " . linkArray[linkTxt[2],2]
         }

      ;} else if (linkTxt[4] == "" && SubStr(UsrIn,0) == "+") {
      } else if (linkTxt[4] == "") {
         oldLabel:=linkArray[linkTxt[2],1]
         linkArray[linkTxt[2],1]:=linkTxt[3] ; Update label at position
         MsgBox % oldLabel . " is now labelled " . linkArray[linkTxt[2],1]
      }
   } else { ; Unspecified position number
      if (linkTxt[2] != "" && linkTxt[3] != "") {
         linkArray.InsertAt(1,[linkTxt[2],linkTxt[3]]) ; Insert in first position
      } else if (linkTxt[2] == "") {
         linkArray[Link,2]:=linkTxt[3] ; Update URL of current
         MsgBox % linkArray[Link,1] . " now links to " . linkArray[Link,2]
      ;} else if (linkTxt[3] == "" && SubStr(UsrIn,0) == "+") {
      } else if (linkTxt[3] == "") {
         oldLabel:=linkArray[Link,1]
         linkArray[Link,1]:=linkTxt[2] ; Update label of current
         MsgBox % oldLabel . " is now labelled " . linkArray[Link,1]
      }
   }
   
   GoSub, UpdateLinkList

   ;MsgBox % appendTxt
return

RemoveLinks:
   Gui, Submit, noHide
   removeTxt:=StrSplit(UsrIn,"-",,3)
   linkString=
   removeTxtIndex:=removeTxt[2]
   ;Sample: 1DELETE-2LinkIndex
   if (removeTxt[2] ~= "i)cat.{0,5}") { ; remove cateogry
      MsgBox, 260, Continue?, Do you want to delete all of the data in %index%?
      ifMsgBox, No
         return
      IfMSgBox, Yes
      {
         Loop % HSR_Array.MaxIndex()
         {
            ;match := InStr(index,HSR_Array[A_Index,1])
            ;MsgBox % HSR_Array[xPos,2] . "`n" . index
            if (index==HSR_Array[A_Index,1]) {
               HSR_Array.RemoveAt(A_Index)
               linkArray:=[]
               linkString=
               ;MsgBox % linkString
               break
            }
         }
         mouseKeep:=1
         GoSub, UpdateLinkList
         GoSub, DestroyGui
         GoSub, BuildMainGUI
         mouseKeep:=0
      }
      ;GoSub, DestroyGui
      ;return
   } else if (removeTxt[2] != "" && removeTxt[3] != "") { ; Remove list of links
      numRemove := max(removeTxt[2],removeTxt[3])-min(removeTxt[2],removeTxt[3]) + 1
      ;MsgBox % numRemove
      start:=min(removeTxt[2],removeTxt[3])
      i:=start
      chckList := 
      Loop, 11
      {
         if (A_Index<=10) {
            chckList .= linkArray[i,1] . "`n"
            i++
         } else {
            andMore:=numRemove-10
            chckList .= "and " . andMore . " others"
         }
      }
      
      MsgBox, 260, Continue?, % "Do you want to remove the links`n" . RTrim(chckList,"`n") . "?"
      IfMsgBox, No
         Return
      IfMsgBox, Yes
      {
         Loop, %numRemove%
         {
            linkArray.RemoveAt(start)
         }
      }
   } else if (removeTxt[2] == "") { ; Remove current link
      MsgBox, 260, Continue?, % "Do you want to remove the link " . Trim(linkArray[Link,1]) . "?"
      IfMsgBox, No
         Return
      IfMsgBox, Yes
      {
         linkArray.RemoveAt(Link)
      }
   } else { ; Remove specified link
      MsgBox, 260, Continue?, % "Do you want to remove the link " . Trim(linkArray[removeTxt[2],1]) . "?"
      IfMsgBox, No
         Return
      IfMsgBox, Yes
      {
         linkArray.RemoveAt(removeTxt[2])
      }
   }

   GoSub, UpdateLinkList
return

ReorderLinks:
   Gui, Submit, noHide
   if (instr(UsrIn, "~"))
      swapTxt:=StrSplit(UsrIn,"~",,2)
   else if (instr(UsrIn, "%"))
      swapTxt:=StrSplit(UsrIn,"`%",,2)
   linkString=
   swap:=[]
   swap:=linkArray[swapTxt[1]]
   linkArray.RemoveAt(swapTxt[1])
   linkArray.InsertAt(swapTxt[2],[swap[1],swap[2]])
   GoSub, UpdateLinkList
return

UpdateLinkList:
   Loop % linkArray.MaxIndex()
   {
      linkString .= "[" . linkArray[A_Index,1] . "](" . linkArray[A_Index,2] . ")"
   }
   
   Loop % HSR_Array.MaxIndex()
   {
      ;match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[xPos,2] . "`n" . index
      if (index==HSR_Array[A_Index,1]) {
         HSR_Array[A_Index,2]:=linkString
         ;MsgBox % linkString
         break
      }
   }

   GoSub, SaveHSR
return

FavButtonClick:
   FavButton(A_ThisMenuItemPos)
Return

FavButton(val)
{
   IniRead, URL, HS_Settings.ini, Favorite Links, FavLink%val%, %A_Space%
   if(URL == "")
      MsgBox, % "Favorite " . val . " is undefined."
   else {
      global searchQuery := URL
      GoSub, GoogleSearch
      GoSub, DestroyGui
   }
}

EditFav:
   Menu, MainMenu, Delete
   indx:=SubStr(UsrIn,1,1)
   val := StrSplit(UsrIn,">",,3)
   newLnk := val[3]
   if (val[2] != "" || val[3] != "") {
      newLbl := "&" . indx . " " . val[2]
      if (val[2] != ""){
         if (val[3] = "")
            MsgBox,,Favorite Reassigned, % "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&" . indx . " ") . "."
         else
            MsgBox,,Favorite Reassigned, % "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&" . indx . " ") . " and links to " . newLnk . "."
      } else
         MsgBox,,Favorite Reassigned, % "Favorite " . indx . " now links to " . newLnk . "."
   } else {
      newLbl:=""
      MsgBox,,Favorite Erased, % "Favorite " . indx . " has been removed."
   }
   if (val[2] = "" && val[3] = "" || val[2] != "")
      IniWrite, %newLbl%, HS_Settings.ini, Favorite Labels, Favorite%indx%
   if (val[2] = "" && val[3] = "" || val[3] != "")
      IniWrite, %newLnk%, HS_Settings.ini, Favorite Links, FavLink%indx%
   GoSub, DestroyGui
return

EditSettings:
   search:=StrSplit(UsrIn,">",,3)
   if (search[2] ~= "i)d.{0,1}rk") {
      IniWrite, 1, HS_Settings.ini, Settings, DkMd
   } else if (search[2] ~= "i)light") {
      IniWrite, 0, HS_Settings.ini, Settings, DkMd
   } else if (search[2] ~= "i)min") {
      IniWrite, 1, HS_Settings.ini, Settings, MinMode
   } else if (search[2] ~= "i)max") {
      IniWrite, 0, HS_Settings.ini, Settings, MinMode
   } else if (search[2] ~= "i)j.mp") {
      if (search[3]~="i)on"){
         IniWrite, 1, HS_Settings.ini, Settings, jump
         IniRead, jump, HS_Settings.ini, Settings, jump
      } else if (search[3]~="i)off") {
         IniWrite, 0, HS_Settings.ini, Settings, jump
         IniRead, jump, HS_Settings.ini, Settings, jump
      }
   } else if (search[2] ~= "i)s.{0,2}rch") {
      if (search[3] ~= "i)D.{0,4}D.{0,4}G.{0,1}") {
         IniRead, DDG, HS_Settings.ini, Search Engine, DuckDuckGo
         searchEngine:="""" . DDG . """"
         IniWrite, %searchEngine%, HS_Settings.ini, Search Engine, Default
         MsgBox, Your default search engine is now set to Duck Duck Go.
      } else if (search[3] ~= "i)G.{0,2}gl.{0,1}") {
         IniRead, Google, HS_Settings.ini, Search Engine, Google
         searchEngine:="""" . Google . """"
         IniWrite, %searchEngine%, HS_Settings.ini, Search Engine, Default
         MsgBox, Your default search engine is now set to Google.
      } else if (search[3] ~= "i)B.{0,1}ng") {
         IniRead, Bing, HS_Settings.ini, Search Engine, Bing
         searchEngine:="""" . Bing . """"
         IniWrite, %searchEngine%, HS_Settings.ini, Search Engine, Default
         MsgBox, Your default search engine is now set to Bing.
      } else
         MsgBox, Invalid search engine. Available options:`n-Google`n-Duck Duck Go`n-Bing
   } else if (search[2] ~= "i)h.{0,2}k.{0,2}1") {
      failsafe:=GUIHotkey
      usrHotkey:=search[3]
      search[3] := StrReplace(search[3], "win", "#")
      search[3] := StrReplace(search[3], "ctrl", "^")
      search[3] := StrReplace(search[3], "alt", "!")
      search[3] := StrReplace(search[3], "+", "")
      search[3] := StrReplace(search[3], "=", "+")
      search[3] := StrReplace(search[3], "shift", "+")
      newHotkey1:=search[3]
      IniWrite, %newHotkey1%, HS_Settings.ini, Settings, GUIHotkey
      ;IniRead, GUIHotkey, HS_Settings.ini, Settings, GUIHotkey
      Hotkey, %GUIHotkey%, off
      GUIHotkey:=newHotkey1
      Hotkey, %GUIHotkey%, LoadGUI, UseErrorLevel
      if (ErrorLevel) {
         MsgBox, Invalid Hotkey
         IniWrite, %failsafe%, HS_Settings.ini, Settings, GUIHotkey
         GUIHotkey:=failsafe
         Hotkey, %GUIHotkey%, searchHighlight
      }
      Hotkey, %GUIHotkey%, on
      MsgBox % "Hotkey 1 has been set to " . usrHotkey
   } else if (search[2] ~= "i)h.{0,2}k.{0,2}2") {
      failsafe:=hiHotkey
      usrHotkey:=search[3]
      search[3] := StrReplace(search[3], "win", "#")
      search[3] := StrReplace(search[3], "ctrl", "^")
      search[3] := StrReplace(search[3], "alt", "!")
      search[3] := StrReplace(search[3], "+", "")
      search[3] := StrReplace(search[3], "=", "+")
      search[3] := StrReplace(search[3], "shift", "+")
      newHotkey2:=search[3]
      IniWrite, %newHotkey2%, HS_Settings.ini, Settings, HighlightHotkey
      ;IniRead, hiHotkey, HS_Settings.ini, Settings, HighlightHotkey
      Hotkey, %hiHotkey%, off
      hiHotkey:=newHotkey2
      Hotkey, %hiHotkey%, searchHighlight, UseErrorLevel
      if (ErrorLevel) {
         MsgBox, Invalid Hotkey
         IniWrite, %failsafe%, HS_Settings.ini, Settings, HighlightHotkey
         hiHotkey:=failsafe
         Hotkey, %hiHotkey%, searchHighlight
      }
      Hotkey, %hiHotkey%, on
      MsgBox % "Hotkey 2 has been set to " . usrHotkey
   } else if (search[2] ~= "i)trans.{0,7}") {
      transVal := search[3]
      if transVal is integer
      {
         transPercent := Round((transVal / 100) * 255)
         IniWrite, %transPercent%, HS_Settings.ini, Settings, Trans
         ;MsgBox, % "Transparency is set to " . transVal . "%"
      } else
         MsgBox, Value should be a number.
   } else {
      MsgBox, Invalid settings option.
   }
return

SetTheme:
   IniRead, themeSel, HS_Settings.ini, Settings, DkMd
   IniRead, transSel, HS_Settings.ini, Settings, Trans
   if (themeSel = 1) {
      Gui, Font, cWhite
      Gui, Color, 404040, 1A1A1A
      Menu, MainMenu, Color, 808080
      Gui +LastFound
   } else {
      Gui, Font, cBlack
      GuiControl, Font, Submit
      Gui, Color, Silver, White
      Menu, MainMenu, Color, White
      Gui +LastFound
   }
   WinSet, Transparent, %transSel%
return

CheckSettings:
   IniRead, sections, HS_Settings.ini
   sectionsArray:=StrSplit(sections,"`n")
   lastSection:=sectionsArray[sectionsArray.maxIndex()]
   if (lastSection == "Theme") {
      IniRead, themeContent, HS_Settings.ini, Theme
      themeContent := "[Settings]`n" . themeContent
      IniDelete, HS_Settings.ini, Theme
      FileAppend, %themeContent%, HS_Settings.ini
   }
   IniRead, settingsContent, HS_Settings.ini, Settings
   settingsArray:=StrSplit(settingsContent,"`n")
   lastSetting:=settingsArray[settingsArray.maxIndex()]
   lastSettingArray:=StrSplit(lastSetting,"=")
   ;MsgBox % lastSettingArray[1]
   if (lastSettingArray[1]=="MinMode") {
      newSettings:="`nGUIHotkey=#Space`nHighlightHotkey=^#Space`nJump=1"
   } else if (lastSettingArray[1]=="HighlightHotkey") {
      newSettings:="`nJump=1"
   }
   FileAppend, %newSettings%, HS_Settings.ini
return

GenerateSettings:
   FileAppend,
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
Trans=230
MinMode=0
GUIHotkey=#Space
HighlightHotkey=^#Space
Jump=1
   ), HS_Settings.ini
return

GenerateHSR:
   FileAppend,
   (
"Index Label","[Link1 Label](Link1 URL)[Link2 Label](Link2 URL)..."
"*Quick Access","[Add a new link]()"
"* Quick Start Guide","[NAVIGATION REFERENCE]()[Type * to search the category index on the left]()[Tab between control windows]()[Press Enter after typing * to set focus to links]()[Use Enter or double click links to activate URL]()[ ]()[TEXT ENTRY REFERENCE]()[Edit Favorites - 'Favorite#>Label>URL']()[Add Index Category - 'Category Name+']()[Add link - '+Link Name+Link URL']()[Add at Position - '+Position#+Link Name+LinkURL']()[Remove Selected Link - 'Delete-']()[Remove at Position - 'Delete-Position#']()[Delete Category - 'Delete--']()[ ]()[SETTINGS]()[Min/Max Mode - 'Set>Min/Max']()[Dark/Light Mode - 'Set>Dark/Light']()[Transparency - 'Set>Transparency>Percentage']()[]()[CLICK HERE for full feature list & updates](https://github.com/JSSatchell/HyperSearch)"
   ), HSR_Master.csv
return

Help:
   Run, % "https://github.com/JSSatchell/HyperSearch"
   GoSub, DestroyGui
return

DestroyGui:
   Hotkey, %GUIHotkey%, LoadGUI
   GoSub, LocalHotkeysOff
   GuiControl,+AltSubmit,Index
   GUI, Submit
   lastIndex:=index
   HSR_String=
   HSR_Array=
   linkArray=
   Gui, Destroy
return

ExitApp:
   ExitApp
