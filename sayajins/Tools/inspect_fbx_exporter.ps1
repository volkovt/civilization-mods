$ErrorActionPreference = 'Stop'
$root = 'E:\SteamLibrary\steamapps\common\Sid Meier''s Civilization V SDK\Nexus\x86'
$nexus = [Reflection.Assembly]::LoadFrom((Join-Path $root 'NexusBuddy2.exe'))
$wrapper = $nexus.GetType('NexusBuddy.FileOps.FBXImporter').GetMethods() |
    Where-Object { $_.Name -eq 'ImportFBXFile' } | Select-Object -First 1
$il = $wrapper.GetMethodBody().GetILAsByteArray()
$token = [BitConverter]::ToInt32($il, 4)
$resolved = $wrapper.Module.ResolveMethod($token)
$assembly = $resolved.DeclaringType.Assembly
$type = $assembly.GetType('Firaxis.Framework.Export.GrannyExporterFBX')
$flags = [Reflection.BindingFlags]'Public,NonPublic,Static,Instance,DeclaredOnly'
$type.FullName
$type.GetMethods($flags) | ForEach-Object {
    $_.ToString()
    $_.GetParameters() | ForEach-Object {
        '  {0} {1}' -f $_.ParameterType.FullName, $_.Name
    }
    '  ImplFlags: ' + $_.MethodImplementationFlags
    '  Attributes: ' + $_.Attributes
}
