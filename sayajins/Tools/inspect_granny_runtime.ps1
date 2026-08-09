$ErrorActionPreference = 'Stop'
$root = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
[Environment]::CurrentDirectory = $root
$env:Path = $root + [IO.Path]::PathSeparator + $env:Path

foreach ($name in @('Firaxis.Framework.dll', 'Firaxis.Framework.Granny.dll', 'Firaxis.Framework.Granny.ImplWin32.dll')) {
    $assembly = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $root $name))
    Write-Output ('ASSEMBLY ' + $assembly.FullName)
    foreach ($type in $assembly.GetTypes() | Where-Object { $_.Name -match 'Available|Context|GrannyContext|Impl|VirtualSpace|VirtualItem' }) {
        Write-Output ('TYPE ' + $type.FullName)
        foreach ($method in $type.GetMethods() | Where-Object { $_.Name -match 'Startup|Get|Add|Load' }) {
            Write-Output ('  ' + $method.ToString())
        }
        foreach ($ctor in $type.GetConstructors()) {
            Write-Output ('  CTOR ' + $ctor.ToString())
        }
    }
}
