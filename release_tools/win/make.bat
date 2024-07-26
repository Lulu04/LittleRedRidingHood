@echo off

set "EXENAME=LittleRedRidingHood.exe"
set "BINARYFOLDER=C:\Pascal\LittleRedRidingHood\Binary\"
set "BINARYFILE=%BINARYFOLDER%%EXENAME%"
set "LAZARUS_PROJECT=C:\Pascal\LittleRedRidingHood\LittleRedRidingHood.lpi"

rem retrieves the app version
pushd ..\..
set /p VERSION=<version.txt
popd


rem delete binary file
if exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe"
)

rem delete dbg file
if exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.dbg" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.dbg"
)

rem delete linux exe file
if exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood"
)

rem atlas png file
if exist "C:\Pascal\LittleRedRidingHood\Binary\Atlas.png" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\Atlas.png"
)

rem compile lazarus project
echo Compiling %EXENAME% version %VERSION% for x86_64
"C:\lazarus\lazbuild.exe" --build-all --quiet --widgetset=win32 --cpu=x86_64 --build-mode=Release --no-write-project %LAZARUS_PROJECT% >NUL 2>NUL

rem check if binary was build
if not exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe" (
  echo COMPILATION ERROR FOR TARGET x86_64
  pause
  exit /b
)
echo success
echo.

echo constructing 64b zip portable version
rem copy Binary folder to a temp LittleRedRidingHood folder
xcopy %BINARYFOLDER% "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%" /s /e /i /q
rem delete unecessary folder
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\i386-linux"
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\i386-win32"
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\x86_64-linux"
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\x86_64-darwin"

echo compressing
tar.exe -a -c -f "..\LittleRedRidingHood_%VERSION%_Windows64_Portable.zip" "LittleRedRidingHood_%VERSION%"

rem delete temporary Saynetes folder
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%"
echo done
echo.

rem delete binary file
if exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe"
)
rem delete dbg file
if exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.dbg" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.dbg"
)

rem compile lazarus project
echo Compiling %EXENAME% version %VERSION% for i386
"C:\lazarus\lazbuild.exe" --build-all --quiet --widgetset=win32 --cpu=i386 --build-mode=Release --no-write-project %LAZARUS_PROJECT% >NUL 2>NUL

rem check if binary was build
if not exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe" (
  echo COMPILATION ERROR FOR TARGET i386
  pause
  exit /b
)
echo success
echo.

echo constructing 32b zip portable version
rem copy Binary folder to a temp LittleRedRidingHood folder
xcopy %BINARYFOLDER% "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%" /s /e /i /q
rem delete unecessary folder
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\i386-linux"
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\x86_64-win64"
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\x86_64-linux"
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%\x86_64-darwin"

echo compressing
tar.exe -a -c -f "..\LittleRedRidingHood_%VERSION%_Windows32_Portable.zip" "LittleRedRidingHood_%VERSION%"

rem delete temporary LittleRedRidingHood folder
rmdir /s /q "C:\Pascal\LittleRedRidingHood\release_tools\win\LittleRedRidingHood_%VERSION%"
echo.

rem delete binary file
if exist "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe" (
  del /q "C:\Pascal\LittleRedRidingHood\Binary\LittleRedRidingHood.exe"
)

echo done
