Menu, Tray, Icon, shell32.dll, 15 ; Icon

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force

;;;;;USE DEFAULT BROWSER;;;;;
RegRead, ProgID, HKEY_CURRENT_USER, Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice, Progid
Browser := "iexplore.exe"
if (ProgID = "ChromeHTML")
   Browser := "chrome.exe"
if (ProgID = "FirefoxURL")
   Browser := "firefox.exe"

If !FileExist("HS_Settings.ini") {
   Gosub, GenerateSettings
}
IniRead, searchEngine, HS_Settings.ini, Search Engine, Default

If !FileExist("HSR_Master.csv") {
   GoSub, GenerateHSR
}
;FileRead, HSR_String, HSR_Master.csv

lastIndex:=1

;;;;;ENTER SEARCH TERMS;;;;;
#Space:: 
{ 
   IniRead, min, HS_Settings.ini, Theme, MinMode
   Hotkey, #Space, Off
   if (min == 1) {
      Gui Menu
      Gosub, LoadMenu
      GoSub, SetTheme
      Gui, Add, Edit, r1 vUsrIn x10 y10 w230 h30
      Gui, Add, Button, Default x250 y10 w50 h20 , Submit
      Gui -Caption
      Gui, Show, h40 w310, HyperSearch Lite
      Return
   } else {
      Gui Menu
      Gosub, LoadMenu
      GoSub, SetTheme
      HSR_Array:=[]
      indexList=
      indexArray:=[]
      FileRead, HSR_String, HSR_Master.csv
      ;indexIndex:=0
      ;MsgBox, %HSR_String%
      GoSub, BuildHSRArray
      Gui, Add, Edit, r1 vUsrIn x160 y10 w220 h30 gInputAlgorithm
      Gui, Add, ListBox, vIndex x10 y10 w140 h330 VScroll Choose1 sort -AltSubmit gLoadLinks, %indexList%
      Gui, Add, ListBox, vLink x160 y40 w280 h300 Choose1 AltSubmit gActivateLinks
      Gui, Add, Button, Default x390 y10 w50 h20 , Submit
      ; Generated UsrIng SmartGUI Creator 4.0
      Gui -Caption
      Gui, Show, h350 w450, HyperSearch
      Control, Choose, %lastIndex%, Listbox1
      Return
   }
   GuiClose:
   GuiEscape:
      GoSub, DestroyGui
   Return
}

;;;;;SEARCH FOR HIGHLIGHTED TEXT;;;;;
^#Space:: 
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

GoogleSearch:
;;;;;Adapted from this thread: https://www.autohotkey.com/board/topic/13404-google-search-on-highlighted-text/
   if (searchQuery != ""){
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
      searchQuery := linkArray[Link,2]
      ;MsgBox % linkArray[Link]
      GoSub, GoogleSearch
   } else {
      if (UsrIn != ""){
         if (UsrIn ~= "\*.*"){
            GuiControl, focus, Link
         } else if (RegExMatch(UsrIn, "^[1-9]>.*")){
            GoSub, EditFav
            GoSub, DestroyGui
         } else if (UsrIn ~= "i)^search>.*"){
            GoSub, EditSearch
            GoSub, DestroyGui
         } else if (UsrIn ~= "i)^set>.*"){
            GoSub, EditSettings
            GoSub, DestroyGui
         } else if (UsrIn ~= "\*.*"){
            GuiControl, focus, Link
         } else if (UsrIn ~= ".*\+.*"){
            GuiControl, -redraw, Link
            GoSub, AppendLinks
            GoSub, LoadLinks
            ;GoSub, BuildHSRArray
            GuiControl, +redraw, Link
            GuiControl,,UsrIn,
            ;GoSub, DestroyGui
         } else if (UsrIn ~= "i)Del.*\-.*"){
            GuiControl, -redraw, Link
            GoSub, RemoveLinks
            GoSub, LoadLinks
            ;GoSub, BuildHSRArray
            GuiControl, +redraw, Link
            GuiControl,,UsrIn,
            ;GoSub, DestroyGui
         } else {
            searchQuery = %UsrIn%
            GoSub, GoogleSearch
            GoSub, DestroyGui
         } 
      }
   }
   ;MsgBox, %UsrIn%

   ;GoSub, DestroyGui
Return

InputAlgorithm:
   Gui, Submit, noHide
   ;GuiControl, ChooseString, IndexList, |%UsrIn%
   if(RegExMatch(UsrIn, "^\*.*"))
   {
      GuiControl, ChooseString, index, % "|" . LTrim(UsrIn, "*")
   }
return

LoadMenu:
   Gui Menu
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
      match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[xPos,2] . "`n" . index
      if (match!=0) {
         linkCell .= HSR_Array[A_Index,2]
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
   GuiControl,,Link, |
   GuiControl,,Link, %labelList%
   GuiControl, Choose, Link, 1
return


ActivateLinks:
   Gui, Submit, noHide
   if (A_GuiEvent == "DoubleClick") {
      ;MsgBox % linkArray[Link,1]
      searchQuery := linkArray[Link,2]
      ;MsgBox % linkArray[Link]
      GoSub, GoogleSearch
   }
return

AppendLinks:
   Gui, Submit, noHide
   linkString=
   ; Sample: 1IndexLabel+2LinkName+3URL
   ; Sample: 1Buffer+2LinkIndex+3LinkName+4URL
   linkTxt:=StrSplit(UsrIn,"+",,4)
   linkIndex:=linkTxt[2]
   ;MsgBox % indexLabel . "`n" . linkIndex . "`n" . linkName . "`n" . linkURL
   if (linkTxt[1] != "") {
      if (linkTxt[2] != "" && linkTxt[3] != "") {
         appendTxt:="`n""" . linkTxt[1] . """," . """[" . linkTxt[2] . "](" . linkTxt[3] . ")"""
         FileAppend, %appendTxt%, HSR_Master.csv
         ;return
      } else if (linkTxt[2] == "" && linkTxt[3] == ""){
         appendTxt:="`n""" . linkTxt[1] . """," . """[ ]()"""
         FileAppend, %appendTxt%, HSR_Master.csv
         ;return
      }
      GoSub, DestroyGui
      return
   } else if linkIndex is integer
   {
      linkArray.InsertAt(linkTxt[2],[linkTxt[3],linkTxt[4]])
      Loop % linkArray.MaxIndex()
      {
         linkString .= "[" . linkArray[A_Index,1] . "](" . linkArray[A_Index,2] . ")"
      }
   } else {
      ;linkString=
      linkArray.InsertAt(1,[linkTxt[2],linkTxt[3]])
      Loop % linkArray.MaxIndex()
      {
         linkString .= "[" . linkArray[A_Index,1] . "](" . linkArray[A_Index,2] . ")"
      }
   }
   ;MsgBox % linkString
   Loop % HSR_Array.MaxIndex()
   {
      match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[xPos,2] . "`n" . index
      if (match!=0) {
         HSR_Array[A_Index,2]:=linkString
         ;MsgBox % linkString
         break
      }
   }
   GoSub, SaveHSR

   ;MsgBox % appendTxt
return

RemoveLinks:
   Gui, Submit, noHide
   removeTxt:=StrSplit(UsrIn,"-",,2)
   linkString=
   removeTxtIndex:=removeTxt[2]
   ;Sample: 1DELETE-2LinkIndex
   if (removeTxt[2] == "-") {
      MsgBox, 4, Continue?, Do you want to delete all of the data in %index%?
      ifMsgBox, No
         return
      IfMSgBox, Yes
      {
         Loop % HSR_Array.MaxIndex()
         {
            match := InStr(index,HSR_Array[A_Index,1])
            ;MsgBox % HSR_Array[xPos,2] . "`n" . index
            if (match!=0) {
               HSR_Array.RemoveAt(A_Index)
               ;MsgBox % linkString
               break
            }
         }
      }
      ;GoSub, DestroyGui
      ;return
   } else if (removeTxt[2] == "") {
      MsgBox, 4, Continue?, % "Do you want to remove the link " . linkArray[Link,1] . "?"
      IfMsgBox, No
         Return
      IfMsgBox, Yes
      {
         linkArray.RemoveAt(Link)
         Loop % linkArray.MaxIndex()
         {
            linkString .= "[" . linkArray[A_Index,1] . "](" . linkArray[A_Index,2] . ")"
         }
      }
   } else if removeTxtIndex is integer
   {
      MsgBox, 4, Continue?, % "Do you want to remove the link " . linkArray[removeTxt[2],1] . "?"
      IfMsgBox, No
         Return
      IfMsgBox, Yes
      {
         linkArray.RemoveAt(removeTxt[2])
         Loop % linkArray.MaxIndex()
         {
            linkString .= "[" . linkArray[A_Index,1] . "](" . linkArray[A_Index,2] . ")"
         }
      }
   } ;else 
   ;MsgBox % linkString
   Loop % HSR_Array.MaxIndex()
   {
      match := InStr(index,HSR_Array[A_Index,1])
      ;MsgBox % HSR_Array[xPos,2] . "`n" . index
      if (match!=0) {
         HSR_Array[A_Index,2]:=linkString
         ;MsgBox % linkString
         break
      }
   }

   GoSub, SaveHSR
   if (removeTxt[2] == "-")
      GoSub, DestroyGui
return

BuildHSRArray:
   Loop, Parse, HSR_String, `n, `r ; Build HSR_Array
   {
      r:=A_Index ; Row number
      ;MsgBox, % A_LoopField
      Loop, Parse, A_LoopField, CSV
      {
         c:=A_Index ; Column number
         if (A_Index==1 && r>1) ; Only search first column
         {
            dup := InStr(indexList,A_LoopField) ; Detect duplicates
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

EditSearch:
   search:=StrSplit(UsrIn,">",,2)
   if (search[2] ~= "i)Duck.*Duck.*Go") {
      IniRead, DDG, HS_Settings.ini, Search Engine, DuckDuckGo
      searchEngine:="""" . DDG . """"
      IniWrite, %searchEngine%, HS_Settings.ini, Search Engine, Default
      MsgBox, Your default search engine is now set to Duck Duck Go.
   } else if (search[2] ~= "i)Google") {
      IniRead, Google, HS_Settings.ini, Search Engine, Google
      searchEngine:="""" . Google . """"
      IniWrite, %searchEngine%, HS_Settings.ini, Search Engine, Default
      MsgBox, Your default search engine is now set to Google.
   } else if (search[2] ~= "i)Bing") {
      IniRead, Bing, HS_Settings.ini, Search Engine, Bing
      searchEngine:="""" . Bing . """"
      IniWrite, %searchEngine%, HS_Settings.ini, Search Engine, Default
      MsgBox, Your default search engine is now set to Bing.
   } else
      MsgBox, Invalid search engine. Available options:`n-Google`n-Duck Duck Go`n-Bing
return

EditSettings:
   search:=StrSplit(UsrIn,">",,3)
   if (search[2] ~= "i)d.rk") {
      IniWrite, 1, HS_Settings.ini, Theme, DkMd
      MsgBox, Dark theme applied.
   } else if (search[2] ~= "i)light") {
      IniWrite, 0, HS_Settings.ini, Theme, DkMd
      MsgBox, Light theme applied.
   } else if (search[2] ~= "i)min") {
      IniWrite, 1, HS_Settings.ini, Theme, MinMode
      MsgBox, Min mode applied.
   } else if (search[2] ~= "i)max") {
      IniWrite, 0, HS_Settings.ini, Theme, MinMode
      MsgBox, Max mode applied.
   } else if (search[2] ~= "i)trans.*") {
      transVal := search[3]
      if transVal is integer
      {
         transPercent := Round((transVal / 100) * 255)
         IniWrite, %transPercent%, HS_Settings.ini, Theme, Trans
         MsgBox, % "Transparency is set to " . transVal . "%"
      } else
         MsgBox, Value should be a number between 1-255.
   }
return

SetTheme:
   IniRead, themeSel, HS_Settings.ini, Theme, DkMd
   IniRead, transSel, HS_Settings.ini, Theme, Trans
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

[Theme]
DkMd=1
Trans=200
   ), HS_Settings.ini
return

GenerateHSR:
   FileAppend,
   (
"Index Label","[Link1 Label](Link1 URL)[Link2 Label](Link2 URL)..."
"Quick Start Guide","[NAVIGATION REFERENCE]()[Type * to search the category index on the left]()[Tab between the various windows]()[Press Enter after typing * to set focus to links]()[Use Enter or double click links to activate URL]()[ ]()[TEXT ENTRY REFERENCE]()[Add Index Category - 'Category Name+']()[Add link - '+Link Name+Link URL']()[Add at Position - '+Position#+Link Name+LinkURL']()[Remove Selected Link - 'Delete-']()[Remove at Position - 'Delete-Position#']()[Delete Category - 'Delete--']()[ ]()[CLICK HERE for the latest updates](https://github.com/JSSatchell/HyperSearch)"
   ), HSR_Master.csv
return

Help:
   Run, % "https://github.com/JSSatchell/HyperSearch"
   GoSub, DestroyGui
return

DestroyGui:
   Hotkey, #Space, On
   GuiControl,+AltSubmit,Index
   GuiControlGet,lastIndex,,Index
   HSR_String=
   HSR_Array=
   linkArray=
   Gui, Destroy
return

ExitApp:
   ExitApp
