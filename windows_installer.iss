#define MyAppName "iMask VPN"
#define MyAppVersion "6.18"
#define MyAppPublisher "BlackBox THC"
#define MyAppExeName "imask_vpn.exe"

[Setup]
AppId={{E6384C12-88E4-48FE-98B2-1D92C9215A44}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
VersionInfoVersion=6.18.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=iMask VPN v6.18 Installer
VersionInfoCopyright=Copyright (C) 2026 BlackBox THC
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
DisableProgramGroupPage=yes
OutputDir=d:\WorkStation\Antigravity\iMask
OutputBaseFilename=iMask-VPN-Setup-v6.18
SetupIconFile=d:\WorkStation\Antigravity\iMask\windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "d:\WorkStation\Antigravity\iMask\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "d:\WorkStation\Antigravity\iMask\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "d:\WorkStation\Antigravity\iMask\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "d:\WorkStation\Antigravity\iMask\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "d:\WorkStation\Antigravity\iMask\tools\openvpn\*"; DestDir: "{app}\tools\openvpn"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "d:\WorkStation\Antigravity\iMask\tools\wireguard-amd64.msi"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "d:\WorkStation\Antigravity\iMask\tools\openvpn.msi"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "d:\WorkStation\Antigravity\iMask\tools\certs\BlackBoxTHC.cer"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "d:\WorkStation\Antigravity\iMask\iMask-WireGuard-Oracle.conf"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"; ValueType: string; ValueName: "{app}\{#MyAppExeName}"; ValueData: "~ RUNASADMIN"; Flags: uninsdeletevalue

[Code]
function WireGuardNotInstalled(): Boolean;
begin
  Result := not FileExists('C:\Program Files\WireGuard\wireguard.exe');
end;

function OpenVPNNotInstalled(): Boolean;
begin
  Result := not FileExists('C:\Program Files\OpenVPN\bin\openvpn.exe');
end;

[Run]
Filename: "certutil.exe"; Parameters: "-addstore -f ""Root"" ""{tmp}\BlackBoxTHC.cer"""; StatusMsg: "Registering BlackBox THC Publisher Certificate..."; Flags: runhidden
Filename: "certutil.exe"; Parameters: "-addstore -f ""TrustedPublisher"" ""{tmp}\BlackBoxTHC.cer"""; StatusMsg: "Registering BlackBox THC Trusted Publisher..."; Flags: runhidden
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\wireguard-amd64.msi"" /quiet /norestart"; StatusMsg: "Installing WireGuard Engine & Wintun Driver..."; Check: WireGuardNotInstalled; Flags: runhidden
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\openvpn.msi"" /quiet /norestart"; StatusMsg: "Installing OpenVPN Engine & TAP Driver..."; Check: OpenVPNNotInstalled; Flags: runhidden
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent shellexec
