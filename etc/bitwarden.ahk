#Requires AutoHotkey v2
#SingleInstance Force

A_LocalAppData := EnvGet("LocalAppData")
A_LocalBitwarden := A_LocalAppData . "\Programs\Bitwarden\Bitwarden.exe"
A_SystemBitwarden := "shell:AppsFolder\8bitSolutionsLLC.bitwardendesktop_h4e712dmw3xyy!bitwardendesktop"

^!p:: ; Ctrl+Alt+P
{
  wd := A_WinDelay
  SetWinDelay(0)
  if WinActive("ahk_exe Bitwarden.exe") {
    SendInput("{Tab}{Tab}{Enter}")
    Sleep(200)
    SendInput("^p")
  } else {
    try
      WinActivate("ahk_exe Bitwarden.exe")
    catch TargetError as error
      if FileExist(A_LocalBitwarden) {
        Run(A_LocalBitwarden)
      } else {
        Run(A_SystemBitwarden)
      }
    finally
      WinWaitActive("ahk_exe Bitwarden.exe", , 1)
    SendInput("^f")
  }
  SetWinDelay(wd)
}

^!v:: ; Ctrl+Alt+V
{
  SendInput(A_ClipBoard)
  Sleep(500)
  SendInput("{Enter}")
}
