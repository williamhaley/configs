# Philosophy

Don't install anything every, unless it's listed here. Try to keep this as pristine as possible.

# Install

* [Google Chrome](https://www.google.com/chrome/browser/desktop/)
* Battle.net
* Steam
* [7-zip](http://www.7-zip.org/download.html)
* [OpenSSH build from Microsoft](https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH)
* NOTHING ELSE

# Configure

After initial install, disable automatic driver installation so that you're not fighting Windows. Control Panel -> System and Security -> System -> Advanced System Settings -> Hardware.

Set Chrome as the default browser.

Add `--incognito` flag to all Chrome shortcuts.

Right click the Cortana omni-box search area. Disable Cortana. Then, right click the same omni-box and disable the ability to search online.

Unpin IE and the Microsoft store from the taskbar. Unpin everything from the start menu.

# Deactivate

```
slmgr.vbs /dlv
slmgr /upk <Activation ID>
# Unplug the network cable to prevent automatic re-activation.
```

# Upgrade

* Upgrade to Windows 8.1 via the store as an *Administrator*.
* Upgrade to Windows 10 by downloading the [Media Creation Tool](https://www.microsoft.com/en-us/software-download/windows10). Run it from your Windows machine.

# User configuration

Login using a Microsoft user account if applicable. Otherwise, create a local account. Make sure the account is a standard user.

Create a second, administrator, account. Never login with that account. It will only be used when prompted to run something with administrator privileges.

## Mouse

Mice in windows can be funky. You may want to screw with the settings for a while. Specifically, tap to click can be problematic, but figure out what works best for you.

# Auto-login

Run a `cmd` prompt as an administrator.

These commands assume you are logged in as the user you wish to auto-login as and that it is a local account.

```
set _PASSWORD=some password
set _USERNAME=The Username
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /f /v AutoAdminLogon /t REG_SZ /d 1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /f /v DefaultDomainName /t REG_SZ /d %COMPUTERNAME%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /f /v DefaultUserName /t REG_SZ /d "%_USERNAME%"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /f /v DefaultPassword /t REG_SZ /d "%_PASSWORD%"
```

WinPE

```
https://technet.microsoft.com/en-us/library/dn293200.aspx

Install Windows PE to a DVD, a CD, or an ISO file

Click Start, and type deployment. Right-click Deployment and Imaging Tools Environment and then select Run as administrator.
Create a working copy of the Windows PE files. Specify either x86 or amd64:
copype amd64 C:\WinPE_amd64
Create an ISO file containing the Windows PE files:
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE_amd64.iso
To burn a DVD or CD: In Windows Explorer, right-click the ISO file, and select Burn disc image > Burn, and follow the prompts.
```
