#Requires AutoHotkey v2
#SingleInstance Force

SendMode("Input")
SetWinDelay(0)

^!p:: ; Ctrl+Alt+P
{
  if WinActive("ahk_exe Bitwarden.exe") {
    Send("^p")
  } else {
    try
      WinActivate("ahk_exe Bitwarden.exe")
    catch TargetError as error
      Run("shell:AppsFolder\8bitSolutionsLLC.bitwardendesktop_h4e712dmw3xyy!bitwardendesktop")
    finally
      WinWaitActive("ahk_exe Bitwarden.exe", , 1)
    Send("^f")
  }
}

^!v:: ; Ctrl+Alt+V
{
  SendInput(A_ClipBoard)
  Sleep(500)
  Send("{Enter}")
}
