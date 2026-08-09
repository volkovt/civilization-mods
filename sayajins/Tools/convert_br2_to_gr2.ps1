param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Destination,

    [string]$SdkNexusRoot = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
)

$ErrorActionPreference = 'Stop'
trap {
    Write-Error $_.InvocationInfo.PositionMessage
    throw
}
$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$destinationPath = [IO.Path]::GetFullPath($Destination)
$sdkPath = (Resolve-Path -LiteralPath $SdkNexusRoot).Path
$nexusBuddyPath = Join-Path $sdkPath 'NexusBuddy2.exe'

[IO.Directory]::CreateDirectory((Split-Path -Parent $destinationPath)) | Out-Null
[Environment]::CurrentDirectory = $sdkPath
$env:Path = $sdkPath + [IO.Path]::PathSeparator + $env:Path

$nexusAssembly = [Reflection.Assembly]::UnsafeLoadFrom($nexusBuddyPath)
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
$frameworkContextType = $frameworkAssembly.GetType('Firaxis.Framework.Context', $true)
$virtualSpaceType = $frameworkAssembly.GetType('Firaxis.Framework.VirtualSpace', $true)
$virtualSpace = [Activator]::CreateInstance($virtualSpaceType)
$frameworkContextType.GetMethod('Add').Invoke($null, [object[]]@($virtualSpace)) | Out-Null
$contextType = $grannyAssembly.GetType('Firaxis.Framework.Granny.GrannyContext', $true)
$context = [Activator]::CreateInstance($contextType)
$importerType = $nexusAssembly.GetType('NexusBuddy.FileOps.BR2Importer', $true)
$importer = [Activator]::CreateInstance($importerType)
$method = $importerType.GetMethod('importBR2')
$method.Invoke($importer, [object[]]@($sourcePath, $destinationPath, $context)) | Out-Null

if (-not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
    throw "Nexus Buddy nao criou o GR2 esperado: $destinationPath"
}

$file = Get-Item -LiteralPath $destinationPath
Write-Output ("BR2_GR2_OK source={0} output={1} bytes={2}" -f
    [IO.Path]::GetFileName($sourcePath), $file.Name, $file.Length)
