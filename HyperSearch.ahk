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

;;;;;ENTER SEARCH TERMS;;;;;
#Space:: 
{ 
   Hotkey, #Space, Off
   Gui Menu
   Gosub, LoadMenu
   GoSub, SetTheme
   HSR_Array:=[]
   indexList=
   indexArray:=[]
   If FileExist("HSR_Master.csv")
      FileRead, HSR_String, HSR_Master.csv
   else {
      FileAppend,
      (
         "Category Name","SubCategory Name","Title","Links","URLs"
      ), HSR_Master.csv
   }
   ;MsgBox, %HSR_String%
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
         ;MsgBox, % r . "`n" . c
         ;MsgBox, % HSR_Array[r,c] . "`n" . r . ", " . c
      }
   }
   Gui, Add, Edit, r1 vUsrIn x160 y10 w230 h30 gInputAlgorithm
   Gui, Add, ListBox, vIndex x10 y10 w140 h340 VScroll Choose1 sort gLoadLinks, %indexList%
   /*
   Gui, Add, Tab3, vTabSet x160 y40 w290 h310 -wrap gMatchIndex, %indexList%
   currentTab=1
   while (currentTab <= indexArray.length())
   {
      currentSubCatList=
      subCatArray%currentTab%:=[]
      xPos=2
      while (HSR_Array[xPos,1] != "") { ; Run down full list
         dup := InStr(currentSubCatList,HSR_Array[xPos,2]) ; Detect duplicates
         if (dup==0 && indexArray[currentTab]==HSR_Array[xPos,1]){ ; Only add if category matches tab and not duplicate
            currentSubCatList .= HSR_Array[xPos,2] . "|" ; Build subcategory list for listbox
            subCatArray%currentTab%.Push(HSR_Array[xPos,2])
         }
         xPos++
      }
      Gui, Tab, %currentTab%
      Gui, Add, ListBox, vSubCat%currentTab% x170 y65 w135 h280 Choose1 gLoadItems, %currentSubCatList%
      Gui, Add, ListBox, vItem%currentTab% x305 y65 w135 h280 Choose1 gAppendLinks
      ;Gui, Add, UpDown, x262 y109 w20 h230 , UpDown
      currentTab++
   }
   Gui, Tab
   */
   Gui, Add, ListBox, vLink x160 y40 w290 h310 Choose1 AltSubmit gActivateLinks
   Gui, Add, Button, Default x400 y10 w50 h20 , Submit
    ; Generated UsrIng SmartGUI Creator 4.0
   Gui -Caption
   Gui, Show, h360 w460, HyperSearch
   Return

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
return

MatchTab:
   Gui, Submit, noHide
   ;MsgBox, You selected %indexList%
   GuiControl, ChooseString, TabSet, %Index%
Return

MatchIndex:
   Gui, Submit, noHide
   ;MsgBox, You selected %indexList%
   GuiControl, ChooseString, Index, %TabSet%
Return

ButtonSubmit:
   Gui, Submit, noHide
   GuiControlGet, activeControl, Focus
   ;MsgBox % activeControl
   if (activeControl == "Edit1") {
      if (UsrIn != ""){
         if (RegExMatch(UsrIn, "^[1-9]>.*")){
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
         } else {
         searchQuery = %UsrIn%
         GoSub, GoogleSearch
         GoSub, DestroyGui
         } 
      }
   } else if (activeControl == "ListBox2") {
      searchQuery := linkArray[Link]
      ;MsgBox % linkArray[Link]
      GoSub, GoogleSearch
      GoSub, DestroyGui
   }
   ;MsgBox, %UsrIn%

   ;GoSub, DestroyGui
Return

InputAlgorithm:
   Gui, Submit, noHide
   ;GuiControl, ChooseString, IndexList, |%UsrIn%
   if(RegExMatch(UsrIn, "^\*.*"))
   {
      ;Input, inputTest, L5 V, {tab}
      try GuiControl, ChooseString, Index, % "|" . LTrim(UsrIn, "*")
      catch {
         try {
            GuiControl, Choose, TabSet, 2 
            GuiControl, ChooseString, SubCat2, % "|" . LTrim(UsrIn, "*")
            GuiControl, Focus, SubCat2
            GuiControl, Focus, UsrIn
         }
         catch {
            try {
               GuiControl, Choose, TabSet, 2 
               GuiControl, ChooseString, Item2, % "|" . LTrim(UsrIn, "*")
               GuiControl, Focus, Item2
               GuiControl, Focus, UsrIn
            }
            catch {
               ;MsgBox, No result found
               return
            }
         }
      }
      ;MsgBox, % "UsrIn >" . LTrim(UsrIn, "*") . "`ninputTest >" . inputTest
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

LoadItems:
   Gui, Submit, noHide
   itemList=
   itemIndex:=SubStr(A_GuiControl, 0)
   ;indexUp:=itemIndex+1
   ;MsgBox % A_GuiControl . "`n" . itemIndex
   xPos=2
   while (HSR_Array[xPos,1] != "") { ; Run down full list
      dup := InStr(itemList,HSR_Array[xPos,3]) ; Detect duplicates
      if (dup==0 && HSR_Array[xPos,2]==subCat%itemIndex%){ ; Only add if category matches tab and not duplicate
         itemList .= HSR_Array[xPos,3] . "|" ; Build subcategory list for listbox
         itemArray.Push(HSR_Array[xPos,3])
      }
      xPos++
   }
   ;MsgBox % itemList
   ;GuiControl, -Redraw, Item2
   GuiControl,,Item%itemIndex%, |
   GuiControl,,Item%itemIndex%, %itemList%
   GuiControl, Focus, Item%itemIndex%
   ;GuiControl, +Redraw, Item2
return

LoadLinks:
   Gui, Submit, noHide
   linkCell=
   labelList=
   linkList=
   labelArray := []
   linkArray := []
   xPos=2
   while (HSR_Array[xPos,1] != "") { ; Run down full list
      match := InStr(HSR_Array[xPos,1],index)
      ;MsgBox % HSR_Array[xPos,2] . "`n" . index
      if (match!=0) {
         linkCell .= HSR_Array[xPos,2]
         break
      } else
         xPos++
   }
   newPos:=1
   while (RegExMatch(linkCell, "O)\[(.*?)]", currentLabel, StartingPos := newPos) != 0) {
      labelArray.push(currentLabel[1])
      labelList .= currentLabel[1] . "|"
      newPos := currentLabel.Pos(1) + 2
   }
   newPos:=1
   while (RegExMatch(linkCell, "O)\((.*?)\)", currentLink, StartingPos := newPos) != 0) {
      linkArray.push(currentLink[1])
      linkList .= currentLink[1] . "|"
      newPos := currentLink.Pos(1) + 2
   }
   ;MsgBox % "Labels:`n" . labelList . "`n`nLinks:`n" . linkList
   GuiControl,,Link, |
   GuiControl,,Link, %labelList%
   GuiControl, Choose, Link, 1
   ;GuiControl, Focus, Link
return


ActivateLinks:
   Gui, Submit, noHide
   if (A_GuiEvent == "DoubleClick") {
      searchQuery := linkArray[Link]
      ;MsgBox % linkArray[Link]
      GoSub, GoogleSearch
      GoSub, DestroyGui
   }
return

AppendLinks:

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

Help:
   Run, % "https://github.com/JSSatchell/HyperSearch"
   GoSub, DestroyGui
return

DestroyGui:
   Hotkey, #Space, On
   Gui, Destroy
return

ExitApp:
   ExitApp
