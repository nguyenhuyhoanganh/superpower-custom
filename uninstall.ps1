#!/usr/bin/env pwsh
# Remove items installed by install.ps1. Source folder untouched.
# Junctions are only removed if their target points into our $SourceDir.
$ErrorActionPreference = 'Stop'

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Workspace = Split-Path -Parent $SourceDir

$RulesDir     = Join-Path $Workspace '.clinerules'
$WorkflowsDir = Join-Path $RulesDir 'workflows'
$SkillsDir    = Join-Path (Join-Path $Workspace '.cline') 'skills'

$removed = 0

# Bootstrap
$bootstrap = Join-Path $RulesDir '00-bootstrap.md'
if (Test-Path $bootstrap) {
    Remove-Item -Force $bootstrap
    $removed++
}

# Inline using-superpowers (this branch)
$inlineRule = Join-Path $RulesDir '01-using-superpowers.md'
if (Test-Path $inlineRule) {
    Remove-Item -Force $inlineRule
    $removed++
}

# Workflows
foreach ($wf in 'brainstorm', 'write-plan', 'execute-plan') {
    $p = Join-Path $WorkflowsDir "$wf.md"
    if (Test-Path $p) {
        Remove-Item -Force $p
        $removed++
    }
}

# Skills: only remove junctions whose target is inside our source
if (Test-Path $SkillsDir) {
    $expectedPrefix = (Resolve-Path (Join-Path $SourceDir 'skills')).Path
    Get-ChildItem -Path $SkillsDir -Force | Where-Object {
        $_.LinkType -eq 'Junction'
    } | ForEach-Object {
        $target = $_.Target | Select-Object -First 1
        if ($target -and $target.StartsWith($expectedPrefix)) {
            Remove-Item -Force $_.FullName
            $removed++
        }
    }
}

Write-Host "Removed $removed items. Source kept at $SourceDir."
