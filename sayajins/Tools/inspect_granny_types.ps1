$ErrorActionPreference = 'Stop'
$root = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
[Environment]::CurrentDirectory = $root
$env:Path = $root + [IO.Path]::PathSeparator + $env:Path

foreach ($assemblyName in @('Firaxis.Framework.dll', 'Firaxis.Framework.Granny.dll')) {
    [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $root $assemblyName)) | Out-Null
}

$assembly = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $root 'Firaxis.Framework.Granny.dll'))
foreach ($name in @(
    'IGrannyFile', 'IGrannyModel', 'IGrannyMesh', 'IGrannyVertexData',
    'IGrannyTriTopology', 'IGrannyMaterial', 'IFGXParameterSet',
    'IFGXParameter', 'IGrannySkeleton', 'IGrannyBone', 'IGrannyTransform',
    'IGrannyAnimation', 'IGrannyTrackGroup', 'IGrannyTransformTrack'
)) {
    $type = $assembly.GetTypes() | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if (-not $type) { continue }
    Write-Output "TYPE $($type.FullName)"
    foreach ($property in $type.GetProperties()) {
        Write-Output "  PROPERTY $($property.PropertyType.FullName) $($property.Name)"
    }
    foreach ($method in $type.GetMethods() | Where-Object { -not $_.IsSpecialName }) {
        Write-Output "  METHOD $($method.ToString())"
    }
}
