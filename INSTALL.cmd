@echo off
setlocal
title scientific-fa-translation-skill - one-click installer for Cline on Windows
echo.
echo   ===========================================================
echo    scientific-fa-translation-skill
echo    one-click installer for Cline on Windows
echo   ===========================================================
echo.
echo    English   -^>   scientific Persian, with a print-ready RTL PDF
echo.
echo    Installing:
echo      * the skill itself into %%USERPROFILE%%\.cline\skills\
echo      * Git Bash shims (google-chrome, poppler PATH, UTF-8 python)
echo      * python3.exe, poppler, Vazirmatn fonts
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-windows.ps1" %*
set RC=%ERRORLEVEL%
echo.
if "%RC%"=="0" (
  echo   ---------------------------------------------------------
  echo    INSTALLED SUCCESSFULLY
  echo.
  echo    1. Restart Cline once ^(user environment variables are
  echo       only inherited by new processes^).
  echo    2. In Cline chat type:  /scientific-fa-translation-skill
  echo       or write in Persian: "this PDF -> scientific Persian PDF"
  echo.
  echo    See README.md in this folder for details.
  echo   ---------------------------------------------------------
) else (
  echo   ---------------------------------------------------------
  echo    INSTALLER FAILED  ^(exit code %RC%^)
  echo    Read the messages above, then see README.md - Troubleshooting.
  echo   ---------------------------------------------------------
)
echo.
pause
exit /b %RC%
