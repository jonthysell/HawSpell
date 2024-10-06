# Copyright (c) Jon Thysell <http://jonthysell.com>
# Licensed under the MIT License.

param(
    [switch]$Clean = $False
)

[string] $RepoRoot = Resolve-Path "$PSScriptRoot/.."

[string] $OutputRoot = "bld"

$StartingLocation = Get-Location
Set-Location -Path $RepoRoot

. (Join-Path $RepoRoot "scripts/utils.ps1")

try
{
    New-Item -Path $OutputRoot -Type Directory -Force | Out-Null

    if ($Clean) {
        Write-Host Cleaning $OutputRoot\HawSpell_*.xpi...
        Remove-Item $OutputRoot\HawSpell_*.xpi
    }

    $FirefoxOutputDir = Join-Path $OutputRoot "firefox"
    if ((Test-Path $FirefoxOutputDir) -and $Clean) {
        Write-Host Cleaning $FirefoxOutputDir...
        Remove-Item $FirefoxOutputDir -Recurse
    }
    New-Item -Path $FirefoxOutputDir -Type Directory -Force | Out-Null

    $FirefoxInputDir = Join-Path $RepoRoot "src/firefox"

    Write-Host Copying base files into $FirefoxOutputDir...
    Copy-Item -Path $FirefoxInputDir/* -Dest $FirefoxOutputDir -Recurse

    $ManifestReplacements = @{}

    $ManifestReplacements["VERSION"] = Get-Version

    $BaseManifestFile = Join-Path $FirefoxInputDir "manifest.json"
    $ManifestFile = Join-Path $FirefoxOutputDir "manifest.json"
    CopyAndReplace-TemplateFile -InputPath $BaseManifestFile -OutputPath $ManifestFile -Replacements $ManifestReplacements

    $HunspellOutputDir = Join-Path $OutputRoot "hunspell"
    $HunspellAffFile = Join-Path $HunspellOutputDir "haw.aff"
    $HunspellDicFile = Join-Path $HunspellOutputDir "haw.dic"
    if (-Not ((Test-Path $HunspellAffFile) -And (Test-Path $HunspellDicFile))) {
        Write-Host Creating missing hunspell files...
        & (Join-Path $RepoRoot "scripts/build-hunspell.ps1")
    }

    $DictionariesOutputDir = Join-Path $FirefoxOutputDir "dictionaries"
    New-Item -Path $DictionariesOutputDir -Type Directory -Force | Out-Null

    Write-Host Copying hunspell files into $DictionariesOutputDir...
    Copy-Item -Path $HunspellAffFile -Dest (Join-Path $DictionariesOutputDir "haw.aff")
    Copy-Item -Path $HunspellDicFile -Dest (Join-Path $DictionariesOutputDir "haw.dic")

    $ArchiveName = Join-Path $OutputRoot "HawSpell_$($ManifestReplacements["VERSION"]).xpi"
    Write-Host Creating $ArchiveName...
    $ArchiveParams = @{
        Path = "$FirefoxOutputDir/*", (Join-Path $RepoRoot "README.md"), (Join-Path $RepoRoot "LICENSE.md"), (Join-Path $RepoRoot "CHANGELOG.md")
        DestinationPath = $ArchiveName
        Force = $True
    }
    Compress-Archive @ArchiveParams
}
finally
{
    Set-Location -Path "$StartingLocation"
}
