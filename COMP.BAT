@echo off
goto start
:lamer
call reed
:start
pc
timer on /3 >nul
echo master srcfile: source/%1.pas
echo compiling...
tpc /B /EEXE /ISOURCE\INC /L /USOURCE /$D- /$G+ /OSOURCE\OBJ SOURCE\%1 >error
echo errorcheck...
exe\errcheck %1
if errorlevel 255 goto lamer
pklite exe\%1.exe >nul
echo lited %@filesize[exe\%1.exe,b] bytes
exe\litefix exe\%1.exe
echo process done.
timer /3
