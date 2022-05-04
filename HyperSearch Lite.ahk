Menu, Tray, Icon, shell32.dll, 210 ; Magnifying Glass Icon

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force
SendMode Input

;;;;;Adapted from this thread: https://www.autohotkey.com/board/topic/13404-google-search-on-highlighted-text/

 
;;;;;ORIGINAL CODE FOR IE;;;;;
;RegRead, OutputVar, HKEY_CLASSES_ROOT, http\shell\open\command 
;StringReplace, OutputVar, OutputVar," 
;SplitPath, OutputVar,,OutDir,,OutNameNoExt, OutDrive 
;browser=%OutDir%\%OutNameNoExt%.exe 

;;;;;USE DEFAULT BROWSER;;;;;
RegRead, ProgID, HKEY_CURRENT_USER, Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice, Progid
Browser := "iexplore.exe"
if (ProgID = "ChromeHTML")
   Browser := "chrome.exe"
if (ProgID = "FirefoxURL")
   Browser := "firefox.exe"

searchEngine := "https://duckduckgo.com/?q="
;searchEngine := "http://www.google.com/search?hl=en&q="

;;;;;Insert favorite URLs here to call them with Alt shortcuts;;;;;
fav1Lbl = Fav &1
favURL1 = 

fav2Lbl = Fav &2
favURL2 = 

fav3Lbl = Fav &3
favURL3 = 

fav4Lbl = Fav &4
favURL4 = 

fav5Lbl = Fav &5
favURL5 = 

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
   Gui, Add, Edit, r1 vinitialQuery x10 y10 w230 h30
   Gui, Add, Button, Default x250 y10 w50 h20 , Search
   Gui, Add, Button, x10 y40 w50 h20 gFavButton1, %fav1Lbl%
   Gui, Add, Button, x70 y40 w50 h20 gFavButton2, %fav2Lbl%
   Gui, Add, Button, x130 y40 w50 h20 gFavButton3, %fav3Lbl%
   Gui, Add, Button, x190 y40 w50 h20 gFavButton4, %fav4Lbl%
   Gui, Add, Button, x250 y40 w50 h20 gFavButton5, %fav5Lbl%
   ; Generated using SmartGUI Creator 4.0
   Gui, Show, h70 w310, HyperSearch Lite
   Return

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

   ButtonSearch:
      Gui, Submit
      ;MsgBox, %initialQuery%
      if(initialQuery == "") {
         Hotkey, #Space, On
         Gui, Destroy
      } else{
         Hotkey, #Space, On
         Gui, Destroy
         searchQuery = %initialQuery%
         GoSub, GoogleSearch
         ;GoogleSearch(initialQuery)
      }
   Return

   GuiClose:
   GuiEscape:
   Gui, Destroy
   Hotkey, #Space, On
   Return
}

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

FavButton(val)
{
   if(favURL%val% == "")
      MsgBox, % "Favorite " . val . " is undefined."
   else {
      if InStr(favURL%val%, "https://")
         Run, % favURL%val%
      else {
         global searchQuery := favURL%val%
         GoSub, GoogleSearch         
      }
      Hotkey, #Space, On
      Gui, Destroy
   }
}
