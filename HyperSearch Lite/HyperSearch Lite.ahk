Menu, Tray, Icon, shell32.dll, 210 ; Magnifying Glass Icon

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
SendMode Input

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
      ;GoogleSearch(clipboard)
   } 
   clipboard = %prevClipboard% 
   return 
}


;;;;;ENTER SEARCH TERMS;;;;;
#Space:: 
{ 
   Hotkey, #Space, Off
   Gui, Font, White
   Gui Menu
   Gosub, LoadMenu
   Gui, Add, Edit, r1 vUsrIn x10 y10 w230 h30 cWhite
   Gui, Add, Button, Default x250 y10 w50 h20 , Submit
   Gui -Caption
   Gui, Color, Gray, 161616
   Menu, MainMenu, Color, Silver
   Gui +LastFound
   WinSet, Transparent, 200
   Gui, Show, h40 w310, HyperSearch Lite
   Return

   GuiClose:
   GuiEscape:
      GoSub, DestroyGui
   Return
}

ButtonSubmit:
   Gui, Submit
   ;MsgBox, %UsrIn%
   if (UsrIn != ""){
      if (RegExMatch(UsrIn, "^[1-5]>.*")){
         GoSub, EditFav
      } else if (UsrIn ~= "i)^search>.*"){
         GoSub, EditSearch
      } else {
      ;MsgBox % searchEngine
      searchQuery = %UsrIn%
      GoSub, GoogleSearch
      ;GoogleSearch(UsrIn)
      } 
   }
   GoSub, DestroyGui
Return

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


FavButton1:
   FavButton(1)
Return

FavButton2:
   FavButton(2)
Return

FavButton3:
   FavButton(3)
Return

FavButton4:
   FavButton(4)
Return

FavButton5:
   FavButton(5)
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
   newLbl := "&" . indx . " " . val[2]
   newLnk := val[3]
   IniWrite, %newLbl%, HS_Settings.ini, Favorite Labels, Favorite%indx%
   IniWrite, %newLnk%, HS_Settings.ini, Favorite Links, FavLink%indx%
   MsgBox,,Favorite Reassigned, % "Favorite " . indx . " is now labelled " . LTrim(newLbl,"&") . " and links to " . newLnk
   GoSub, DestroyGui
return

EditSearch:
   search:=StrSplit(UsrIn,">",,2)
   ;Msgbox % search[2]
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
   } else
      MsgBox, Invalid search engine. Available options:`nGoogle`nDuck Duck Go
return

LoadMenu:
   Gui Menu
   i=1
   while(i<=5){
      IniRead, currentFav, HS_Settings.ini, Favorite Labels, Favorite%i%
      Menu, MainMenu, Add, %currentFav%, FavButton%i%
      i++
   }
   Menu, Exit, Add, Close Window, DestroyGui
   Menu, Exit, Add, Exit App, ExitApp
   Menu, MainMenu, Add, [&X], :Exit, +right
   Gui, Menu, MainMenu
return

GenerateSettings:
   FileAppend,
   (
[Search Engine]
Default="https://duckduckgo.com/?q="
DuckDuckGo="https://duckduckgo.com/?q="
Google="http://www.google.com/search?hl=en&q="

[Favorite Labels]
Favorite1=Fav &1
Favorite2=Fav &2
Favorite3=Fav &3
Favorite4=Fav &4
Favorite5=Fav &5

[Favorite Links]
FavLink1=
FavLink2=
FavLink3=
FavLink4=
FavLink5=

[Theme]
DkMd=1
Trans=200
   ), HS_Settings.ini
return

DestroyGui:
   Hotkey, #Space, On
   Gui, Destroy
return

ExitApp:
   ExitApp
