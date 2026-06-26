# bootstrap.ps1 — installe / met à jour dev-team-council depuis GitHub.
# Sans git, idempotent. Usage (PowerShell, n'importe quelle machine) :
#   irm https://raw.githubusercontent.com/tanguynoumea-collab/dev-council-marketplace/main/bootstrap.ps1 | iex
$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # accélère Invoke-WebRequest sur PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "tanguynoumea-collab/dev-council-marketplace"
$Tmp  = Join-Path $env:TEMP ("devcouncil-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

try {
    $Zip = Join-Path $Tmp "repo.zip"
    Write-Host "Téléchargement de $Repo ..."
    Invoke-WebRequest "https://github.com/$Repo/archive/refs/heads/main.zip" -OutFile $Zip
    Expand-Archive -Path $Zip -DestinationPath $Tmp -Force
    $Root = Join-Path $Tmp "dev-council-marketplace-main"
    & (Join-Path $Root "install.ps1")
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
