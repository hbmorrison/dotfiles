#Requires AutoHotkey v2
#SingleInstance Force

SendMode("Input")

; Work out the location of the Bitwarden executable

A_LocalAppData := EnvGet("LocalAppData")
A_LocalBitwarden := A_LocalAppData . "\Programs\Bitwarden\Bitwarden.exe"
A_SystemBitwarden := "shell:AppsFolder\8bitSolutionsLLC.bitwardendesktop_h4e712dmw3xyy!bitwardendesktop"

; Shortcuts

^!+p::SwitchToBitwarden()
^!+n::SwitchToTerminal()
^!+e::SwitchToMSEdge()
^!+x::SwitchToExplorer()
^!+r::SwitchTo("mstsc.exe", "mstsc.exe")
^!+t::SwitchTo("ms-teams.exe", "ms-teams.exe")

; Bring the Window Hello dialog box to the front

^!+h::
{
  WinActivate("ahk_class Credential Dialog Xaml Host")
}

 ; Type out whatever is in the clipboard

^!+v::
{
  Send(A_ClipBoard)
  Sleep(500)
  Send("{Enter}")
}

; Switch to the app if it is running or launch it

SwitchTo(name, launch) {
  if WinExist("ahk_exe" name)
    WinActivate()
  else
    Run(launch)
}

; Switch to explorer if there are windows open or open one

SwitchToExplorer() {
  if WinExist("ahk_class CabinetWClass") {
    vWinList := WinGetList("ahk_class CabinetWClass")
    for vWin in vWinList {
      WinActivate("ahk_id " vWin)
    }
  } else {
    Run("explorer.exe")
  }
}

; Switch to Microsoft Edge or make a new tab if it is already active

SwitchToMSEdge() {
  wd := A_WinDelay
  SetWinDelay(0)
  if WinActive("ahk_exe msedge.exe") {
    Send("^t")
  } else {
    try
      WinActivate("ahk_exe msedge.exe")
    catch TargetError as error
      Run("msedge.exe")
    finally
      WinWaitActive("ahk_exe msedge.exe", , 1)
  }
  SetWinDelay(wd)
}


; Switch to terminal or make a new tab if it is already active

SwitchToTerminal() {
  wd := A_WinDelay
  SetWinDelay(0)
  if WinActive("ahk_exe WindowsTerminal.exe") {
    Send("^+t")
  } else {
    try
      WinActivate("ahk_exe WindowsTerminal.exe")
    catch TargetError as error
      Run("wt.exe")
    finally
      WinWaitActive("ahk_exe WindowsTerminal.exe", , 1)
  }
  SetWinDelay(wd)
}

; Switch to Bitwarden or copy the first password if it is already active

SwitchToBitwarden() {
  wd := A_WinDelay
  SetWinDelay(0)
  if WinActive("ahk_exe Bitwarden.exe") {
    Send("^f")
    Send("{Tab}")
    Send("{Tab}")
    Send("{Enter}")
    Send("^p")
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
    Send("^f")
  }
  SetWinDelay(wd)
}