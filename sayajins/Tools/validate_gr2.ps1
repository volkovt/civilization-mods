param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$SdkNexusRoot = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
)

$ErrorActionPreference = 'Stop'
$sdkPath = (Resolve-Path -LiteralPath $SdkNexusRoot).Path
$targetPath = (Resolve-Path -LiteralPath $Path).Path
[Environment]::CurrentDirectory = $sdkPath
$env:Path = $sdkPath + [IO.Path]::PathSeparator + $env:Path

$frameworkAssembly = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $sdkPath 'Firaxis.Framework.dll'))
$grannyAssembly = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $sdkPath 'Firaxis.Framework.Granny.dll'))
$implAssembly = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $sdkPath 'Firaxis.Framework.Granny.ImplWin32.dll'))
$resolveHandler = [ResolveEventHandler]{
    param($sender, $eventArgs)
    if ($eventArgs.Name.StartsWith('Firaxis.Framework.Granny.Impl,')) {
        return $implAssembly
    }
    return $null
}
[AppDomain]::CurrentDomain.add_AssemblyResolve($resolveHandler)
$contextType = $grannyAssembly.GetType('Firaxis.Framework.Granny.GrannyContext', $true)
$context = [Activator]::CreateInstance($contextType)
$loadMethod = $contextType.GetMethod('LoadGrannyFile', [Type[]]@([string]))

$files = @()
if (Test-Path -LiteralPath $targetPath -PathType Container) {
    $files = @(Get-ChildItem -LiteralPath $targetPath -Filter '*.gr2' -File | Sort-Object Name)
}
else {
    $files = @((Get-Item -LiteralPath $targetPath))
}

$invalid = 0
foreach ($item in $files) {
    try {
        $grannyFile = $loadMethod.Invoke($context, [object[]]@([string]$item.FullName))
        $modelCount = [int]$grannyFile.Models.Count
        $animationCount = [int]$grannyFile.Animations.Count
        $meshCount = [int]$grannyFile.Meshes.Count
        $materialCount = [int]$grannyFile.Materials.Count
        $boneCount = 0
        if ($modelCount -gt 0 -and $null -ne $grannyFile.Models[0].Skeleton) {
            $boneCount = [int]$grannyFile.Models[0].Skeleton.Bones.Count
        }
        $duration = 0.0
        if ($animationCount -gt 0) {
            $duration = [double]$grannyFile.Animations[0].Duration
        }
        Write-Output ("GR2_VALID file={0} models={1} meshes={2} materials={3} bones={4} animations={5} duration={6:N3}" -f $item.Name, $modelCount, $meshCount, $materialCount, $boneCount, $animationCount, $duration)
    }
    catch {
        $invalid++
        Write-Output ("GR2_INVALID file={0} error={1}" -f $item.Name, $_.Exception.Message)
    }
}

if ($invalid -gt 0) {
    throw ("{0} arquivo(s) GR2 inválido(s)." -f $invalid)
}
Write-Output ("GR2_VALIDATION_OK count={0}" -f $files.Count)
