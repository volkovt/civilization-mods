param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet('Vegeta', 'Goku', 'Gohan', 'Broly')]
    [string[]]$Heroes = @('Vegeta', 'Goku', 'Gohan', 'Broly')
)

$ErrorActionPreference = 'Stop'

$projectPath = [IO.Path]::GetFullPath($ProjectRoot)
$blender = Join-Path $PSScriptRoot 'blender-portable\blender-4.2.0-windows-x64\blender.exe'
$generator = Join-Path $PSScriptRoot 'generate_sayajin_models.py'
$modelBuilder = Join-Path $PSScriptRoot 'build_unit_art.ps1'
$texconvCandidates = @(
    (Join-Path (Split-Path -Parent $projectPath) 'tools\texconv.exe'),
    'D:\Mods civ5 pessoal\tools\texconv.exe'
)
$texconv = $texconvCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

foreach ($required in @($blender, $generator, $modelBuilder, $texconv)) {
    if (-not $required -or -not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Ferramenta obrigatoria nao encontrada: $required"
    }
}

$forms = @('Classical', 'Medieval', 'Renaissance', 'Industrial', 'Modern', 'PostModern', 'Future')
$unitRoot = Join-Path $projectPath 'ART\Units'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($hero in $Heroes) {
    & $blender --background --python $generator -- `
        --output-root $unitRoot --hero $hero --all-forms --models-only
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao gerar as transformacoes visuais de $hero."
    }

    $heroRoot = Join-Path $unitRoot $hero
    $baseFxsxml = Join-Path $heroRoot "Sayajin_${hero}.fxsxml"
    $baseAsset = [IO.File]::ReadAllText($baseFxsxml)
    foreach ($form in $forms) {
        $assetName = "Sayajin_${hero}_${form}"
        $png = Join-Path $heroRoot "${assetName}_DIFF.png"
        & $texconv -nologo -y -dx9 -f BC3_UNORM -m 0 -ft dds -o $heroRoot $png | Out-Null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $heroRoot "${assetName}_DIFF.dds"))) {
            throw "Falha ao converter a textura de $hero/$form para DDS."
        }

        $variantAsset = $baseAsset.Replace(
            "Sayajin_${hero}_Model.gr2", "${assetName}_Model.gr2"
        ).Replace(
            "Sayajin_${hero}_DIFF.dds", "${assetName}_DIFF.dds"
        )
        if ($hero -in @('Goku', 'Gohan')) {
            $triggerFile = switch ($form) {
                'PostModern' { 'FX_Triggers_Sayajin_Atomic.ftsxml' }
                'Future' { 'FX_Triggers_Sayajin_Nuclear.ftsxml' }
                default { 'FX_Triggers_Sayajin_Ranged.ftsxml' }
            }
            $variantAsset = $variantAsset.Replace(
                'FX_Triggers_Sayajin_Ranged.ftsxml', $triggerFile
            )
        }
        [IO.File]::WriteAllText((Join-Path $heroRoot "${assetName}.fxsxml"), $variantAsset, $utf8NoBom)
    }
}

& $modelBuilder -ProjectRoot $projectPath -Heroes $Heroes -FormsOnly
if ($LASTEXITCODE -ne 0) {
    throw 'Falha ao reconstruir os modelos GR2 das transformacoes.'
}

Write-Output "SAYAJIN_TRANSFORMATION_ART_OK heroes=$($Heroes.Count) forms=$($Heroes.Count * $forms.Count)"
