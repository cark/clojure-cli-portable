@echo off
set thisdir=%~d0%~p0
pushd "%thisdir%"
cd ..
REM we're now in project root
set /p version=<version.txt
set output-dir=out\clojure-cli
call script\compile version
if ERRORLEVEL 1 (
  echo COMPILE ERROR
  goto error) else goto download

:error
echo STOP ON ERROR !!!
popd
exit /B 1

:download
if /I "%1"=="nodownload" goto package
echo Downloading ClojureTools...
rd /S /Q ClojureTools
set link=https://download.clojure.org/install/clojure-tools-%version%.zip
powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%link%'" -OutFile clojure-tools.zip
echo Extracting files...
jar -xf clojure-tools.zip
if ERRORLEVEL 1 (
  echo DOWNLOAD ERROR
  goto error) else goto package

:package
ECHO Packaging...
rd /S /Q out
md %output-dir%\libexec
copy ClojureTools\*.jar %output-dir%\libexec
copy ClojureTools\*.edn %output-dir%
copy script\clj.cmd %output-dir%
move /y clojure.exe %output-dir%
cd out
REM we'll just assume a clojure dev has java installed
jar -cfM clojure-cli-win-%version%.zip .\
if ERRORLEVEL 1 (
  echo ZIP ERROR
  goto error)

:the-end
popd
