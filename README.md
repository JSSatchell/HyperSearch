# HyperSearch
Instant internet search and shortcut management for hyperlinks and files.

### [DOWNLOAD](https://github.com/JSSatchell/HyperSearch/releases)  |  [QUICK START VIDEO](https://youtu.be/1HC9vhA5meY)

### GUIDE CONTENTS

 - [Overview](https://github.com/JSSatchell/HyperSearch#overview)
 - [General Usage](https://github.com/JSSatchell/HyperSearch#general-usage)
 - [Switching Between Web and File Mode](https://github.com/JSSatchell/HyperSearch#switching-search-mode)
 - [Navigation](https://github.com/JSSatchell/HyperSearch#navigation)
 - [Adding & Removing Categories & Links](https://github.com/JSSatchell/HyperSearch#adding--removing-categories--links)
 - [Editing Category Names, Link Labels, and URLs](https://github.com/JSSatchell/HyperSearch#editing-category-names-link-labels-and-urls)
 - [Crosslinking](https://github.com/JSSatchell/HyperSearch#crosslinking)
 - [Update Favorites](https://github.com/JSSatchell/HyperSearch#update-favorites)
 - [Load & Import](https://github.com/JSSatchell/HyperSearch#load--import)
 - [Export](https://github.com/JSSatchell/HyperSearch#export)
 - [Update the Settings](https://github.com/JSSatchell/HyperSearch#update-the-settings)

---

#### OVERVIEW

**Preview:**

![image](https://user-images.githubusercontent.com/99512204/170307230-564138b0-1e40-4a6b-a034-a20c347755da.png)

HyperSearch is a minimalist bookmark managing utility that focuses on speed and distraction-free access to user-defined web and file path shortcuts.

It provides customizable hotkeys for searching any highlighted text as well as a GUI search bar that can search both the internet and your personal index of link categories.

HyperSearch Lite is a streamlined version of the web searchbar and favorites without the bookmark manager.

**Preview:**

![image](https://user-images.githubusercontent.com/99512204/170307480-cb98fd58-2e9d-4307-b294-ebc4d7541c55.png)

Activate HyperSearch Lite by typing `Set>Min`

    Set>Min

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### GENERAL USAGE 

Open the GUI with `Win`+`Space` or search any highlighted text with `Ctrl`+`Win`+`Space`. (These hotkeys can be reconfigured to user preference.)

Close the GUI with `Escape` or `Close Window` from the `X` menu.

The app will stay open in the system tray unless closed from the tray or via `Exit App` from the `X` menu.

When the app is launched for the first time it will create `HS_Settings.ini` and `HSR_Master.csv` sidecar files. If the .exe is moved the .ini and .csv files must stay in the same root folder as the .exe or the settings will be reset. Do not rename these files or new ones will be created the next time the app is launched and the app will be reset to it's default configuration.

The `?` menu contains a link back to this guide, a link to the folder of the current repository file, and the active version number which directs to the folder of the application.

##### Switching Search Mode

Use the `!` in the top right to switch between `Web` mode and `File` mode. The current search mode will be indicated by the status bar in the bottom left.

In `Web` mode all links will be accessed via the default web browser and search engine, whereas in `File` mode "links" should be input as file paths and will be accessed via Windows Explorer.

_Note: Windows 11 allows for copying the file path of a selected file or folder via_ `Ctrl`+`Shift`+`C`_._

When switching to `File` mode for the first time, a dialog will prompt to enter a name for a new HFR file (HyperSearch File Repository). This will create a separate repository from the `HSR_Master.csv` file to be used in `File` mode.

The rest of this guide will refer to input items as "links" or "URLs," although the same methods can be used to input file or folder paths. Be sure that when inputting items, the link or file path is formatted appropriately for the current search mode.

Likewise, when loading and importing repositories, be sure that the new repository is formatted appropriately for the current search mode.

_Note: Favorites will remain consistent between_ `Web` _and_ `File` _mode and will always be accessed as web links. Also, the search bar will always send the search query to the web unless modifying the repository as indicated in the rest of this guide._

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### NAVIGATION

Navigate the favorites menu easily with `Alt`+`1` - `9` or `Alt`+`X` for the exit menu.

Type in the search bar and press enter to search the internet via your default search engine (see changing the default search engine below)

Type a `Space` at the beginning of your search to search the index on the left instead

    _Category Name
    
If the search starts with a `Space`, pressing `Enter` will set the focus to the links window below the search bar. Pressing `Enter` again will activate the highlighted link.

Type a `#` followed by a number to highlight the link in the specified position.

    #10

Type `#v` to highlight the last link in the current category.

    #v

`Alt`+`A` and `Alt`+`D` will also toggle between the two listboxes, skipping the search bar.

If one of the listboxes is active, `Alt`+`W` and `Alt`+`S` will toggle the slection up and down, respectively.

If the search bar is active, `Alt`+`S` or `Alt`+`W` will activate the links window and start cycling down through the links.

Also with the search bar active, `Alt`+`Q` will clear all of the current text so a new search can be started more quickly.

To pull the URL of the selected item into the edit bar, type `^` and press `Enter`. A link index can be specified after the `^` to pull that link's URL into the search bar.

    ^5

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### ADDING & REMOVING CATEGORIES & LINKS

To add a category, type the category name and `+`

    Category Name+
    
To add a link to the current category, type `+` followed the name of the link followed by `+` followed by the URL. New links without a specified position will be added to the top of the links list

    +GMail+mail.google.com
    
_Note: When adding a link or filename with a_ `+` _character, escape it by preceding it with a backtick._

To add a link at a specific position, type `+` followed by the position number followed by `+` followed by the link name followed by `+` followed by the URL

    +1+Calendar+calendar.google.com
    
To add a link at the bottom of the links list, substitute `v` for the position value

    +v+GDrive+drive.google.com
    
To move a link to a new position, type the starting position of the link, followed by `~` and the new position of the link

    1~5

To move a range of links to a new position, type the first position of the range followed by `-` and the last number of the range, followed by `~` and the new starting positon of the link range

    1-3~5

To remove the current link, type `Delete-` and select `Yes` on the prompt

    Delete-
    
To remove a link at a specific position, type `Delete-` followed by the position number and select `Yes` on the prompt

    Delete-1

To remove a sequential range of links, type `Delete-` followed by the first number of the range, then `-` and the last number of the range

    Delete-1-5

To remove the current category, type `Delete-` followed by `Category` and select `Yes` on the prompt

    Delete-Category

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### EDITING CATEGORY NAMES, LINK LABELS, AND URLs

To rename the current category, type the new category name followed by `++`

    New Category Name++
    
To relabel the current link, type `+` followed by the new label followed by `+`

    +New Link Label
    
To relabel a link at a specific position, precede the command with `+` and the desired position #

    +1+New Link Label
    
To reassign the URL of the current link, type `++` followed by the new URL

    ++New URL
    
To reassign a URL of a link at a specific position, precede the command with `+` and the desired position #

    +1++New URL

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### CROSSLINKING

To have a link activate a specific category in the index, encapsulate the exact text of the desired category with `<`...`>` and set the link URL to `*`

    +1+<Category Label>+*

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### UPDATE FAVORITES

To update favorites, type a number `1` - `9` and then `>` followed by your desired label name then `>` followed by the link URL. For example:
 
    1>GMail>mail.google.com
    
To clear a selection, type the number of the favorite followed by only `>`

    1>
   
To set a new label for a favorite, simply omit the last `>`

    1>GMail

To set a new link for an existing favorite without updating the label, use `>>`

    1>>drive.google.com
    
[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### LOAD & IMPORT

To load a repository other than the default HSR_Master.csv file, type `Load>` followed by the pathname of a .csv file that is formatted consistently with HyperSearch. If the file is in the same folder as the HyperSearch executable, only the filename need be typed.

    Load>C:\Users\username\Documents\HyperSearch\Repositories\MyCustomRepository.csv
    
To import bookmarks from Google Chrome, type `Import>` followed by the pathname of a .html file that has been generated by the "Export Bookmarks" function of Google Chrome. If the file is in the same folder as the HyperSearch executable, only the filename need be typed (with .html extension and case-sensitive spelling).

    Import>C:\Users\username\Documents\HyperSearch\Imports\bookmarks_m_d_yyyy.html
    
_NOTE: When importing from Chrome you will have the option to add the bookmarks to the exisiting repository or replace the existing repository with the bookmarks. If you choose to replace the existing repository all links will be permanently deleted. It is recommended to make a copy of the existing repository before choosing to replace it._
    
To import a HyperSearch category or full HyperSearch repository, type `Import>` followed by the pathname of a .csv file that is formatted consistently with HyperSearch. If the file is in the same folder as the HyperSearch executable, only the filename need be typed (with .csv extension and case-sensitive spelling).

    Import>C:\Users\username\Documents\HyperSearch\Imports\SharedLinks.csv

When importing a .csv, all links will be added to the current repository.

_NOTE: When adding new categories via .csv if any imported category has the same name as an existing category, the links from the new category will not be visible. To get around this, rename the exisiting category before or after the import and the new category and its corresponding links will be revealed._

To create a new repository with the default categories, type `New>` followed by the desired filename or path of the new repository.

    New>HSR_New.csv
    
_NOTE: If the new filename is the same as a file in the specified folder, the existing file will be loaded. If no filename is provided, the default name "HSR_Master.csv" will be used. If "HSR_Master.csv" already exists, it will be loaded._

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### EXPORT

To export the active category or full repository in a more accessible CSV file of hyperlinks, type `Export>` followed by either `Category` or `Repository`

    Export>Repository

To export the current category in a way that can be read and imported by the HyperSearch import function listed above, add `>HyperSearch`

    Export>Category>HyperSearch

A new .csv file with the name of either the current repository or the active category will be created in the same folder as the HyperSearch executable.

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### UPDATE THE SETTINGS

Begin the search with `Set>`

To update the search engine, type `Search>` and then either `Google`, `Bing`, or `DuckDuckGo`. DuckDuckGo is currently the default.
    
    Set>Search>Google

To edit the hotkeys, type `Hotkey1/2>` followed by your desired hotkey

For reference: `Hotkey1` opens the GUI, `Hotkey2` searches for highlighted text

    Set>Hotkey1>ctrl+space

To turn on/off window jumping, type `Jump>On/Off`

    Set>Jump>Off

To set the interface to the more streamlined one of HyperSearch Lite, type `Min`

    Set>Min
    
To return to the full HyperSearch interface, type `Max`

    Set>Max

To set the color mode, type either `Dark` or `Light`. Dark is the default

    Set>Light
    
To set the opacity, type `Opacity>` and enter a number between `1` - `100`. Default is 90%

    Set>Opacity>80
    
[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)
