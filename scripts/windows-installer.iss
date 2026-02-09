; Read version from plain text VERSION file
#define VersionFile AddBackslash(SourcePath) + "..\windows-tray-app\VERSION"
#define FileHandle FileOpen(VersionFile)
#define MyAppVersion Trim(FileRead(FileHandle))
#expr FileClose(FileHandle)

#define MyAppName "Consult User MCP"
#define MyAppPublisher "Consult User MCP"
#define MyAppExeName "ConsultUserMCP.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=ConsultUserMCP-Setup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Tray app
Source: "..\windows-tray-app\bin\Release\net8.0-windows\win-x64\publish\ConsultUserMCP.exe"; DestDir: "{app}"; Flags: ignoreversion

; Dialog CLI
Source: "..\dialog-cli-windows\bin\Release\net8.0-windows\win-x64\publish\dialog-cli-windows.exe"; DestDir: "{app}"; Flags: ignoreversion

; MCP Server
Source: "..\mcp-server\dist\*"; DestDir: "{app}\mcp-server\dist"; Flags: ignoreversion recursesubdirs
Source: "..\mcp-server\node_modules\*"; DestDir: "{app}\mcp-server\node_modules"; Flags: ignoreversion recursesubdirs
Source: "..\mcp-server\package.json"; DestDir: "{app}\mcp-server"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "startup"; Description: "Start {#MyAppName} when Windows starts"; GroupDescription: "Startup:"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#MyAppName}"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: startup

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
