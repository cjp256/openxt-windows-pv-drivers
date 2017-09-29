$ErrorActionPreference = "Stop"

$wd = Split-Path $myinvocation.MyCommand.Path

$sdkKey = "HKLM:\\SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SDKs\\Windows\\v8.1"
$url = "http://download.microsoft.com/download/B/0/C/B0C80BA3-8AD6-4958-810B-6882485230B5/standalonesdk/sdksetup.exe"
$target = "$wd\sdk81setup.exe"
$expectedhash = "5107822a5a99bcdef4c7b7c7eea218425692f0185750b0d4fafd441034a7486b"

if (-Not (Test-Path -Path $sdkKey)) {

    Write-Host "Downloading SDK 8.1 exe..."

    if (Test-Path -Path $target) {
        Write-Host "SDK 8.1 exe already exists. Skipping download."
    } else {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $target)
    }

    $hash = (Get-FileHash -Algorithm 'SHA256' -Path $target).Hash.ToLower()

    if ($hash -ne $expectedhash) {
        Write-Warning "Hash mismatch! SDK will not be installed."
        exit
    }

    Write-Host "Hash verified. Installing SDK 8.1..."
    & $target /q /norestart | Out-Host

    if ($LastExitCode -eq 0) {
        Write-Host "SDK 8.1 installed successfully."
    } else {
        Write-Warning "SDK install failed. Try running the exe manually."
    }

} else {
    Write-Host "SDK 8.1 already installed. Skipping step."
}
