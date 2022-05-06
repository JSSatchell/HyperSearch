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
   numTabs = 1
   HSR_Array:=[]
   index=
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
            dup := InStr(index,A_LoopField) ; Detect duplicates
            if (dup==0){
               index .= A_LoopField . "|" ; Build index list for listbox
               numTabs++
            }
         }
         HSR_Array[r,c]:=A_LoopField
         ;MsgBox, % r . "`n" . c
         ;MsgBox, % HSR_Array[r,c] . "`n" . r . ", " . c
      }
   }
   Gui, Add, Edit, r1 vUsrIn x10 y10 w230 h30 gInputAlgorithm
   Gui, Add, ListBox, vIndexList x310 y10 w140 h340 Choose1 gMatchTab, %index%
   Gui, Add, Tab3, vTabSet x10 y40 w290 h310 -wrap gMatchIndex, %index%
   currentTab=1
   while (currentTab <= numTabs)
   {
      subCat=
      item=
      ; WIP Load subcategories into left list
      ;while ()
      Gui, Tab, %currentTab%
      Gui, Add, ListBox, x20 y65 w135 h280 , %subCat%
      Gui, Add, ListBox, x155 y65 w135 h280 , %item%
      ;Gui, Add, UpDown, x262 y109 w20 h230 , UpDown
      currentTab++
   }
   Gui, Tab
   Gui, Add, Button, Default x250 y10 w50 h20 , Submit
    ; Generated UsrIng SmartGUI Creator 4.0
   Gui -Caption
   Gui, Show, h379 w460, HyperSearch
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

;;;;;Adapted from this thread: https://www.autohotkey.com/board/topic/13404-google-search-on-highlighted-text/
GoogleSearch:
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
   GuiControl, ChooseString, TabSet, %indexList%
Return

MatchIndex:
   Gui, Submit, noHide
   ;MsgBox, You selected %indexList%
   GuiControl, ChooseString, IndexList, %TabSet%
Return

ButtonSubmit:
   Gui, Submit
   ;MsgBox, %UsrIn%
   if (UsrIn != ""){
      if (RegExMatch(UsrIn, "^[1-9]>.*")){
         GoSub, EditFav
      } else if (UsrIn ~= "i)^search>.*"){
         GoSub, EditSearch
      } else if (UsrIn ~= "i)^set>.*"){
         GoSub, EditSettings
      } else {
      searchQuery = %UsrIn%
      GoSub, GoogleSearch
      } 
   }
   GoSub, DestroyGui
Return

InputAlgorithm:
   Gui, Submit, noHide
   ;GuiControl, ChooseString, IndexList, |%UsrIn%
   if(RegExMatch(UsrIn, "^\*.*"))
   {
      ;Input, inputTest, L5 V, {tab}
      GuiControl, ChooseString, IndexList, % "|" . LTrim(UsrIn, "*")
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
