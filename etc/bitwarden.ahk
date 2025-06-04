#Requires AutoHotkey v2
#SingleInstance Force

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
      Run("shell:AppsFolder\8bitSolutionsLLC.bitwardendesktop_h4e712dmw3xyy!bitwardendesktop")
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
