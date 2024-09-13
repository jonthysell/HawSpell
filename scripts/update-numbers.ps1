# Copyright (c) Jon Thysell <http://jonthysell.com>
# Licensed under the MIT License.

param(
    [switch]$Clean = $False
)

[string] $RepoRoot = Resolve-Path "$PSScriptRoot/.."

[string] $OutputRoot = "bld"

$StartingLocation = Get-Location
Set-Location -Path $RepoRoot

try
{
    $WordListDir = "src/wordlists"

    $NumberListTxt = Join-Path $WordListDir "numbers.txt"

    if ((Test-Path $NumberListTxt) -and $Clean) {
        Write-Host Cleaning $NumberListTxt...
        Remove-Item $NumberListTxt | Out-Null
    }

    Write-Host Creating $NumberListTxt...
    $NumberList = @("ʻole, ʻaʻohe")

    $NumberOnes = @("kahi", "lua", "kolu", "hā", "lima", "ono", "hiku", "walu", "iwa")
    $NumberOnes | ForEach-Object {
        $Number = ("ʻe" + $_)
        if ($_ -eq "kahi") {
            $Number += ", hoʻo" + $_
        } elseif ($_ -eq "hā") {
            $Number += ", kāuna"
        }
        $NumberList += $Number
    } | Out-Null

    $NumberTens = @("ʻumi", "iwakālua")
    $NumberOnes | Select-Object -Skip 2 | ForEach-Object { $NumberTens += "kana" + $_ } | Out-Null
    $NumberTens | ForEach-Object {
        $Number = $_
        if ($_ -eq "kanahā") {
            $Number += ", kaʻau"
        }
        $NumberList += $Number

        $TensPlace = $_
        $NumberOnes | ForEach-Object { $NumberList += ($TensPlace + "kūmā" + $_ + ", " + $TensPlace + "kumamā" + $_)  } | Out-Null
    } | Out-Null

    $NumberList += "hanele, haneli"

    $NumberList | Set-Content -Path $NumberListTxt
}
finally
{
    Set-Location -Path "$StartingLocation"
}
