$ErrorActionPreference = "Stop"

$wd = Split-Path $myinvocation.MyCommand.Path

$installdir = "C:\ewdk"
$url = "https://go.microsoft.com/fwlink/p/?LinkID=699461"
$target = "$wd\ewdk10.zip"
$expectedhash = "8b1440b434910162c88f8c2f66d7bb7db83d1f3703f769b415e07a8b119a130f"

if (-Not (Test-Path -Path $installdir)) {

    Write-Host "Downloading EWDK 10 zip. This will take a while..."

    if (Test-Path -Path $target) {
        Write-Host "EWDK 10 zip already exists. Skipping download."
    } else {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $target)
    }

    $hash = (Get-FileHash -Algorithm 'SHA256' -Path $target).Hash.ToLower()

    if ($hash -ne $expectedhash) {
        Write-Warning "Hash mismatch! EWDK will not be installed."
        exit
    }

    Write-Host "Hash verified. Installing EWDK 10..."
    & 7z x $target "-o$installdir"

    if (Test-Path -Path $installdir) {
        Write-Host "EWDK 10 installed successfully."
    } else {
        Write-Warning "EWDK install failed. Try unzipping the EWDK manually into C:\ewdk."
    }

} else {
    Write-Host "EWDK 10 already installed. Skipping step."
}
