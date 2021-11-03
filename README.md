# ftt
Description: First made by iPadkid358 - then updated by myself. Change Flex 3 patches into Theos projects using simple terminal commands. 

Use 'ftt -?' For a full list of options.    

Flex 3 beta repo - http://getdelta.co     

Original flex to theos coding I found :https://github.com/ipadkid358/FlexToTheos


DIFFERENCES BETWEEN FLEX TO THEOS FROM IPADKID358 AND MINE

V0.3.8 - I fixed the following bugs that were present in ipadkid358's version of flex to theos, but I hadn't gotten around to fixing until now

Fixed a bug that would try to return %orig; on a void method

If the output folder already exists, it will change the number on the end instead of failing to convert the project from flex to theos

Ability to set FINALPACKAGE: && DEBUG:  automatically when generating the makefile.

Added ability to convert ALL flex patches to theos code projects with one command (ftt -z)


----------------------------
PAST FLEX TO THEOS UPDATES

Fix bug that would add an extra character between the return value, causing the project not to make properly
-  (bool)  <- two characters

Added the ability to make the deb straight from flex to theos terminal output (ftt -m)

I have ftt -g hooked to some of my personal flex patches

Added a preference bundle which allows the user to set custom arm support for their deb as well as customize the developers name / email and bundle name

Added the ability to add a description to your patch straight from the terminal while using ftt

Added ability to automatically name the folder after the flex patch you're making (ftt -a)