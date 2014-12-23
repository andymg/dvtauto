@echo off
echo Installing the softwares¡­¡­¡­¡­
echo If you have installed any python, please unistall it!!!!!
set /p var="Are you sure there are no python on your computer?<Y/N>"
if %var%==n goto stop1
if %var%==N goto stop1

echo installing python2.6
set Current_Path=%~dp0
cd "%~dp0%"
start /wait tools/software/python-2.6.6.msi
echo you have installed python2.6

echo installing supplementary softwares
cd "%~dp0/%"
start /wait tools/software/thirdparty.exe
echo you have installed the supplementary softwares

ping -n 3 127.1>nul
for /f "tokens=2,*" %%i in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Python\PythonCore\2.6\InstallPath"^|findstr /i :') do set p=%%j
echo %path%|findstr /i %p%&&(goto continue) 
set path=%path%;%p%
wmic ENVIRONMENT where "name='path' and username='<system>'" set VariableValue="%path%"
echo modify the SystemVariable Path successfully
:continue

ping -n 3 127.1>nul

reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\|find /i "{6151cf20-0bd8-4023-a4a0-6a86dcfe58e5}">nul 2>nul
if %errorlevel%==0 (echo install python successfully) else  (goto stop2)

ping -n 3 127.1>nul

cd "%~dp0/selenium-2.35.0/selenium-2.35.0"
python setup.py install


ping -n 4 127.1>nul

cd "%~dp0/scapy-d02d7e7b0989"
python setup.py install
ping -n 3 127.1>nul

goto stop3:

echo Login Automation Platform
start /wait main.exe

:stop1:
echo "Please unistall Python first!!!!!"
pause

:stop2:
echo "Failed in installing Python"
pause

:stop3
echo finished!!!!!!!!!!!!!!!!
pause