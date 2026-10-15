@echo off
chcp 65001 >nul
title Instalador ManteniPro
setlocal
set "SRC=%~dp0"
set "DEST=%LOCALAPPDATA%\ManteniPro"

echo ==========================================
echo    INSTALADOR - ManteniPro
echo    Mantenimiento de Equipos
echo ==========================================
echo.

REM 1. Verificar que se ejecuta desde la carpeta extraida (no dentro del ZIP)
if not exist "%SRC%index.html" (
  echo [ERROR] No se encontro index.html junto a este instalador.
  echo Extraiga primero el ZIP: clic derecho ^> Extraer todo,
  echo y ejecute INSTALAR.bat desde la carpeta extraida.
  pause
  exit /b 1
)

REM 2. Copiar archivos
echo [1/4] Copiando archivos a %DEST% ...
if not exist "%DEST%" mkdir "%DEST%"
xcopy "%SRC%*" "%DEST%\" /E /I /Y /Q >nul
if errorlevel 1 (
  echo [ERROR] No se pudieron copiar los archivos.
  pause
  exit /b 1
)

REM 3. Acceso directo en el Escritorio
echo [2/4] Creando acceso directo en el Escritorio ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$w=New-Object -ComObject WScript.Shell;" ^
 "$s=$w.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\ManteniPro.lnk');" ^
 "$s.TargetPath='%DEST%\index.html';$s.IconLocation='%DEST%\icons\ManteniPro.ico';$s.Description='ManteniPro - Mantenimiento de Equipos';$s.Save()"

REM 4. Acceso directo en el Menu Inicio
echo [3/4] Agregando al Menu Inicio ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$w=New-Object -ComObject WScript.Shell;" ^
 "$s=$w.CreateShortcut([Environment]::GetFolderPath('Programs')+'\ManteniPro.lnk');" ^
 "$s.TargetPath='%DEST%\index.html';$s.IconLocation='%DEST%\icons\ManteniPro.ico';$s.Save()"

REM 5. Verificacion
echo [4/4] Verificando instalacion ...
if exist "%DEST%\index.html" (echo     OK  Programa instalado) else (echo     FALLA Programa)
if exist "%USERPROFILE%\Desktop\ManteniPro.lnk" (echo     OK  Acceso directo Escritorio) else (echo     AVISO Acceso directo no encontrado ^(Escritorio en OneDrive^)?)

echo.
echo ==========================================
echo  Instalacion terminada.
echo  Usuario: admin    Contrasena: admin123
echo  Cambie la contrasena en Usuarios.
echo ==========================================
start "" "%DEST%\index.html"
pause
endlocal
