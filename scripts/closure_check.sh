#!/bin/sh
# 闭合校验（机制自检，非 pre-commit 门禁）：核对"总量 = 已纳入 + 已忽略"与"总量 = 基线 - 消失"两本账
#
# 用法：
#   sh scripts/closure_check.sh                                  # 无参数：跳过（日常提交不受影响）
#   sh scripts/closure_check.sh total=974 included=639 ignored=335 baseline=1385 vanished=58
#   CLOSURE_TOTAL=974 CLOSURE_INCLUDED=639 CLOSURE_IGNORED=335 \
#     CLOSURE_BASELINE=1385 CLOSURE_VANISHED=58 sh scripts/closure_check.sh
#   sh scripts/closure_check.sh --strict total=... ...            # 不闭合时 exit 1
#   sh scripts/closure_check.sh --self-test                       # 内置正负样例自检
#
# 约定：
#   - 五项（total/included/ignored/baseline/vanished）必须全给或全不给；全不给即跳过。
#   - 参数形式 key=value，同名环境变量为 CLOSURE_<KEY>（大写），参数优先于环境变量。
#   - 校验 ① included + ignored = total；② total = baseline - vanished；非负整数，非法 exit 2。
#   - 默认模式不闭合只打印 [CLOSURE][WARN] 并 exit 0（不误伤日常提交）；--strict 才 exit 1。
#
# 重要：两个等式中的两数须来自**独立来源**（如"登记表计数"与"文件清单计数"），
#       若两边都从同一份数据推导，等式恒真，本校验就失去意义。
#
# 本脚本不挂 pre-commit（保持非阻断，日常提交零感知）。

usage() {
  cat <<'EOF'
用法：
  sh scripts/closure_check.sh [--strict] [--self-test] [total=N included=N ignored=N baseline=N vanished=N]
  CLOSURE_TOTAL=... CLOSURE_INCLUDED=... CLOSURE_IGNORED=... CLOSURE_BASELINE=... CLOSURE_VANISHED=...
说明：五项全给或全不给；无参数即跳过（exit 0）；非法输入 exit 2；--strict 时不闭合 exit 1。
EOF
}

is_nonneg() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
  esac
  return 0
}

# 返回：0 闭合；1 不闭合；2 参数非法
check_closure() {
  c_total=$1
  c_included=$2
  c_ignored=$3
  c_baseline=$4
  c_vanished=$5

  for pair in "total=$c_total" "included=$c_included" "ignored=$c_ignored" "baseline=$c_baseline" "vanished=$c_vanished"; do
    k=${pair%%=*}
    v=${pair#*=}
    if ! is_nonneg "$v"; then
      echo "[CLOSURE] 非法参数：$k=$v（须为非负整数）"
      return 2
    fi
  done

  bad=0
  sum=$((c_included + c_ignored))
  if [ "$sum" -ne "$c_total" ]; then
    echo "[CLOSURE][WARN] 不闭合①：included($c_included) + ignored($c_ignored) = $sum ≠ total($c_total)（差 $((c_total - sum))）"
    bad=1
  fi
  diff=$((c_baseline - c_vanished))
  if [ "$diff" -ne "$c_total" ]; then
    echo "[CLOSURE][WARN] 不闭合②：baseline($c_baseline) - vanished($c_vanished) = $diff ≠ total($c_total)（差 $((c_total - diff))）"
    bad=1
  fi

  if [ "$bad" -eq 0 ]; then
    echo "[CLOSURE] 闭合：total=$c_total = included($c_included) + ignored($c_ignored)；baseline($c_baseline) - vanished($c_vanished) = $c_total"
    return 0
  fi
  return 1
}

run_self_test() {
  st_fail=0
  st_run() {
    st_desc=$1
    st_expect=$2
    shift 2
    st_out=$(check_closure "$@" 2>&1)
    st_rc=$?
    if [ "$st_rc" -eq "$st_expect" ]; then
      echo "[CLOSURE][SELFTEST] PASS $st_desc（rc=$st_rc）"
    else
      echo "[CLOSURE][SELFTEST] FAIL $st_desc（期望 rc=$st_expect，实际 rc=$st_rc）"
      printf '%s\n' "$st_out"
      st_fail=1
    fi
  }

  # 正样例（≥3）：两本账都闭合
  st_run "正例1 小样本闭合"        0 10 6 4 12 2
  st_run "正例2 真实口径闭合"      0 974 639 335 1327 353
  st_run "正例3 全零边界"          0 0 0 0 0 0
  # 负样例（≥3）：含"漏一件导致差 1"
  st_run "负例1 漏一件导致差1"     1 10 6 3 10 0
  st_run "负例2 基线账不闭合"      1 10 6 4 11 0
  st_run "负例3 两本账同时不闭合"  1 9 6 4 12 1
  # 非法输入
  st_run "负例4 非整数"            2 abc 6 4 10 0
  st_run "负例5 负数"              2 -1 6 4 10 0

  if [ "$st_fail" -eq 0 ]; then
    echo "[CLOSURE] PASS self-test：3 正例 + 5 负例全部符合预期"
    return 0
  fi
  echo "[CLOSURE] FAIL self-test：样例结果与预期不符"
  return 1
}

strict=0
self_test=0
args_total=""
args_included=""
args_ignored=""
args_baseline=""
args_vanished=""

for a in "$@"; do
  case "$a" in
    --strict) strict=1 ;;
    --self-test) self_test=1 ;;
    -h|--help) usage; exit 0 ;;
    total=*) args_total=${a#total=} ;;
    included=*) args_included=${a#included=} ;;
    ignored=*) args_ignored=${a#ignored=} ;;
    baseline=*) args_baseline=${a#baseline=} ;;
    vanished=*) args_vanished=${a#vanished=} ;;
    *)
      echo "[CLOSURE] 未知参数：$a（只接受 total=/included=/ignored=/baseline=/vanished= 或 --strict/--self-test）" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$self_test" -eq 1 ]; then
  run_self_test
  exit $?
fi

env_set=0
[ "${CLOSURE_TOTAL+set}" = set ] && env_set=1
[ "${CLOSURE_INCLUDED+set}" = set ] && env_set=1
[ "${CLOSURE_IGNORED+set}" = set ] && env_set=1
[ "${CLOSURE_BASELINE+set}" = set ] && env_set=1
[ "${CLOSURE_VANISHED+set}" = set ] && env_set=1

total=$args_total
included=$args_included
ignored=$args_ignored
baseline=$args_baseline
vanished=$args_vanished

[ -z "$total" ] && [ "${CLOSURE_TOTAL+set}" = set ] && total=$CLOSURE_TOTAL
[ -z "$included" ] && [ "${CLOSURE_INCLUDED+set}" = set ] && included=$CLOSURE_INCLUDED
[ -z "$ignored" ] && [ "${CLOSURE_IGNORED+set}" = set ] && ignored=$CLOSURE_IGNORED
[ -z "$baseline" ] && [ "${CLOSURE_BASELINE+set}" = set ] && baseline=$CLOSURE_BASELINE
[ -z "$vanished" ] && [ "${CLOSURE_VANISHED+set}" = set ] && vanished=$CLOSURE_VANISHED

provided=0
[ -n "$total" ] && provided=$((provided + 1))
[ -n "$included" ] && provided=$((provided + 1))
[ -n "$ignored" ] && provided=$((provided + 1))
[ -n "$baseline" ] && provided=$((provided + 1))
[ -n "$vanished" ] && provided=$((provided + 1))

# 全不给（无数据参数且无环境变量）→ 跳过，避免误伤日常提交
if [ "$provided" -eq 0 ] && [ "$env_set" -eq 0 ]; then
  echo "[CLOSURE] 无参数，跳过"
  exit 0
fi

if [ "$provided" -ne 5 ]; then
  echo "[CLOSURE] 参数不全（已给 $provided/5）：五项必须全给或全不给" >&2
  usage >&2
  exit 2
fi

check_closure "$total" "$included" "$ignored" "$baseline" "$vanished"
rc=$?

case "$rc" in
  0) exit 0 ;;
  1)
    if [ "$strict" -eq 1 ]; then
      echo "[CLOSURE] --strict：不闭合，exit 1"
      exit 1
    fi
    exit 0
    ;;
  *) exit 2 ;;
esac
