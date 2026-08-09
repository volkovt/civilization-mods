param(
    [string]$MethodName = 'cleardownTemplate',
    [string]$TypeName = 'NexusBuddy.FileOps.BR2Importer'
)

$ErrorActionPreference = 'Stop'
$nexusBuddy = Join-Path $PSScriptRoot 'granny-inspector\NexusBuddy2.exe'
$assembly = [Reflection.Assembly]::UnsafeLoadFrom($nexusBuddy)
$type = $assembly.GetType($TypeName, $true)
$method = $type.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Instance,Static') |
    Where-Object { $_.Name -eq $MethodName } | Select-Object -First 1
if (-not $method) { throw "Method not found: $MethodName" }

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
    $value = [int]$bytes[$offset++]
    if ($value -eq 0xfe) {
        $combined = 0xfe00 -bor [int]$bytes[$offset++]
        $value = if ($combined -gt 32767) { $combined - 65536 } else { $combined }
    }
    $opcode = $opcodes[[int16]$value]
    $operand = ''
    switch ($opcode.OperandType) {
        'InlineNone' { }
        'ShortInlineI' { $raw=[int]$bytes[$offset]; $operand=if($raw -gt 127){$raw-256}else{$raw}; $offset++ }
        'ShortInlineVar' { $operand = $bytes[$offset]; $offset++ }
        'InlineVar' { $operand = [BitConverter]::ToUInt16($bytes, $offset); $offset += 2 }
        'InlineI' { $operand = [BitConverter]::ToInt32($bytes, $offset); $offset += 4 }
        'InlineI8' { $operand = [BitConverter]::ToInt64($bytes, $offset); $offset += 8 }
        'ShortInlineR' { $operand = [BitConverter]::ToSingle($bytes, $offset); $offset += 4 }
        'InlineR' { $operand = [BitConverter]::ToDouble($bytes, $offset); $offset += 8 }
        'ShortInlineBrTarget' { $raw=[int]$bytes[$offset]; $delta=if($raw -gt 127){$raw-256}else{$raw}; $offset++; $operand=('IL_{0:x4}' -f ($offset+$delta)) }
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
