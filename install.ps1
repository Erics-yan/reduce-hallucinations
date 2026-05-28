# claude-factcheck installer (Windows PowerShell)
# Idempotent: safe to re-run. Appends rules block to $HOME\.claude\CLAUDE.md
# between <!-- factcheck:begin --> and <!-- factcheck:end --> markers.

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir   = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }
$SkillSrc    = Join-Path $ScriptDir 'skills\factcheck\SKILL.md'
$RulesSrc    = Join-Path $ScriptDir 'CLAUDE.md'
$SkillDstDir = Join-Path $ClaudeDir 'skills\factcheck'
$SkillDst    = Join-Path $SkillDstDir 'SKILL.md'
$RulesDst    = Join-Path $ClaudeDir 'CLAUDE.md'

$BeginMarker = '<!-- factcheck:begin -->'
$EndMarker   = '<!-- factcheck:end -->'

Write-Host '==> claude-factcheck installer'
Write-Host "    Target: $ClaudeDir"

if (-not (Test-Path $SkillSrc) -or -not (Test-Path $RulesSrc)) {
  Write-Error 'Source files missing. Run this script from the cloned repo root.'
  exit 1
}

New-Item -ItemType Directory -Force -Path $SkillDstDir | Out-Null

# 1. Install skill
if (Test-Path $SkillDst) {
  $existing = Get-FileHash $SkillDst -Algorithm SHA256
  $incoming = Get-FileHash $SkillSrc -Algorithm SHA256
  if ($existing.Hash -ne $incoming.Hash) {
    $backup = "$SkillDst.bak.$([int][double]::Parse((Get-Date -UFormat %s)))"
    Copy-Item $SkillDst $backup
    Write-Host "    Existing skill backed up to: $backup"
  }
}
Copy-Item $SkillSrc $SkillDst -Force
Write-Host "    [ok] skill installed: $SkillDst"

# 2. Install / update CLAUDE.md rules block
if (-not (Test-Path $RulesDst)) {
  New-Item -ItemType File -Path $RulesDst -Force | Out-Null
}

$current = Get-Content $RulesDst -Raw -ErrorAction SilentlyContinue
if ($null -eq $current) { $current = '' }
$newBlock = Get-Content $RulesSrc -Raw

if ($current -match [regex]::Escape($BeginMarker)) {
  # Replace existing block via MatchEvaluator (avoids $1/$& interpretation in replacement string)
  $pattern = [regex]::Escape($BeginMarker) + '[\s\S]*?' + [regex]::Escape($EndMarker)
  $updated = [regex]::Replace($current, $pattern, { param($m) $newBlock })
  Set-Content -Path $RulesDst -Value $updated -NoNewline
  Write-Host '    [ok] CLAUDE.md rules block updated in-place'
} else {
  # Append, with separator if non-empty
  $separator = ''
  if ($current.Length -gt 0 -and -not $current.EndsWith("`n")) {
    $separator = "`r`n`r`n"
  } elseif ($current.Length -gt 0) {
    $separator = "`r`n"
  }
  Add-Content -Path $RulesDst -Value ($separator + $newBlock) -NoNewline
  Write-Host '    [ok] CLAUDE.md rules block appended'
}

Write-Host ''
Write-Host '==> Done.'
Write-Host '    Open a new Claude Code session — the factcheck protocol is now active by default.'
Write-Host '    Manual trigger remains available: /factcheck  or  /factcheck <question>'
