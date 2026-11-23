# closure_check.ps1 —— 闭合校验（Windows 辅助实现）
#
# 规范实现：scripts/closure_check.sh。本文件仅 Windows 辅助，参数、语义、退出码与 fixtures
# 必须与 sh 版逐项对拍一致；任何差异以 sh 版为准。
#
# 参数：-Total/-Included/-Ignored/-Baseline/-Vanished，或 key=value（total=… included=… 等）；
#       也可用环境变量 CLOSURE_TOTAL / CLOSURE_INCLUDED / CLOSURE_IGNORED / CLOSURE_BASELINE / CLOSURE_VANISHED。
# 约定：五项必须全给或全不给；全不给即跳过（exit 0）。
# 校验：① included + ignored = total；② total = baseline - vanished；非负整数。
# 退出码：0＝闭合或默认告警跳过；1＝-Strict 下不闭合（含 SelfTest 失败）；2＝参数非法/不全。
# 默认只打印 [CLOSURE][WARN] 不阻断，-Strict 才 exit 1。
#
# 用法：
#   powershell -NoProfile -File scripts/closure_check.ps1 -Total 100 -Included 60 -Ignored 40 -Baseline 120 -Vanished 20
#   powershell -NoProfile -File scripts/closure_check.ps1 total=100 included=60 ignored=40 baseline=120 vanished=20 -Strict
#   powershell -NoProfile -File scripts/closure_check.ps1 -SelfTest

[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$Total = '',
    [string]$Included = '',
    [string]$Ignored = '',
    [string]$Baseline = '',
    [string]$Vanished = '',
    [switch]$Strict,
    [switch]$SelfTest,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

$ErrorActionPreference = 'Stop'

function Write-Usage {
    Write-Host '用法：'
    Write-Host '  powershell -NoProfile -File scripts/closure_check.ps1 [-Strict] [-SelfTest] [total=N included=N ignored=N baseline=N vanished=N]'
    Write-Host '  CLOSURE_TOTAL=... CLOSURE_INCLUDED=... CLOSURE_IGNORED=... CLOSURE_BASELINE=... CLOSURE_VANISHED=...'
    Write-Host '说明：五项全给或全不给；无参数即跳过（exit 0）；非法输入 exit 2；-Strict 时不闭合 exit 1。'
}

function Resolve-Key {
    param([string]$Raw)
    $k = ($Raw.Trim() -replace '^--?', '').ToLowerInvariant()
    switch ($k) {
        'total' { return 'Total' }
        'included' { return 'Included' }
        'ignored' { return 'Ignored' }
        'baseline' { return 'Baseline' }
        'vanished' { return 'Vanished' }
        default { return $null }
    }
}

# 返回：0 闭合；1 不闭合；2 参数非法（与 sh 版 check_closure 一致）
function Invoke-ClosureCheck {
    param([string]$T, [string]$I, [string]$G, [string]$B, [string]$V)

    $parsed = @{}
    foreach ($pair in @(
            @{ K = 'total'; V = $T },
            @{ K = 'included'; V = $I },
            @{ K = 'ignored'; V = $G },
            @{ K = 'baseline'; V = $B },
            @{ K = 'vanished'; V = $V })) {
        $n = [long]0
        if (-not [long]::TryParse(([string]$pair.V), [ref]$n) -or $n -lt 0) {
            Write-Host ("[CLOSURE] 非法参数：{0}={1}（须为非负整数）" -f $pair.K, $pair.V)
            return 2
        }
        $parsed[$pair.K] = $n
    }

    $bad = 0
    $sum = $parsed['included'] + $parsed['ignored']
    if ($sum -ne $parsed['total']) {
        Write-Host ("[CLOSURE][WARN] 不闭合①：included({0}) + ignored({1}) = {2} ≠ total({3})（差 {4}）" -f $parsed['included'], $parsed['ignored'], $sum, $parsed['total'], ($parsed['total'] - $sum))
        $bad = 1
    }
    $diff = $parsed['baseline'] - $parsed['vanished']
    if ($diff -ne $parsed['total']) {
        Write-Host ("[CLOSURE][WARN] 不闭合②：baseline({0}) - vanished({1}) = {2} ≠ total({3})（差 {4}）" -f $parsed['baseline'], $parsed['vanished'], $diff, $parsed['total'], ($parsed['total'] - $diff))
        $bad = 1
    }

    if ($bad -eq 0) {
        Write-Host ("[CLOSURE] 闭合：total={0} = included({1}) + ignored({2})；baseline({3}) - vanished({4}) = {0}" -f $parsed['total'], $parsed['included'], $parsed['ignored'], $parsed['baseline'], $parsed['vanished'])
        return 0
    }
    return 1
}

function Invoke-SelfTest {
    $fail = 0

    # 与 sh 版 run_self_test 同一组 fixtures（3 正例 + 5 负例）。
    $cases = @(
        [pscustomobject]@{ Desc = '正例1 小样本闭合'; Expect = 0; Args = @('10', '6', '4', '12', '2') },
        [pscustomobject]@{ Desc = '正例2 真实口径闭合'; Expect = 0; Args = @('974', '639', '335', '1327', '353') },
        [pscustomobject]@{ Desc = '正例3 全零边界'; Expect = 0; Args = @('0', '0', '0', '0', '0') },
        [pscustomobject]@{ Desc = '负例1 漏一件导致差1'; Expect = 1; Args = @('10', '6', '3', '10', '0') },
        [pscustomobject]@{ Desc = '负例2 基线账不闭合'; Expect = 1; Args = @('10', '6', '4', '11', '0') },
        [pscustomobject]@{ Desc = '负例3 两本账同时不闭合'; Expect = 1; Args = @('9', '6', '4', '12', '1') },
        [pscustomobject]@{ Desc = '负例4 非整数'; Expect = 2; Args = @('abc', '6', '4', '10', '0') },
        [pscustomobject]@{ Desc = '负例5 负数'; Expect = 2; Args = @('-1', '6', '4', '10', '0') }
    )

    foreach ($c in $cases) {
        $rc = Invoke-ClosureCheck -T $c.Args[0] -I $c.Args[1] -G $c.Args[2] -B $c.Args[3] -V $c.Args[4] 6>$null
        if ($rc -eq $c.Expect) {
            Write-Host ("[CLOSURE][SELFTEST] PASS {0}（rc={1}）" -f $c.Desc, $rc)
        } else {
            Write-Host ("[CLOSURE][SELFTEST] FAIL {0}（期望 rc={1}，实际 rc={2}）" -f $c.Desc, $c.Expect, $rc)
            $fail = 1
        }
    }

    if ($fail -eq 0) {
        Write-Host '[CLOSURE] PASS self-test：3 正例 + 5 负例全部符合预期'
        return 0
    }
    Write-Host '[CLOSURE] FAIL self-test：样例结果与预期不符'
    return 1
}

try {
    $values = @{}
    foreach ($k in @('Total', 'Included', 'Ignored', 'Baseline', 'Vanished')) {
        if ($PSBoundParameters.ContainsKey($k)) {
            $values[$k] = [string]$PSBoundParameters[$k]
        }
    }

    $envSet = 0
    foreach ($k in @('Total', 'Included', 'Ignored', 'Baseline', 'Vanished')) {
        $envName = 'CLOSURE_' + $k.ToUpperInvariant()
        if (Test-Path ("Env:" + $envName)) {
            $envSet = 1
            if (-not $values.ContainsKey($k) -or [string]::IsNullOrEmpty($values[$k])) {
                $values[$k] = [string](Get-Item ("Env:" + $envName)).Value
            }
        }
    }

    foreach ($token in @($Rest)) {
        if ([string]::IsNullOrWhiteSpace($token)) { continue }
        $t = $token.Trim()
        $lower = $t.ToLowerInvariant()
        if ($lower -match '^-{0,2}strict$') { $Strict = $true; continue }
        if ($lower -match '^-{0,2}self-?test$') { $SelfTest = $true; continue }
        if ($lower -match '^-{0,2}(h|help)$') { Write-Usage; exit 0 }

        $pos = $t.IndexOf('=')
        if ($pos -le 0) {
            Write-Host ("[CLOSURE] 未知参数：{0}（只接受 total=/included=/ignored=/baseline=/vanished= 或 -Strict/-SelfTest）" -f $t)
            Write-Usage
            exit 2
        }
        $key = Resolve-Key -Raw $t.Substring(0, $pos)
        if ($null -eq $key) {
            Write-Host ("[CLOSURE] 未知参数：{0}" -f $t)
            Write-Usage
            exit 2
        }
        $values[$key] = $t.Substring($pos + 1)
    }

    if ($SelfTest) {
        exit (Invoke-SelfTest)
    }

    $provided = 0
    foreach ($k in @('Total', 'Included', 'Ignored', 'Baseline', 'Vanished')) {
        if ($values.ContainsKey($k) -and -not [string]::IsNullOrEmpty($values[$k])) { $provided++ }
    }

    if ($provided -eq 0 -and $envSet -eq 0) {
        Write-Host '[CLOSURE] 无参数，跳过'
        exit 0
    }

    if ($provided -ne 5) {
        Write-Host ("[CLOSURE] 参数不全（已给 {0}/5）：五项必须全给或全不给" -f $provided)
        Write-Usage
        exit 2
    }

    $rc = Invoke-ClosureCheck -T $values['Total'] -I $values['Included'] -G $values['Ignored'] -B $values['Baseline'] -V $values['Vanished']

    switch ($rc) {
        0 { exit 0 }
        1 {
            if ($Strict) {
                Write-Host '[CLOSURE] -Strict：不闭合，exit 1'
                exit 1
            }
            exit 0
        }
        default { exit 2 }
    }
}
catch {
    Write-Host ("[CLOSURE] 参数错误：{0}" -f $_.Exception.Message)
    Write-Usage
    exit 2
}
