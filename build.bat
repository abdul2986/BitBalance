@echo off

if not exist bin mkdir bin

C:\masm32\bin\ml.exe /c /coff src\main.asm
if errorlevel 1 goto error

C:\masm32\bin\link.exe /SUBSYSTEM:WINDOWS /OUT:bin\SentryOS.exe main.obj
if errorlevel 1 goto error

echo.
echo BUILD SUCCESSFUL
echo.

pause
exit

:error
echo.
echo BUILD FAILED
echo.

pause