$Shell = New-Object -ComObject ("WScript.Shell")
$ShortCut = $Shell.CreateShortcut($env:USERPROFILE + "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\WinCryptSSHAgent.lnk")
$ShortCut.TargetPath="WinCryptSSHAgent.exe"
$ShortCut.WorkingDirectory = "C:\ProgramData\chocolatey\bin";
$ShortCut.IconLocation = "WinCryptSSHAgent.exe, 0";
$ShortCut.Save()
