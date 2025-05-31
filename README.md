# LSD.COM-screensaver-memory-reclaim-network-block
LSD.COM screensaver memory reclaim network block
must rename file pointers in the files to match your actual system and where you place the files, 
furthermor for it to run as screensaver, you must disable the notification window that prompts running powershell (to execute the powershell  commands in it) . this is entirely still a work in progress, and is released early as a proof of concept. if you make it work for you, kudos. Also will remove the lockbits 8gb reserve when i have a chance. was attempting to have it clean unused memory while running screensaver but its not working as intended (need to access physical memore via dev tools and C++)       
if you do compile and run this code, know it will create a firewall rule that will block all traffic, it can be undone by running the unblock.ps1 or by opening firewall rules and disabling it.
https://www.youtube.com/watch?v=XjLs3o-X3E0
