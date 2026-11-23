# triage_untracked.ps1 —— 未追踪文件分诊报告（Windows 辅助实现，只读）
#
# 定位：1385 治理的分诊器。只读报告，绝不执行 git add/commit/push。
# [P-041] 刻意不使用 `git status` 状态码（`-like '??*'` 会把 ' M' 误计为未跟踪），
#         统一改用 `git ls-files --others [--ignored] --exclude-standard`。
# 参数：-Base <N> 基数（上一次快照的未追踪总数）；-Vanished <N> 消失件数（默认 0）。
# 输出：一级目录统计、扩展名统计、>1MB 清单、按 .gitignore 分诊的「待入库/可忽略」，以及双算校验：
#       ① 入库 + 忽略 = 总数；② 总数 = 基数 - 消失件（给 -Base 时才校验）。
# 退出码：0＝报告完成（闭包不平只报告不阻断）；2＝git 环境或参数错误。
#
# 用法：
#   powershell -NoProfile -File scripts/triage_untracked.ps1 -Base 1390 -Vanished 5

[CmdletBinding(PositionalBinding = $false)]
param(
    [long]$Base,
    [long]$Vanished = 0
)

$ErrorActionPreference = 'Stop'
$LargeThreshold = [long]1048576

function Invoke-GitLines {
    param([string]$Root, [string[]]$GitArgs)
    $out = & git -C $Root @GitArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw ("git {0} 失败（exit {1}）" -f ($GitArgs -join ' '), $LASTEXITCODE)
    }
    return @($out)
}

function Get-TopLevel {
    param([string]$Path)
    $p = $Path -replace '\\', '/'
    $i = $p.IndexOf('/')
    if ($i -lt 0) { return '(根目录)' }
    return $p.Substring(0, $i)
}

function Get-Extension {
    param([string]$Path)
    $name = [System.IO.Path]::GetFileName($Path)
    $ext = [System.IO.Path]::GetExtension($name)
    if ([string]::IsNullOrEmpty($ext)) { return '(无扩展名)' }
    return $ext.ToLowerInvariant()
}

try {
    if ($Base -lt 0) { throw '参数 Base 不得为负数' }
    if ($Vanished -lt 0) { throw '参数 Vanished 不得为负数' }

    $root = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($root)) {
        throw '当前目录不在 git 工作区内'
    }
    $root = $root.Trim()

    $candidates = Invoke-GitLines -Root $root -GitArgs @('-c', 'core.quotePath=false', 'ls-files', '--full-name', '--others', '--exclude-standard')
    $ignored = Invoke-GitLines -Root $root -GitArgs @('-c', 'core.quotePath=false', 'ls-files', '--full-name', '--others', '--ignored', '--exclude-standard')

    $all = @()
    foreach ($p in $candidates) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $all += [pscustomobject]@{ Path = $p; Kind = '待入库' }
    }
    foreach ($p in $ignored) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $all += [pscustomobject]@{ Path = $p; Kind = '可忽略' }
    }

    $total = $all.Count
    $includedCount = @($all | Where-Object { $_.Kind -eq '待入库' }).Count
    $ignoredCount = @($all | Where-Object { $_.Kind -eq '可忽略' }).Count

    Write-Host '[TRIAGE] 未追踪文件分诊报告（只读，不执行 git add/commit/push）'
    Write-Host ("[TRIAGE] 仓库：{0}" -f $root)
    Write-Host ("[TRIAGE] 未追踪总数：{0}（待入库 {1} / 可忽略 {2}）" -f $total, $includedCount, $ignoredCount)
    Write-Host ''

    Write-Host '[TRIAGE] 一、按一级目录统计'
    $byDir = $all |
        Group-Object { Get-TopLevel $_.Path } |
        Sort-Object Name |
        ForEach-Object {
            [pscustomobject]@{
                '一级目录' = $_.Name
                '待入库' = @($_.Group | Where-Object { $_.Kind -eq '待入库' }).Count
                '可忽略' = @($_.Group | Where-Object { $_.Kind -eq '可忽略' }).Count
                '合计' = $_.Count
            }
        }
    if (@($byDir).Count -eq 0) {
        Write-Host '(无未追踪文件)'
    } else {
        $byDir | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
    }

    Write-Host '[TRIAGE] 二、按扩展名统计'
    $byExt = $all |
        Group-Object { Get-Extension $_.Path } |
        Sort-Object { $_.Count } -Descending |
        ForEach-Object {
            [pscustomobject]@{
                '扩展名' = $_.Name
                '待入库' = @($_.Group | Where-Object { $_.Kind -eq '待入库' }).Count
                '可忽略' = @($_.Group | Where-Object { $_.Kind -eq '可忽略' }).Count
                '合计' = $_.Count
            }
        }
    if (@($byExt).Count -eq 0) {
        Write-Host '(无未追踪文件)'
    } else {
        $byExt | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
    }

    Write-Host '[TRIAGE] 三、>1MB 清单'
    $large = @()
    foreach ($item in $all) {
        $full = Join-Path $root $item.Path
        $fi = Get-Item -LiteralPath $full -ErrorAction SilentlyContinue
        if ($null -ne $fi -and $fi.Length -gt $LargeThreshold) {
            $large += [pscustomobject]@{
                '大小MB' = [math]::Round($fi.Length / 1MB, 2)
                '分诊' = $item.Kind
                '路径' = $item.Path
            }
        }
    }
    if ($large.Count -eq 0) {
        Write-Host '(无大于 1MB 的未追踪文件)'
    } else {
        $large | Sort-Object '大小MB' -Descending | Format-Table -AutoSize | Out-String -Width 240 | Write-Host
    }

    Write-Host '[TRIAGE] 四、按 .gitignore 分诊'
    Write-Host ("  可忽略（命中 .gitignore）：{0} 件" -f $ignoredCount)
    Write-Host ("  待入库（未被忽略）：{0} 件" -f $includedCount)

    Write-Host '[TRIAGE] 五、双算校验'
    $eq1 = (($includedCount + $ignoredCount) -eq $total)
    $mark1 = if ($eq1) { 'OK' } else { 'MISMATCH' }
    Write-Host ("  ① 入库+忽略=总数：{0}+{1}={2} 目标 {3} [{4}]" -f $includedCount, $ignoredCount, ($includedCount + $ignoredCount), $total, $mark1)

    if ($PSBoundParameters.ContainsKey('Base')) {
        $expected = $Base - $Vanished
        $eq2 = ($total -eq $expected)
        $mark2 = if ($eq2) { 'OK' } else { 'MISMATCH' }
        Write-Host ("  ② 总数=基数-消失件：{0}-{1}={2} 目标 {3} [{4}]" -f $Base, $Vanished, $expected, $total, $mark2)
    } else {
        Write-Host '  ② 未提供 -Base，跳过（基数-消失件校验）'
    }

    exit 0
}
catch {
    Write-Host ("[TRIAGE] 错误：{0}" -f $_.Exception.Message)
    exit 2
}
