# ManageWU
Install Windows Update and Reboot or Install when you want

As I manage more than 160 PC's over 3 languages, and do not want to install WSUS server, I made this AutoIt script to force people do the Windows Update and allow user to install / shut down or reboot their PC at the time they want.

**YOU MUST MAKE SOME CHANGES IN YOUR SCRIPT TO BE ABLE TO USE IT**

As it is custom made you **must** do a few things:

1. Complie the ```Shutdown.au3```
2. Change the variable ```$sServerFile = '\\Path\to\my\Server\ManageWU.dat'``` in the ```Write-datFile.au3``` and compile it
3. Change the variable ```$sRootDwl = 'https://exemple.com/download'``` in the ```ManageWU.au3```  to your own website where the files will be downloaded (externaly)
4. Put on your website:
   - The ```ManageWU.dat``` (and change the settings according to your needs)
   - The ```ManageWU.exe``` (complied with your own settings)
   - All the msu files from the Windows Catalog
5. Optional: 
   - Change your Logo: ```MyBrand.bmp```
   
![mRemoteNG_GW6Z0xKO2f](https://user-images.githubusercontent.com/21193662/198076856-a49a9d34-ba38-4c27-a1a5-b32a4134c273.png)

## Running the program the firt time
Copy the program anywhere on your PC, then run it. It will automaticaly intall itself at the right place, and setup a schedule every day.

## From the schedule
The program will be executed and update itself if need it, run the update if build (PC) is different.
ManageWU can be run manualy.

Enjoy.

C.
