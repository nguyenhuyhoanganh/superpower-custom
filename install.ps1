#!/usr/bin/env pwsh
# PowerShell installer for superpower-custom. Mixed strategy:
#   - Junction for the 13 skill folders (no admin / Developer Mode needed)
#   - Copy for bootstrap + 4 workflow files (junctions don't work on files)
# Idempotent: re-running refreshes copies and rebuilds junctions.
$ErrorActionPreference = 'Stop'

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Workspace = Split-Path -Parent $SourceDir

$RulesDir     = Join-Path $Workspace '.clinerules'
$WorkflowsDir = Join-Path $RulesDir 'workflows'
$SkillsDir    = Join-Path (Join-Path $Workspace '.cline') 'skills'

New-Item -ItemType Directory -Force -Path $RulesDir, $WorkflowsDir, $SkillsDir | Out-Null

# 1. Bootstrap rule (copy)
$bootstrapSource = Join-Path $SourceDir 'rules\00-bootstrap.md'
if (Test-Path $bootstrapSource) {
    Copy-Item -Force $bootstrapSource (Join-Path $RulesDir '00-bootstrap.md')
}

# 2. Workflows (copy)
foreach ($wf in 'brainstorm', 'write-plan', 'execute-plan', 'check-webui-style') {
    $src = Join-Path $SourceDir "workflows\$wf.md"
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $WorkflowsDir "$wf.md")
    }
}

# 3. Skills (junction)
$skillCount = 0
$skillsSourceDir = Join-Path $SourceDir 'skills'
if (Test-Path $skillsSourceDir) {
    Get-ChildItem -Path $skillsSourceDir -Directory | ForEach-Object {
        $target = Join-Path $SkillsDir $_.Name
        if (Test-Path $target) {
            Remove-Item -Force -Recurse $target
        }
        New-Item -ItemType Junction -Path $target -Target $_.FullName | Out-Null
        $skillCount++
    }
}

Write-Host "Installed superpower-custom into $Workspace"
Write-Host "  Rules:     $RulesDir"
Write-Host "  Workflows: $WorkflowsDir"
Write-Host "  Skills:    $SkillsDir ($skillCount linked)"
Write-Host ""
Write-Host "Note: bootstrap and workflow files are COPIES on Windows."
Write-Host "      Re-run install.ps1 after editing those source files."
