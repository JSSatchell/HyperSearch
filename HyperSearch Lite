Menu, Tray, Icon, shell32.dll, 210 ; Magnifying Glass Icon

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


;;;;;Adapted from this thread: https://www.autohotkey.com/board/topic/13404-google-search-on-highlighted-text/

SendMode Input 
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

searchEngine := "https://duckduckgo.com/"

;;;;;Insert favorite URLs here to call them with Alt shortcuts;;;;;
favURL1 = 
favURL2 = 
favURL3 = 
favURL4 = 

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


;;;;;ENTER SEARCH TERMS;;;;;
#Space:: 
{ 
   Gui, Add, Edit, r1 vinitialQuery x10 y10 w180 h30
   Gui, Add, Button, Default x200 y10 w50 h20 , Search
   Gui, Add, Button, x10 y40 w50 h20 , Fav &1
   Gui, Add, Button, x70 y40 w50 h20 , Fav &2
   Gui, Add, Button, x130 y40 w50 h20 , Fav &3
   Gui, Add, Button, x190 y40 w50 h20 , Fav &4
   ; Generated using SmartGUI Creator 4.0
   Gui, Show, h70 w260, HyperSearch Lite
   Return

   ButtonFav1:
   if(favURL1 == "")
      MsgBox, Favorite 1 is undefined.
   else {
      Run, %favURL1%
      Gui, Destroy
   }
   Return

   ButtonFav2:
   if(favURL1 == "")
      MsgBox, Favorite 2 is undefined.
   else {
      Run, %favURL2%
      Gui, Destroy
   }
   Return

   ButtonFav3:
   if(favURL1 == "")
      MsgBox, Favorite 3 is undefined.
   else {
      Run, %favURL3%
      Gui, Destroy
   }
   Return

   ButtonFav4:
   if(favURL4 == "")
      MsgBox, Favorite 4 is undefined.
   else {
      Run, %favURL4%
      Gui, Destroy
   }
   Return

   ButtonSearch:
      Gui, Submit
      ;MsgBox, %initialQuery%
      if(initialQuery == "") {
         Gui, Destroy
      } else{
         Gui, Destroy
         searchQuery = %initialQuery%
         GoSub, GoogleSearch
      }
   Return

   GuiClose:
   GuiEscape:
   Gui, Destroy
   Return
}

GoogleSearch: 
   StringReplace, searchQuery, searchQuery, `r`n, %A_Space%, All 
   Loop 
   { 
      noExtraSpaces=1 
      StringLeft, leftMost, searchQuery, 1 
      IfInString, leftMost, %A_Space% 
      { 
         StringTrimLeft, searchQuery, searchQuery, 1 
         noExtraSpaces=0 
      } 
      StringRight, rightMost, searchQuery, 1 
      IfInString, rightMost, %A_Space% 
      { 
         StringTrimRight, searchQuery, searchQuery, 1 
         noExtraSpaces=0 
      } 
      If (noExtraSpaces=1) 
         break 
   } 
   StringReplace, searchQuery, searchQuery, \, `%5C, All 
   StringReplace, searchQuery, searchQuery, %A_Space%, +, All 
   StringReplace, searchQuery, searchQuery, `%, `%25, All 
   IfInString, searchQuery, . 
   { 
      IfInString, searchQuery, + 
         ;Run, %browser% http://www.google.com/search?hl=en&q=%searchQuery% 
		   ;Run, %browser% https://duckduckgo.com/?q=%searchQuery%
         Run, %browser% %searchEngine%?q=%searchQuery%
      else 
         Run, %browser% %searchQuery% 
   } 
   else 
      ;Run, %browser% http://www.google.com/search?hl=en&q=%searchQuery% 
	   ;Run, %browser% https://duckduckgo.com/?q=%searchQuery%
      Run, %browser% %searchEngine%?q=%searchQuery%
return
