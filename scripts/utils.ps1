# Copyright (c) Jon Thysell <http://jonthysell.com>
# Licensed under the MIT License.

function CopyAndReplace-TemplateFile {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        $Replacements
    )

    Write-Host Creating $OutputPath...

    $RawContent = Get-Content -Path $InputPath
    $NewContent = $RawContent | ForEach-Object {
        $line = $_
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $Replacements.Keys | ForEach-Object {
                $key = $_
                $line = $line.Replace("{$key}", $Replacements[$key])
            }
        }
        return $line
    }
    $NewContent | Set-Content -Path $OutputPath -Force
}

function Get-Version {
    param()

    [string] $RepoRoot = Resolve-Path "$PSScriptRoot/.."

    $VersionFile = Join-Path $RepoRoot "src/version.txt"
    $Version = Get-Content -Path $VersionFile
    return $Version.Trim()
}

function Copy-LicenseAndReadme {
    param(
        [string]$OutputPath
    )

    Write-Host Copy license and readme...

    [string] $RepoRoot = Resolve-Path "$PSScriptRoot/.."

    $LicenseFile = Join-Path $RepoRoot "LICENSE.md"
    Copy-Item -Path $LicenseFile -Dest $OutputPath

    $ReadMeFile = Join-Path $RepoRoot "README.md"
    Copy-Item -Path $ReadMeFile -Dest $OutputPath
}