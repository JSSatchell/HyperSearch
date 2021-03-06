# HyperSearch
Instant internet search, minus the distractions.

In editor language: It's FX Console/Excalibur for the internet.

### GUIDE CONTENTS

 - [Overview](https://github.com/JSSatchell/HyperSearch#overview)
 - [General Usage](https://github.com/JSSatchell/HyperSearch#general-usage)
 - [Navigation](https://github.com/JSSatchell/HyperSearch#navigation)
 - [Adding & Removing Categories & Links](https://github.com/JSSatchell/HyperSearch#adding--removing-categories--links)
 - [Editing Category Names, Link Labels, and URLs](https://github.com/JSSatchell/HyperSearch#editing-category-names-link-labels-and-urls)
 - [Crosslinking](https://github.com/JSSatchell/HyperSearch#crosslinking)
 - [Update Favorites](https://github.com/JSSatchell/HyperSearch#update-favorites)
 - [Update the Settings](https://github.com/JSSatchell/HyperSearch#update-the-settings)

---

#### OVERVIEW

**Preview:**

![image](https://user-images.githubusercontent.com/99512204/170307230-564138b0-1e40-4a6b-a034-a20c347755da.png)

HyperSearch is a bookmark managing utility that focuses on speed and direct access to what your looking for without the fluff and distractions of the internet.

It also provides convenient hotkeys for searching any highlighted text as well as a search bar to search the internet before you've even opened your browser.

HyperSearch Lite is a streamlined version of the searchbar and favorites without the bookmark manager.

**Preview:**

![image](https://user-images.githubusercontent.com/99512204/170307480-cb98fd58-2e9d-4307-b294-ebc4d7541c55.png)

HyperSearch Lite is also built into HyperSearch and can be activated by typing `Set>Min`

    Set>Min

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### GENERAL USAGE 

Open the GUI with `Win`+`Space` or search any highlighted text with `Ctrl`+`Win`+`Space`. (These hotkeys can be reconfigured to user preference.)

Close the GUI with Escape or `Close Window` from the `X` menu.

The app will stay open in the system tray unless closed from the tray or via `Exit App` from the `X` menu.

When the app is launched for the first time it will create `HS_Settings.ini` and `HSR_Master.csv` sidecar files. If the .exe is moved the .ini and .csv files must stay in the same root folder as the .exe or the settings will be reset. Do not rename these files or new ones will be created the next time the app is launched and the app will be reset to it's default configuration.

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### NAVIGATION

Navigate the favorites menu easily with `Alt`+`1` - `9` or `Alt`+`X` for the exit menu.

Type in the search bar and press enter to search the internet via your default search engine (see changing the default search engine below)

Type a `Space` at the beginning of your search to search the index on the left instead

    _Category Name
    
If the search starts with a `Space`, pressing `Enter` will set the focus to the links window below the search bar. Pressing `Enter` again will activate the highlighted link.

If focus is on the search bar, `Tab` will first go to the index which can be navigated by pressing the letter corresponding to the first letter of the desired category. A second `Tab` will highlight the links window.

`Shift`+`A` and `Shift`+`D` will also toggle between the two listboxes, skipping the search bar.

If one of the listboxes is active, `Shift`+`W` and `Shift`+`S` will toggle the slection up and down, respectively.

[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)

---

#### ADDING & REMOVING CATEGORIES & LINKS

To add a category, type the category name and `+`

    Category Name+
    
To add a link to the current category, type `+` followed the name of the link followed by `+` followed by the URL. New links without a specified position will be added to the top of the links list

    +GMail+mail.google.com
    
_Note: Link names should not contain the characters_ `[` `]` `(` `)` _or_ `|`

To add a link at a specific position, type `+` followed by the position number followed by `+` followed by the link name followed by `+` followed by the URL

    +1+Calendar+calendar.google.com
    
To add a link at the bottom of the links list, substitute `v` for the position value

    +v+GDrive+drive.google.com
    
To move a link to a new position, type the starting position of the link, followed by `~` and the new positon of the link

    1~5

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
   
To set a new label for a favorite, simple omit the last `>`

    1>GMail

To set a new link for an existing favorite without updating the label, use `>>`

    1>>drive.google.com
    
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
    
To set the transparency, type `Transparency>` and enter a number between `1` - `100`. Default is 90%

    Set>Transparency>80
    
[^ TOP ^](https://github.com/JSSatchell/HyperSearch#hypersearch)
