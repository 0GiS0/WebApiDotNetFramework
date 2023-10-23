FROM mcr.microsoft.com/windows/servercore/insider:10.0.20348.1-amd64

#input GitHub runner version argument
ARG RUNNER_VERSION

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

#Set working directory
WORKDIR /actions-runner

#Install chocolatey
ADD scripts/Install-Choco.ps1 .
RUN .\Install-Choco.ps1 -Wait; \
    Remove-Item .\Install-Choco.ps1 -Force

#Install Git, GitHub-CLI, Azure-CLI and PowerShell Core with Chocolatey (add more tooling if needed at build)
RUN choco install -y \
    git \
    gh \
    powershell-core \
    azure-cli


# Download the PowerShell App Development Toolkit
RUN Invoke-WebRequest -Uri "https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/download/3.8.4/PSAppDeployToolkit_v3.8.4.zip" -OutFile "PSAppDeployToolkit.zip"; \
    Unblock-File -Path "PSAppDeployToolkit.zip"; \
    Expand-Archive -Path "PSAppDeployToolkit.zip" -DestinationPath 'AppDeployToolkit'; \
    Remove-Item "PSAppDeployToolkit.zip" -Force



# Install Visual Studio 2022 Build Tools
ADD scripts/Install-VSBuildTools.ps1 .
RUN Powershell.exe -ExecutionPolicy Bypass .\Install-VSBuildTools.ps1 -DeploymentType "Install" -DeployMode "NonInteractive"

#Download GitHub Runner based on RUNNER_VERSION argument (Can use: Docker build --build-arg RUNNER_VERSION=x.y.z)
# https://github.com/actions/runner/releases
RUN Invoke-WebRequest -Uri "https://github.com/actions/runner/releases/download/v$env:RUNNER_VERSION/actions-runner-win-x64-$env:RUNNER_VERSION.zip" -OutFile "actions-runner.zip"; \
    Expand-Archive -Path ".\\actions-runner.zip" -DestinationPath '.'; \
    Remove-Item ".\\actions-runner.zip" -Force

#Add GitHub runner configuration startup script
ADD scripts/start.ps1 .
ADD scripts/Cleanup-Runners.ps1 .
ENTRYPOINT ["pwsh.exe", ".\\start.ps1"]