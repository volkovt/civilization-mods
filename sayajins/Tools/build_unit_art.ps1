param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet('Vegeta', 'Goku', 'Gohan', 'Piccolo', 'Broly')]
    [string[]]$Heroes = @('Vegeta', 'Goku', 'Gohan', 'Piccolo', 'Broly'),
    [switch]$FormsOnly
)

$ErrorActionPreference = 'Stop'

$projectPath = [IO.Path]::GetFullPath($ProjectRoot)
$stagingRoot = Join-Path $projectPath 'BuildValidation\Civ5BaseHuman'
$materialTool = Join-Path $PSScriptRoot 'granny-inspector\GrannyUnitMaterial.exe'
$inspectorTool = Join-Path $PSScriptRoot 'granny-inspector\GrannyInspector.exe'
$br2ConverterTool = Join-Path $PSScriptRoot 'granny-inspector\GrannyBR2Converter.exe'
$cn6ExporterTool = Join-Path $PSScriptRoot 'granny-inspector\GrannyCN6Exporter.exe'
$materialTemplate = Join-Path $PSScriptRoot 'granny-inspector\UnitShaderTemplate.gr2'
$baseHumanTemplate = Join-Path $PSScriptRoot 'granny-inspector\Civ5BaseHumanTemplate.gr2'
$blender279 = Join-Path $PSScriptRoot 'blender-2.79-portable\blender-2.79b-windows64\blender.exe'
$retargetScript = Join-Path $PSScriptRoot 'export_model_on_civ5_skeleton_279.py'
$cn6Importer = Join-Path $PSScriptRoot 'Civilization-Blender-Scripts-16.40\Civilization-Blender-Scripts-16.40\Blender-2.7-Addons\io_import_cn6.py'
$br2Exporter = Join-Path $PSScriptRoot 'Civilization-Blender-Scripts-16.40\Civilization-Blender-Scripts-16.40\Blender-2.7-Addons\io_export_br2.py'

foreach ($required in @(
        $materialTool, $inspectorTool, $br2ConverterTool, $cn6ExporterTool,
        $materialTemplate, $baseHumanTemplate, $blender279, $retargetScript,
        $cn6Importer, $br2Exporter
    )) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Ferramenta obrigatoria nao encontrada: $required"
    }
}

[IO.Directory]::CreateDirectory($stagingRoot) | Out-Null
$stagedTemplate = Join-Path $stagingRoot 'Civ5BaseHumanTemplate.gr2'
$stagedCn6 = Join-Path $stagingRoot 'Civ5BaseHumanTemplate.cn6'
Copy-Item -LiteralPath $baseHumanTemplate -Destination $stagedTemplate -Force
& $cn6ExporterTool $stagedTemplate
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $stagedCn6 -PathType Leaf)) {
    throw 'Falha ao extrair o esqueleto humano comprovado do Civ V.'
}

$forms = @('Classical', 'Medieval', 'Renaissance', 'Industrial', 'Modern', 'PostModern', 'Future')
$builtModels = 0

foreach ($hero in $Heroes) {
    $unitRoot = Join-Path $projectPath "ART\Units\$hero"
    $sourceRoot = Join-Path $unitRoot 'Source'
    $variants = if ($FormsOnly) {
        if ($hero -eq 'Piccolo') { @() } else { $forms }
    } else {
        @('')
    }

    foreach ($form in $variants) {
        $assetName = "Sayajin_${hero}" + $(if ($form) { "_${form}" } else { '' })
        $variantLabel = if ($form) { $form } else { 'Base' }
        $heroStaging = Join-Path (Join-Path $stagingRoot $hero) $variantLabel
        [IO.Directory]::CreateDirectory($heroStaging) | Out-Null

        $sourceModel = Join-Path $sourceRoot "${assetName}_Model.fbx"
        $texture = Join-Path $unitRoot "${assetName}_DIFF.dds"
        foreach ($required in @($sourceModel, $texture)) {
            if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
                throw "Arte de origem ausente: $required"
            }
        }

        $br2 = Join-Path $heroStaging "${assetName}_Civ5Skeleton.br2"
        $rawModel = Join-Path $heroStaging "${assetName}_Civ5Skeleton.gr2"
        $finalModel = Join-Path $unitRoot "${assetName}_Model.gr2"
        $materializedModel = Join-Path $heroStaging "${assetName}_Final.gr2"

        & $blender279 --background --python $retargetScript -- `
            $stagedCn6 $sourceModel $br2 $cn6Importer $br2Exporter
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $br2 -PathType Leaf)) {
            throw "Falha ao encaixar $hero/$variantLabel no esqueleto humano do Civ V."
        }

        & $br2ConverterTool $stagedTemplate $br2 $rawModel
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $rawModel -PathType Leaf)) {
            throw "Falha ao gerar o conteiner GR2 nativo de $hero/$variantLabel."
        }

        & $materialTool $rawModel $materializedModel $materialTemplate $texture
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $materializedModel -PathType Leaf)) {
            throw "Falha ao aplicar o material do Civ V em $hero/$variantLabel."
        }
        Copy-Item -LiteralPath $materializedModel -Destination $finalModel -Force

        $inspection = @(& $inspectorTool $finalModel --details)
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao inspecionar o modelo final de $hero/$variantLabel."
        }

        $escapedAssetName = [Regex]::Escape($assetName)
        $modelPattern = "file=${escapedAssetName}_Model\.gr2 models=1 meshes=1 materials=1 bones=25 animations=0 .*shaders=UnitShader_Skinned"
        if (-not ($inspection -match $modelPattern)) {
            throw "O modelo de $hero/$variantLabel nao reteve o conteiner humano, o material ou o shader do Civ V."
        }
        foreach ($boneName in @(
                'Dummy_WORLD', 'CHARACTER_REORIENT', 'Base HumanPelvis',
                'Base HumanRibcage', 'Base HumanLUpperarm', 'Base HumanRUpperarm',
                'Base HumanLThigh', 'Base HumanRThigh', 'Base HumanNeck2'
            )) {
            if (-not ($inspection -match "name=$([Regex]::Escape($boneName)) ")) {
                throw "O osso obrigatorio '$boneName' esta ausente em $hero/$variantLabel."
            }
        }
        if (-not ($inspection -match "values=${escapedAssetName}_DIFF\.dds\|Infantry_SREF\.dds")) {
            throw "A textura final de $hero/$variantLabel nao ficou ligada ao material da unidade."
        }

        $inspection | Write-Output
        $builtModels++
        Write-Output "SAYAJIN_CIV5_SKELETON_OK hero=$hero form=$variantLabel bones=25 animations=InfantryNative"
    }
}

Write-Output "SAYAJIN_UNIT_ART_BATCH_OK heroes=$($Heroes.Count) models=$builtModels formsOnly=$FormsOnly skeleton=Civ5BaseHuman animations=InfantryNative"
