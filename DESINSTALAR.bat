@echo off
echo Haga un RESPALDO desde ManteniPro antes de continuar.
pause
rmdir /S /Q "%LOCALAPPDATA%\ManteniPro"
del "%USERPROFILE%\Desktop\ManteniPro.lnk" 2>nul
echo ManteniPro desinstalado.
pause
