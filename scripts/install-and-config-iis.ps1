Write-Output "Install IIS"
Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools

Write-Output "Install ASP.NET 4.8"
Install-WindowsFeature -Name Web-Asp-Net45

Write-Output "Create a folder for the website"
New-Item -Path C:\inetpub\wwwroot\ -Name "webapi" -ItemType "directory" -Force

Write-Output "Create a new website"
New-IISSite -Name "webapi" -Port 8080 -PhysicalPath "C:\inetpub\wwwroot\webapi" -ApplicationPool ".NET v4.5"

Write-Output "Enable 8080 port on firewall"
New-NetFirewallRule -DisplayName "Allow 8080" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow

Write-Output "Enable web deploy port on firewall"
New-NetFirewallRule -DisplayName "Allow 8172" -Direction Inbound -LocalPort 8172 -Protocol TCP -Action Allow