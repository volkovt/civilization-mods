$ErrorActionPreference = 'Stop'
$root = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
[Environment]::CurrentDirectory = $root
$framework = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $root 'Firaxis.Framework.dll'))
$type = $framework.GetType('Firaxis.Framework.ReflectionHelper', $true)
$method = $type.GetMethod('ProxyAssembly', [Type[]]@([string]))
try {
    $result = $method.Invoke($null, [object[]]@('Firaxis.Framework.Granny.Impl'))
    Write-Output $result.FullName
}
catch {
    Write-Output $_.Exception.ToString()
    if ($_.Exception.InnerException) { Write-Output $_.Exception.InnerException.ToString() }
}
