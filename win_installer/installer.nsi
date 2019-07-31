!include x64.nsh
!include LogicLib.nsh
!include MUI2.nsh
!include "FileFunc.nsh"

!define APP_NAME "Clojure"
!define /ifndef PRODUCT_VERSION "0.0.0.0"
!define PUBLISHER "Rich Hickey"
!define PRODUCT_CODE "{C718C0FE-E079-4452-B5CD-523DF1727F20}"
!define UNINSTALL_REGKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

Name "${APP_NAME}"
InstallDir "$PROGRAMFILES64\${APP_NAME}"
OutFile "out\clojure-cli-installer-${PRODUCT_VERSION}.exe"
RequestExecutionLevel admin

Var psEnableScripts
Var psExecutionPolicy
  
Function EnsureJava
  nsExec::exec "where java"
  Pop $0 ; Return
  Pop $1 ; Output
  IntCmp $0 0 is0
  MessageBox MB_YESNO "${APP_NAME} requires Java to run. Please download and install it, ensure it is in the path, and run this setup again.$\n$\nDo you want to download Java now?" IDNO NoDownload
    ExecShell "open" "https://jdk.java.net"
  NoDownload:
    Abort
  is0:
FunctionEnd

Function Ensure64
  ${If} ${RunningX64}
  ${Else}
    MessageBox MB_OK|MB_ICONEXCLAMATION  "This installer only supports 64bit installations."
    Abort
  ${EndIf}
FunctionEnd

;; Saves the registry values for Powershell script execution policy
!macro PSRegSave un
Function ${un}PSRegSave
  SetRegView 64
  ReadRegDWORD $psEnableScripts HKLM "SOFTWARE\Policies\Microsoft\Windows\PowerShell" "EnableScripts"
  ReadRegStr $psExecutionPolicy HKLM "SOFTWARE\Policies\Microsoft\Windows\PowerShell" "ExecutionPolicy"
FunctionEnd
!macroend
!insertmacro PSRegSave ""
!insertmacro PSRegSave "un."

;; Restores the registry values for Powershell script execution policy
!macro PSRegRestore un
Function ${un}PSRegRestore
  SetRegView 64
  WriteRegStr HKLM "SOFTWARE\Policies\Microsoft\Windows\PowerShell" "ExecutionPolicy" $psExecutionPolicy
  WriteRegDWORD HKLM "SOFTWARE\Policies\Microsoft\Windows\PowerShell" "EnableScripts" $psEnablescripts
FunctionEnd
!macroend
!insertmacro PSRegRestore ""
!insertmacro PSRegRestore "un."

;; Sets the registry values for Powershell script execution
!macro PSRegSet un
Function ${un}PSRegSet
  SetRegView 64
  WriteRegStr HKLM "SOFTWARE\Policies\Microsoft\Windows\PowerShell" "ExecutionPolicy" "Bypass"
  WriteRegDWORD HKLM "SOFTWARE\Policies\Microsoft\Windows\PowerShell" "EnableScripts" 0x00000001
FunctionEnd
!macroend
!insertmacro PSRegSet ""
!insertmacro PSRegSet "un."

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "icon\InstallHeader.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "icon\InstallHeader.bmp"
!define MUI_HEADERIMAGE_UNBITMAP_RTL "icon\InstallHeader.bmp"
!define MUI_ABORTWARNING
;!define MUI_COMPONENTSPAGE_CHECKBITMAP

!insertmacro MUI_PAGE_LICENSE "epl-v10.txt"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Function .onInit
  Call Ensure64
  Call EnsureJava
FunctionEnd

Section "File copy"
  SetOutPath $INSTDIR    
    File "clojure-cli\clj.cmd"
    File "clojure-cli\clojure.exe"
    File "clojure-cli\deps.edn"
    File "clojure-cli\example-deps.edn"
    File "icon\Clojure.ico"
  SetOutPath "$INSTDIR\libexec"
    File "clojure-cli\libexec\clojure-tools-1.10.1.466.jar"
  SetOutPath $INSTDIR
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

!macro CreateInternetShortcut FILEPATH URL
WriteINIStr "${FILEPATH}" "InternetShortcut" "URL" "${URL}"
!macroend

Section "Star menu"
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  SetOutPath "$DOCUMENTS"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\CLojure.lnk" "$INSTDIR\Clojure.exe" "" "$INSTDIR\Clojure.ico"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Clj.lnk" "$INSTDIR\clj.cmd" "" "$INSTDIR\Clojure.ico"
  !insertmacro CreateInternetShortcut "$SMPROGRAMS\${APP_NAME}\Clojure on the web.URL" "https://clojure.org"
SectionEnd  

Section "Set uninstall keys"
  SetRegView 64
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "QuietUninstallString" '"$INSTDIR\uninstall.exe" /S'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "InstallLocation" '$INSTDIR'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "DisplayVersion" '${PRODUCT_VERSION}'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "DisplayIcon" '$INSTDIR\Clojure.ico'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "Publisher" '${PUBLISHER}'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "URLInfoAbout" 'https://clojure.org'
  WriteRegStr HKLM ${UNINSTALL_REGKEY} "URLUpdateInfo" 'https://clojure.org'
  WriteRegDWORD HKLM ${UNINSTALL_REGKEY} "NoModify" 0x00000001
  WriteRegDWORD HKLM ${UNINSTALL_REGKEY} "NoRepair" 0x00000001
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKLM ${UNINSTALL_REGKEY} "EstimatedSize" "$0"
SectionEnd

Section "SetThePath"
  SetOutpath $TEMP
    File "InstallScripts\Path.ps1"
  Call PSRegSave
  Call PSRegSet
  nsExec::exec `powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$TEMP\Path.ps1" add "$INSTDIR"`
  Call PSRegRestore
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd

Section "Uninstall"  
  ;; Unset uninstall keys
  SetRegView 64
  DeleteRegKey HKLM ${UNINSTALL_REGKEY}
  ;; remove from path
  SetOutpath $TEMP
    File "InstallScripts\Path.ps1"
  Call un.PSRegSave
  Call un.PSRegSet
  nsExec::exec `powershell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$TEMP\Path.ps1" remove "$INSTDIR"`
  Call un.PSRegRestore
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ;; delete install files
  RMDir /r $INSTDIR
  RMDir /r "$SMPROGRAMS\${APP_NAME}"
SectionEnd
