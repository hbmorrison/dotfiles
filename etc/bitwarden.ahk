SendMode Input
SetTitleMatchMode, RegEx

#SingleInstance, Off
#Persistent

if ( ScriptInstanceExist() ) {
  ExitApp
}

^!b:: ; Ctrl+Shift+B
{
  if ! WinActivate, ahk_exe Bitwarden.exe
    Run, shell:AppsFolder\8bitSolutionsLLC.bitwardendesktop_h4e712dmw3xyy!bitwardendesktop
  WinWaitActive, ahk_exe Bitwarden.exe,, 1
  Send ^f
}
return

^!v:: ; Ctrl+Shift+V
{
  SendInput %ClipBoard%
  Sleep 500
  SendInput {Enter}
}
return

ScriptInstanceExist() {
  static title := " - AutoType - AutoHotkey v" A_AhkVersion
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  WinGet, match, List, % A_ScriptFullPath . title
  DetectHiddenWindows, % dhw
  return (match > 1)
}
