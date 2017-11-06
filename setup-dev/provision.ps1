# Provision a Win10 dev environment

function provision-main {
    # If we're running in vagrant, we have to get the working directory a bit more explicitly
    # Luckily we can set an environment variable during vagrant's provisioning step to make it self-aware
    # If we aren't using vagrant, just set the working dir to the script's current dir
    if ($env:VAGRANT) {
        $wd = "C:\vagrant"
    } else {
        $wd = Split-Path $myinvocation.MyCommand.Path
    }

    # Install chocolatey for package management
    Write-Host "Installing chocolatey..."

    $chocodir = "C:\ProgramData\chocolatey"
    $expectedhash = "39b5adcb4100b3bf0c4b99c0fa8bed387ebfa954cd637828517d051ec81f671d"

    if (-Not (Test-Path $chocodir)) {

        $script = ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        $hash = Get-SHA256 $script

        if ($hash -ne $expectedhash) {
            throw "Error: Hash mismatch! Exiting."
        }

        iex $script

        $chocobin = @("$chocodir\bin")
        Add-ToPath "Path" $chocobin

        Print-Pretty "Chocolatey installed. Environment set up for provisioning."

    } else {
        Write-Host "Chocolatey already installed. Skipping step."
    }

    # Install choco dependencies
    $choco_pkgs = @("7zip","git","dotnet4.5","python3")

    Write-Host "Looking for missing chocolatey packages..."
    $missing_pkgs = New-Object System.Collections.ArrayList
    $installed_pkgs = choco list --local-only

    foreach ($pkg in $choco_pkgs) {
        if (-Not ($installed_pkgs | Select-String $pkg)) {
            [void]$missing_pkgs.add($pkg)
        }
    }

    if ($missing_pkgs.count -eq 0) {
        Write-Host "All chocolatey packages installed!"
    } else {
        foreach ($pkg in $missing_pkgs) {
            Write-Host "Installing $pkg..."
            cinst -y $pkg > $null
            if ($LastExitCode -eq 0) {
                Write-Host "$pkg installed successfully."
            } else {
                Write-Warning "could not install $pkg."
            }
        }
    }

    # Download the necessary windows kits and unzip them to the proper directories
    # Chocolatey doesn't have all of them available, so for consistency we grab them from Microsoft directly
    Get-ChildItem -Path "$wd\installers" -Filter *.ps1 | Foreach-Object {
        $script = $_.FullName
        & $script
    }

    # Add relevant folders to machine search path
    $pathelements = @(
        "C:\Program Files\Git\bin",
        "C:\Python36"
    )

    Add-ToPath "Path" $pathelements

    if ($env:VAGRANT) {
        Print-Pretty "Provisioning complete! Run 'vagrant reload' before continuing."
    } else {
        Print-Pretty "Provisioning complete! Restart your box before continuing."
    }
}

function Add-ToPath ($pathname, $elements) {

    $curpath = [Environment]::GetEnvironmentVariable($pathname)
    $oldpath = $curpath

    foreach ($elem in $elements) {
        if (-Not ($curpath.Contains($elem))) {
            Write-Host "Adding [$elem] to $pathname..."
            $curpath = $curpath + ";$elem"
        }
    }

    # Add to permanent path and to local session path
    # Permanent path isn't available mid-provision unless you refresh powershell
    [Environment]::SetEnvironmentVariable($pathname, $curpath, [System.EnvironmentVariableTarget]::Machine)
    $env:path = $curpath

    if ($oldpath -ne $curpath) {
        Write-Host "$pathname now $curpath"
    }
}

function Get-SHA256 ($string) {
    $sha256 = New-Object -TypeName System.Security.Cryptography.SHA256CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($sha256.ComputeHash($utf8.GetBytes($string))).ToLower() -replace '-',''

    return $hash
}
function Print-Pretty ($text) {
    Write-Host "---------------------------------------------------------------------"
    Write-Host "$text"
    Write-Host "---------------------------------------------------------------------"
}

$ErrorActionPreference = "Stop"
provision-main
