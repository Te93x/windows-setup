# windows-setup


## VMWare Workstation Auto Start
```ps1
Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command irm https://raw.githubusercontent.com/Te93x/windows-setup/main/vmware-autostart.ps1 | iex"
```