@echo off
chcp 65001 >nul
title Instalador ManteniPro
setlocal
set "SRC=%~dp0"
set "DEST=%LOCALAPPDATA%\ManteniPro"
echo ==========================================
echo    INSTALADOR - ManteniPro v2.0
echo    Ferreteria Quilvio
echo ==========================================
if not exist "%SRC%index.html" (
  echo [ERROR] Extraiga primero el ZIP y ejecute INSTALAR.bat desde la carpeta extraida.
  pause
  exit /b 1
)
echo [1/3] Copiando archivos a %DEST% ...
if not exist "%DEST%" mkdir "%DEST%"
xcopy "%SRC%*" "%DEST%\" /E /I /Y /Q >nul
echo [2/3] Creando accesos directos ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$w=New-Object -ComObject WScript.Shell;" ^
 "foreach($d in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('Programs'))){$s=$w.CreateShortcut($d+'\ManteniPro.lnk');$s.TargetPath='%DEST%\index.html';$s.IconLocation='%DEST%\icons\ManteniPro.ico';$s.Description='ManteniPro - Ferreteria Quilvio';$s.Save()}"
echo [3/3] Verificando ...
if exist "%DEST%\index.html" (echo     OK  Programa instalado) else (echo     FALLA)
echo.
echo  Abra ManteniPro e ingrese la URL y clave de Supabase (ver LEEME.txt).
start "" "%DEST%\index.html"
pause
endlocal
