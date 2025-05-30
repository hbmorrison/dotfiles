SendMode Input

#SingleInstance, Off
#Persistent

if ( ScriptInstanceExist() ) {
  ExitApp
}

; Send the ssh session into the background, fetch the the password from pmp
; again and bring the ssh session back into the foreground (done by the pmp
; command but an <enter> is required).

^+z:: ; Ctrl+Shift+Z
{
  SendInput {Enter}~{Control down}z{Control up}pmp{Enter}
  Sleep 500
  SendInput {Enter}
}
return

ScriptInstanceExist() {
  static title := " - PMP - AutoHotkey v" A_AhkVersion
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  WinGet, match, List, % A_ScriptFullPath . title
  DetectHiddenWindows, % dhw
  return (match > 1)
}
