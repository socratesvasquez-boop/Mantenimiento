@echo off
echo Sus datos estan en la nube y NO se borran al desinstalar.
pause
rmdir /S /Q "%LOCALAPPDATA%\ManteniPro"
del "%USERPROFILE%\Desktop\ManteniPro.lnk" 2>nul
echo ManteniPro desinstalado.
pause
