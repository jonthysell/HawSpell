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
        Write-Host Cleaning $OutputRoot\HawSpell_*.oxt...
        Remove-Item $OutputRoot\HawSpell_*.oxt
    }

    $OpenOfficeOutputDir = Join-Path $OutputRoot "openoffice"
    if ((Test-Path $OpenOfficeOutputDir) -and $Clean) {
        Write-Host Cleaning $OpenOfficeOutputDir...
        Remove-Item $OpenOfficeOutputDir -Recurse
    }
    New-Item -Path $OpenOfficeOutputDir -Type Directory -Force | Out-Null

    $OpenOfficeInputDir = Join-Path $RepoRoot "src/openoffice"

    Write-Host Copying base files into $OpenOfficeOutputDir...
    Copy-Item -Path $OpenOfficeInputDir/* -Dest $OpenOfficeOutputDir -Recurse

    $DescriptionReplacements = @{}

    $DescriptionReplacements["VERSION"] = Get-Version

    $BaseDescriptionFile = Join-Path $OpenOfficeInputDir "description.xml"
    $DescriptionFile = Join-Path $OpenOfficeOutputDir "description.xml"
    CopyAndReplace-TemplateFile -InputPath $BaseDescriptionFile -OutputPath $DescriptionFile -Replacements $DescriptionReplacements

    $HunspellOutputDir = Join-Path $OutputRoot "hunspell"
    $HunspellAffFile = Join-Path $HunspellOutputDir "haw.aff"
    $HunspellDicFile = Join-Path $HunspellOutputDir "haw.dic"
    if (-Not ((Test-Path $HunspellAffFile) -And (Test-Path $HunspellDicFile))) {
        Write-Host Creating missing hunspell files...
        & (Join-Path $RepoRoot "scripts/build-hunspell.ps1")
    }

    Write-Host Copying hunspell files into $OpenOfficeOutputDir...
    Copy-Item -Path $HunspellAffFile -Dest (Join-Path $OpenOfficeOutputDir "haw.aff")
    Copy-Item -Path $HunspellDicFile -Dest (Join-Path $OpenOfficeOutputDir "haw.dic")

    $ArchiveName = Join-Path $OutputRoot "HawSpell_$($DescriptionReplacements["VERSION"]).oxt"
    Write-Host Creating $ArchiveName...
    $ArchiveParams = @{
        Path = "$OpenOfficeOutputDir/*", (Join-Path $RepoRoot "README.md"), (Join-Path $RepoRoot "LICENSE.md"), (Join-Path $RepoRoot "CHANGELOG.md")
        DestinationPath = $ArchiveName
        Force = $True
    }
    Compress-Archive @ArchiveParams
}
finally
{
    Set-Location -Path "$StartingLocation"
}
