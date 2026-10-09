; Windows 安装包脚本（Inno Setup 6）
; 先执行 flutter build windows --release，再在项目根目录执行：
;   iscc installer/windows/device_debug_tools.iss
; 版本号需与 pubspec.yaml 的 version 保持一致

#define MyAppName "Device Debug Tools"
#define MyAppVersion "1.0.0"
#define MyAppExeName "device_debug_tools.exe"
#define MyAppPublisher "device_debug_tools"
#define ReleaseDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{6F3B2A1C-8D4E-4F5A-9B7C-2E1D0A3F4B5C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\device_debug_tools
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\..\build\installer
OutputBaseFilename=device_debug_tools-{#MyAppVersion}-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 必须整目录安装：exe 依赖同级的 flutter_windows.dll、插件 dll 与 data/
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
