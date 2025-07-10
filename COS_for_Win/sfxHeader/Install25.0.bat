@echo off
echo.
cd %~dp0
set ADMINISTRATORSGROUPNAME=
powershell -Command "$group = (Get-WmiObject -Class Win32_Group -Filter \"Domain='$env:computername' and SID='S-1-5-32-544'\").Name; $group | Out-File -FilePath ADMINISTRATORSGROUPNAME.txt -Encoding OEM"
set /P ADMINISTRATORSGROUPNAME=<%ADMINISTRATORSGROUPNAME.txt
del ADMINISTRATORSGROUPNAME.txt

chcp 936 >nul
title ChemDraw Applications ÆÆ½â°æ°²×°

net localgroup %ADMINISTRATORSGROUPNAME% | findstr /b /e /i /c:"%userdomain%\%username%" >nul
if %errorLevel% == 0 goto :AdminInstall

net localgroup %ADMINISTRATORSGROUPNAME% | findstr /b /e /i /c:"%username%" >nul
if %errorLevel% == 0 goto :AdminInstall

SET __COMPAT_LAYER=RunAsInvoker
echo [[1;36mINFO[0m] ÓÃ»§ÎÞ¹ÜÀíÔ±È¨ÏÞ£¬½«½öÎªµ±Ç°ÓÃ»§°²×°¡£
goto :Install

:AdminInstall
if "%1" == "ADMIN" (echo [[1;36mINFO[0m] ½«ÎªËùÓÐÓÃ»§°²×°¡£& goto :Install)

echo [[1;36mINFO[0m] ÓÃ»§¾ßÓÐ¹ÜÀíÔ±È¨ÏÞ¡£°´ Y ÎªËùÓÐÓÃ»§°²×°£¨Ä¬ÈÏ£©£¬»ò°´ N ½öÎªµ±Ç°ÓÃ»§°²×°¡£ [[1;33mY/N[0m]^?
choice /N /T 10 /D y >nul
if %errorLevel% == 2 (goto :UserInstall)

powershell -Command "Start-Process -FilePath \"%~f0\" -ArgumentList \"ADMIN\" -Verb RunAs" 2>nul
if %errorLevel% == 0 (exit /b)

:UserInstall
SET __COMPAT_LAYER=RunAsInvoker
echo [[1;36mINFO[0m] ½«½öÎªµ±Ç°ÓÃ»§°²×°¡£

:Install
echo [[1;36mINFO[0m] ÕýÔÚ°²×° ChemDraw ¡­
Install.exe 2>nul
if %errorLevel% == 0 (echo [[1;36mINFO[0m] Íê³É°²×° ChemDraw£¬ÇëÉÔºò¡­
rem Give time to allow Install.exe to close
timeout /t 1 /nobreak >nul) else (echo [[1;31mERROR[0m] ÎÞ·¨°²×° ChemDraw¡£)

ren Install.ini Install1.ini 2>nul && ren Install2.ini Install.ini 2>nul
if NOT %errorLevel% == 0 (ren Install1.ini Install.ini 2>nul
echo [[1;31mERROR[0m] ÎÞ·¨°²×° ChemDraw Applications¡£
goto :next)

echo [[1;36mINFO[0m] ÕýÔÚ°²×° ChemDraw Applications ¡­
Install.exe 2>nul
if %errorLevel% == 0 (echo [[1;36mINFO[0m] Íê³É°²×° ChemDraw Applications£¬ÇëÉÔºò¡­
rem Give time to allow Install.exe to close
timeout /t 1 /nobreak >nul) else (echo [[1;31mERROR[0m] ÎÞ·¨°²×° ChemDraw Applications¡£)
ren Install.ini Install2.ini 2>nul && ren Install1.ini Install.ini 2>nul

:next
echo [[1;36mINFO[0m] ¼´½«ÔËÐÐÆÆ½â¡£
COS_Win_Patch 2>nul
if NOT %errorLevel% == 0 (echo [[1;33mWARNING[0m] ²¹¶¡³ÌÐò¿ÉÄÜÎ´Õý³£Íê³É£¬ÈçÓÐÎÊÌâÇëÔÚÖ®ºóÊÖ¶¯ÔËÐÐ COS_Win_Patch.exe¡£
pause
goto :end)

echo [[1;36mINFO[0m] °²×°ÆÆ½âÍê³É£¬ÊÇ·ñÉ¾³ý´ËÎÄ¼þ¼Ð£¿ [[1;33mY/N[0m]^?
choice /N /T 10 /D y >nul
if %errorLevel% == 2 (goto :end)

cd ..
start /b "" timeout /t 1 /nobreak >nul & rd /S /Q "%~dp0" & exit
:end
