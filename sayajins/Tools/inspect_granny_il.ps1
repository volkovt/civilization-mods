$ErrorActionPreference = 'Stop'
$root = "E:\SteamLibrary\steamapps\common\Sid Meier's Civilization V SDK\Nexus\x86"
[Environment]::CurrentDirectory = $root
$framework = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $root 'Firaxis.Framework.dll'))
$assembly = [Reflection.Assembly]::UnsafeLoadFrom((Join-Path $root 'Firaxis.Framework.Granny.dll'))
$resourcesType = $assembly.GetType('Firaxis.Framework.Granny.Properties.Resources')
$proxyProperty = $resourcesType.GetProperty('ProxyModule', [Reflection.BindingFlags]'Public,NonPublic,Static')
Write-Output ('PROXY_MODULE=' + $proxyProperty.GetValue($null, $null))
$method = $assembly.GetType('Firaxis.Framework.Granny.GrannyContext').GetConstructors()[0]

$opcodes = @{}
[Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Public,Static') | ForEach-Object {
    $opcode = $_.GetValue($null)
    $opcodes[[int16]$opcode.Value] = $opcode
}

$bytes = $method.GetMethodBody().GetILAsByteArray()
$module = $method.Module
$offset = 0
while ($offset -lt $bytes.Length) {
    $start = $offset
    $value = [int]$bytes[$offset]
    $offset++
    if ($value -eq 0xfe) { $value = [int16](0xfe00 -bor [int]$bytes[$offset]); $offset++ }
    $opcode = $opcodes[[int16]$value]
    $operand = ''
    switch ($opcode.OperandType) {
        'InlineNone' { }
        'ShortInlineI' { $operand = [sbyte]$bytes[$offset]; $offset += 1 }
        'ShortInlineVar' { $operand = $bytes[$offset]; $offset += 1 }
        'InlineVar' { $operand = [BitConverter]::ToUInt16($bytes, $offset); $offset += 2 }
        'InlineI' { $operand = [BitConverter]::ToInt32($bytes, $offset); $offset += 4 }
        'InlineI8' { $operand = [BitConverter]::ToInt64($bytes, $offset); $offset += 8 }
        'ShortInlineR' { $operand = [BitConverter]::ToSingle($bytes, $offset); $offset += 4 }
        'InlineR' { $operand = [BitConverter]::ToDouble($bytes, $offset); $offset += 8 }
        'ShortInlineBrTarget' { $delta=[sbyte]$bytes[$offset]; $offset++; $operand=('IL_{0:x4}' -f ($offset+$delta)) }
        'InlineBrTarget' { $delta=[BitConverter]::ToInt32($bytes,$offset); $offset+=4; $operand=('IL_{0:x4}' -f ($offset+$delta)) }
        'InlineSwitch' { $count=[BitConverter]::ToInt32($bytes,$offset); $offset+=4+(4*$count); $operand="switch[$count]" }
        { $_ -in @('InlineString','InlineMethod','InlineField','InlineType','InlineTok','InlineSig') } {
            $token=[BitConverter]::ToInt32($bytes,$offset); $offset+=4
            try {
                if($opcode.OperandType -eq 'InlineString'){ $operand='"'+$module.ResolveString($token)+'"' }
                elseif($opcode.OperandType -eq 'InlineMethod'){ $resolved=$module.ResolveMethod($token); $operand=$resolved.DeclaringType.FullName+'::'+$resolved.ToString() }
                elseif($opcode.OperandType -eq 'InlineField'){ $operand=$module.ResolveField($token).ToString() }
                elseif($opcode.OperandType -eq 'InlineType'){ $operand=$module.ResolveType($token).ToString() }
                else { $operand=('token 0x{0:x8}' -f $token) }
            } catch { $operand=('token 0x{0:x8}' -f $token) }
        }
        default { $operand='<unsupported '+$opcode.OperandType+'>'; break }
    }
    'IL_{0:x4}: {1,-12} {2}' -f $start,$opcode.Name,$operand
}
