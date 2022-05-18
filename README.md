# HyperSearch
Instant internet search, minus the distractions.

**PREVIEW**

![image](https://user-images.githubusercontent.com/99512204/168928729-1a696160-30fa-4657-a4bf-3b37fe9a349f.png)

HyperSearch is a bookmark managing utility that focuses on speed and direct access to what your looking for without the fluff and distractions of the internet.

It also provides convenient hotkeys for searching any highlighted text as well as a search bar to search the internet before you've even opened your browser.

HyperSearch Lite is a streamlined version of the searchbar and favorites without the bookmark manager.

**PREVIEW**

![image](https://user-images.githubusercontent.com/99512204/166970969-f181093f-1e91-4174-80d2-007b428868f4.png)

HyperSearch Lite is also built into HyperSearch and can be activated by typing "Set>Min"

    Set>Min

---

**GENERAL USAGE**

Open the GUI with Win + Space or search any highlighted text with Ctrl + Win + Space.

The app will stay open in the system tray unless closed from the tray or via "Exit App" from the "X" menu.

When the app is launched for the first time it will create HS_Settings.ini and HSR_Master.csv sidecar files. If the .exe is moved the .ini must stay in the same root folder or the settings will be reset. Do not rename these files or new ones will be created the next time the app is launced and settings will be reset to default.

---

**NAVIGATION**

Navigate the favorites menu easily with Alt + 1-9 or Alt + X for the exit menu.

Type in the search bar and press enter to search the internet via your default search engine (see changing the default search engine below)

Type * at the beginning of your search to search the index on the left instead

    *Category Name
    
If the search starts with * pressing Enter will set the focus to the links window below the search bar. Pressing Enter again will activate the highlighted link.

If focus is on the search bar, Tab will first go to the index which can be navigated by pressing the letter corresponding to the first letter of the desired category. A second Tab will highlight the links window.

---

**ADDING AND REMOVING CATEGORIES & LINKS**

To add a category, type the category name and "+"

    Category Name+
    
To add a link to the current category, type "+" followed the name of the link followed by "+" followed by the URL. New links without a specified position will be added to the top of the links list

    +GMail+mail.google.com
    
To add a link at a specific position, type "+" followed by the position number followed by "+" followed by the link name followed by "+" followed by the URL

    +1+Calendar+calendar.google.com
    
To add a link at the bottom of the links list, substitute "v" for the position value

    +v+GDrive+drive.google.com
    
To remove the current link, type "Delete-" and select "Yes" on the prompt

    Delete-
    
To remove a link at a specific position, type "Delete-" followed by the position number and select "Yes" on the prompt

    Delete-1

To remove the current category, type "Delete--" and select "Yes" on the prompt

    Delete--

---

**EDITING CATEGORY NAMES, LINK LABELS, AND URLs**

To rename the current category, type the new category name followed by "++"

    New Category Name++
    
To relabel the current link, type "+" followed by the new label followed by "+"

    +New Link Label+
    
To relabel a link at a specific position, precede the command with "+" and the desired position #

    +1+New Link Label+
    
To reassign the URL of the current link, type "++" followed by the new URL

    ++New URL
    
To reassign a URL of a link at a specific position, precede the command with "+" and the desired position #

    +1++New URL

---

**CROSSLINKING**

To have a link activate a specific category in the index, encapsulate the exact text of the desired category with "<>" and set the link URL to "*"

    +1+<Category Label>+*

---

**UPDATE FAVORITES**

To update favorites, type a number 1-9 and then ">" followed by your desired label name then ">" followed by the link URL. For example:
 
    1>GMail>mail.google.com
    
To clear a selection, type the number of the favorite followed by only ">"

    1>
   
To set a new label for a favorite, simple omit the last ">"

    1>GMail

To set a new link for an existing favorite without updating the label, use ">>"

    1>>drive.google.com
    
---

**CHANGE THE DEFAULT SEARCH ENGINE**

To update the search engine, type "Search>" and then either "Google", "Bing", or "DuckDuckGo". DuckDuckGo is currently the default.
    
    Search>Google

---

**UPDATE THE SETTINGS**

Beginthe search with "Set>"

To set the interface to the more streamlined one of HyperSearch Lite, type "Min"

    Set>Min
    
To return to the full HyperSearch interface, type "Max"

    Set>Max

To set the mode, type either "Dark" or "Light". Dark is the default

    Set>Light
    
To set the transparency, enter a number between 1-100. Default is 80%

    Set>Transparency>80
