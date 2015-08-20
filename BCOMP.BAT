@echo off
goto start
:lamer
call reed
:start
pc
timer on /3 >nul
echo master srcfile: source/%1.pas
echo compiling...
tpc /B /EEXE /ISOURCE\INC /L /USOURCE /$D- SOURCE\%1 >error
echo errorcheck...
exe\errcheck %1
if errorlevel 255 goto lamer
lzexe exe\%1.exe >nul
move %1.exe exe\%1.exe
set exesize=%@filesize[exe\%1.exe,b]
echo lited %exesize bytes
exe\litefix exe\%1.exe
echo process done.
