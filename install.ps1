# install.ps1 — installe dev-team-council dans ~/.claude (Windows / PowerShell)
# Usage : depuis la racine du repo, lancer  ./install.ps1
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src       = Join-Path $ScriptDir "dev-team-council"
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }

if (-not (Test-Path (Join-Path $Src "skills\dev-team-council\SKILL.md"))) {
    throw "Dossier 'dev-team-council' introuvable a cote du script. Lance install.ps1 depuis la racine du repo."
}

Write-Host "Installation de dev-team-council dans $ClaudeDir ..."

# 1. Skill (constitution) - dans son propre dossier
$SkillDir = Join-Path $ClaudeDir "skills\dev-team-council"
New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
Copy-Item (Join-Path $Src "skills\dev-team-council\SKILL.md") $SkillDir -Force

# 2. Agents
$AgentsDir = Join-Path $ClaudeDir "agents"
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
Copy-Item (Join-Path $Src "agents\*.md") $AgentsDir -Force

# 3. Commandes
$CmdDir = Join-Path $ClaudeDir "commands"
New-Item -ItemType Directory -Force -Path $CmdDir | Out-Null
Copy-Item (Join-Path $Src "commands\*.md") $CmdDir -Force

$nAgents = (Get-ChildItem (Join-Path $Src "agents\*.md")).Count
$nCmds   = (Get-ChildItem (Join-Path $Src "commands\*.md")).Count

Write-Host ""
Write-Host "OK :"
Write-Host "  - skill     -> $SkillDir\SKILL.md"
Write-Host "  - agents    -> $AgentsDir\ ($nAgents fichiers)"
Write-Host "  - commandes -> $CmdDir\ ($nCmds fichiers)"
Write-Host ""
Write-Host "Redemarre Claude Code, puis verifie avec : /skills  /agents  (et tape /dev- )"
