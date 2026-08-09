$ErrorActionPreference = 'Stop'

$nexusBuddy = 'E:\SteamLibrary\steamapps\common\Sid Meier''s Civilization V SDK\Nexus\x86\NexusBuddy2.exe'
$assembly = [Reflection.Assembly]::LoadFrom($nexusBuddy)
$flags = [Reflection.BindingFlags]'Public,NonPublic,Static,Instance,DeclaredOnly'

$assembly.GetTypes() |
    Where-Object {
        $_.FullName -match '(?i)gr2|br2|fbx|export|import|model|form1|mainwindow' -or
        ($_.GetMethods($flags) | Where-Object { $_.Name -match '(?i)ExportFBXFile' })
    } |
    ForEach-Object {
        $_.FullName
        $_.GetConstructors($flags) | ForEach-Object { '  CTOR ' + $_.ToString() }
        $_.GetMethods($flags) |
            ForEach-Object { '  METHOD ' + $_.ToString() }
    }
