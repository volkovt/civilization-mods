param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [string]$SdkNexusRoot = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
)

$ErrorActionPreference = 'Stop'

$sourcePath = (Resolve-Path -LiteralPath $SourceRoot).Path
$outputPath = [IO.Path]::GetFullPath($OutputRoot)
$sdkPath = (Resolve-Path -LiteralPath $SdkNexusRoot).Path
$nexusBuddyPath = Join-Path $sdkPath 'NexusBuddy2.exe'

if (-not (Test-Path -LiteralPath $nexusBuddyPath -PathType Leaf)) {
    throw "Nexus Buddy 2 não encontrado em $nexusBuddyPath"
}

[IO.Directory]::CreateDirectory($outputPath) | Out-Null
[Environment]::CurrentDirectory = $sdkPath
$env:Path = $sdkPath + [IO.Path]::PathSeparator + $env:Path

# Nexus Buddy already wraps the Firaxis FBX exporter. Resolve that method at
# runtime so the helper remains independent of a specific SDK assembly version.
$nexusAssembly = [Reflection.Assembly]::LoadFrom($nexusBuddyPath)
$wrapperType = $nexusAssembly.GetType('NexusBuddy.FileOps.FBXImporter', $true)
$wrapperMethod = $wrapperType.GetMethods() |
    Where-Object { $_.Name -eq 'ImportFBXFile' } |
    Select-Object -First 1
$il = $wrapperMethod.GetMethodBody().GetILAsByteArray()
$methodToken = [BitConverter]::ToInt32($il, 4)
$exportMethod = $wrapperMethod.Module.ResolveMethod($methodToken)

$converted = 0
$failed = @()
Get-ChildItem -LiteralPath $sourcePath -Filter '*.fbx' -File |
    Sort-Object Name |
    ForEach-Object {
        $sourceFile = [string]$_.FullName
        $destination = Join-Path $outputPath ([string]$_.BaseName + '.gr2')
        try {
            $arguments = [object[]]@($sourceFile, [string]$destination, $null)
            $success = [bool]$exportMethod.Invoke($null, $arguments)
            if (-not $success -or -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                throw 'o exportador retornou falha'
            }
            $converted++
            Write-Output ('GR2_OK ' + [IO.Path]::GetFileName($destination))
        }
        catch {
            $failed += $sourceFile
            Write-Error ('GR2_FAIL ' + $sourceFile + ': ' + $_.Exception.Message)
        }
    }

if ($failed.Count -gt 0) {
    throw ("Falharam {0} de {1} arquivos FBX." -f $failed.Count, ($converted + $failed.Count))
}

Write-Output ("GR2_BATCH_OK count={0} output={1}" -f $converted, $outputPath)
