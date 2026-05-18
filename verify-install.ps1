#!/usr/bin/env pwsh
# Verify install.ps1 result: files copied (and not stale), junctions resolve.
# Exits 0 if OK, 1 with problem list otherwise.
$ErrorActionPreference = 'Stop'

$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Workspace = Split-Path -Parent $SourceDir

$RulesDir     = Join-Path $Workspace '.clinerules'
$WorkflowsDir = Join-Path $RulesDir 'workflows'
$SkillsDir    = Join-Path (Join-Path $Workspace '.cline') 'skills'

$script:problems = 0

function Test-FileCopy {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    if (-not (Test-Path $Source)) { return }  # Skip if source missing (staged install)
    if (-not (Test-Path $Target)) {
        Write-Host "MISSING file: $Target"
        $script:problems++
        return
    }
    $srcHash = (Get-FileHash $Source).Hash
    $dstHash = (Get-FileHash $Target).Hash
    if ($srcHash -ne $dstHash) {
        Write-Host "STALE COPY: $Target (run install.ps1 to refresh)"
        $script:problems++
    }
}

# Bootstrap
Test-FileCopy -Source (Join-Path $SourceDir 'rules\00-bootstrap.md') -Target (Join-Path $RulesDir '00-bootstrap.md')

# Workflows
foreach ($wf in 'brainstorm', 'write-plan', 'execute-plan') {
    Test-FileCopy -Source (Join-Path $SourceDir "workflows\$wf.md") -Target (Join-Path $WorkflowsDir "$wf.md")
}

# Skills
$skillCount = 0
$skillsSourceDir = Join-Path $SourceDir 'skills'
if (Test-Path $skillsSourceDir) {
    Get-ChildItem -Path $skillsSourceDir -Directory | ForEach-Object {
        $sourceFull = $_.FullName
        $target = Join-Path $SkillsDir $_.Name
        if (-not (Test-Path $target)) {
            Write-Host "MISSING junction: $target"
            $script:problems++
            return
        }
        $item = Get-Item $target -Force
        if ($item.LinkType -ne 'Junction') {
            Write-Host "NOT A JUNCTION: $target"
            $script:problems++
            return
        }
        $actualTarget = $item.Target | Select-Object -First 1
        if ($actualTarget -ne $sourceFull) {
            Write-Host "WRONG TARGET: $target -> $actualTarget (expected $sourceFull)"
            $script:problems++
            return
        }
        $skillMd = Join-Path $target 'SKILL.md'
        if (-not (Test-Path $skillMd)) {
            Write-Host "SKILL.md missing in: $target"
            $script:problems++
            return
        }
        $skillCount++
    }
}

$total = 1 + 3 + $skillCount
if ($script:problems -eq 0) {
    Write-Host "OK: $total items installed (1 rule + 3 workflows + $skillCount skills, mixed copy+junction)"
    exit 0
} else {
    Write-Host "FAIL: $($script:problems) problem(s) found"
    exit 1
}
