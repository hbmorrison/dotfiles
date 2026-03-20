#Requires AutoHotkey v2
#SingleInstance Force

; Send the ssh session into the background, fetch the the password from pmp
; again and bring the ssh session back into the foreground (done by the pmp
; command but an <enter> is required).

^!z:: ; Ctrl+Alt+Z
{
  SendInput("{Enter}~{Control down}z{Control up}pmp{Enter}")
  Sleep(500)
  SendInput("{Enter}")
}
