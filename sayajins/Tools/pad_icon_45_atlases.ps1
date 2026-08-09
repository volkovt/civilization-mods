param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Texconv = 'D:\Mods civ5 pessoal\tools\texconv.exe'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectPath = [IO.Path]::GetFullPath($ProjectRoot)
$tempRoot = Join-Path $projectPath 'BuildValidation\Icon45Padding'
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null

if (-not (Test-Path -LiteralPath $Texconv -PathType Leaf)) {
    throw "texconv.exe nao encontrado: $Texconv"
}

$files = @(
    Get-ChildItem -LiteralPath (Join-Path $projectPath 'ART') -File -Filter '*_45.dds'
    Get-ChildItem -LiteralPath (Join-Path $projectPath 'ART\Heroes') -File -Filter '*_45.dds'
)

foreach ($file in $files) {
    & $Texconv -nologo -y -ft png -m 1 -o $tempRoot $file.FullName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao decodificar $($file.FullName)"
    }

    $decoded = Join-Path $tempRoot ($file.BaseName + '.png')
    $padded = Join-Path $tempRoot ($file.BaseName + '.padded.png')
    $source = [Drawing.Bitmap]::FromFile($decoded)
    try {
        $canvas = New-Object Drawing.Bitmap 48, 48, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [Drawing.Graphics]::FromImage($canvas)
            try {
                $graphics.Clear([Drawing.Color]::Transparent)
                $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.DrawImageUnscaled($source, 0, 0)
            }
            finally {
                $graphics.Dispose()
            }
            $canvas.Save($padded, [Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $canvas.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }

    $conversionInput = Join-Path $tempRoot ($file.BaseName + '.png')
    Copy-Item -LiteralPath $padded -Destination $conversionInput -Force
    & $Texconv -nologo -y -dx9 -f BC3_UNORM -m 0 -ft dds -o $file.DirectoryName $conversionInput | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao reconstruir $($file.FullName)"
    }
    Write-Output ("ICON45_OK file={0} physical=48x48 logical=45x45" -f $file.Name)
}

Write-Output ("ICON45_BATCH_OK count={0}" -f $files.Count)
