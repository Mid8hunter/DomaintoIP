#!/usr/bin/env bash
# dotoip.sh - Resolve domain(s) to only IPs (A/AAAA) using dnsx, save to dotoip.txt
# Usage:
#   ./dotoip.sh example.com
#   ./dotoip.sh -l domains.txt
# Options:
#   -l FILE   Read domains from FILE (one per line)
#   -r RES    Custom DNS resolver (e.g., 1.1.1.1:53). Repeatable.
#   -T N      Threads/concurrency for dnsx (default 200, maps to -t)
#   -R N      Rate limit requests per second (optional, dnsx -rl)
#   -4        IPv4 only (A records)
#   -6        IPv6 only (AAAA records)
#   -o FILE   Output filename (default dotoip.txt)
#   -h        Help

set -euo pipefail

THREADS=200
RATE="-1"
RESOLVERS=()
LIST=""
OUT="dotoip.txt"
ONLY4=0
ONLY6=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
  grep -E '^# ' "$0" | sed 's/^# //'
  exit 1
}

while getopts ":l:r:T:R:o:46h" opt; do
  case "$opt" in
    l) LIST="$OPTARG" ;;
    r) RESOLVERS+=("$OPTARG") ;;
    T) THREADS="$OPTARG" ;;
    R) RATE="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    4) ONLY4=1 ;;
    6) ONLY6=1 ;;
    h) usage ;;
    \?) echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2; usage ;;
    :) echo -e "${RED}Option -$OPTARG requires an argument.${NC}" >&2; usage ;;
  esac
done
shift $((OPTIND-1))

# Collect input domains
INPUT_DOMAINS=()
if [[ -n "$LIST" ]]; then
  [[ -f "$LIST" ]] || { echo -e "${RED}File not found: $LIST${NC}" >&2; exit 1; }
  mapfile -t FILE_DOMAINS < <(grep -v '^\s*$' "$LIST" | sed 's/\r$//')
  INPUT_DOMAINS+=("${FILE_DOMAINS[@]}")
fi
if [[ $# -gt 0 ]]; then
  INPUT_DOMAINS+=("$@")
fi
if [[ ${#INPUT_DOMAINS[@]} -eq 0 ]]; then
  echo -e "${RED}Provide a domain or -l file.${NC}" >&2
  usage
fi

# Build dnsx flags (use -ro only)
DNSX_FLAGS=(-silent -ro -t "$THREADS")

if [[ $ONLY4 -eq 1 && $ONLY6 -eq 1 ]]; then
  DNSX_FLAGS+=(-a -aaaa)
elif [[ $ONLY4 -eq 1 ]]; then
  DNSX_FLAGS+=(-a)
elif [[ $ONLY6 -eq 1 ]]; then
  DNSX_FLAGS+=(-aaaa)
else
  DNSX_FLAGS+=(-a -aaaa)
fi

[[ "$RATE" != "-1" ]] && DNSX_FLAGS+=(-rl "$RATE")
if [[ ${#RESOLVERS[@]} -gt 0 ]]; then
  DNSX_FLAGS+=(-r "$(IFS=','; echo "${RESOLVERS[*]}")")
fi

# Fancy header
echo -e "${CYAN}🔍 Domain → IP Resolver${NC}"
echo -e "      ${YELLOW}Powered by dnsx | Author: GD${NC}\n"

# Start resolving
echo -e "${GREEN}[+] Resolving ${#INPUT_DOMAINS[@]} domain(s) → $OUT (threads=$THREADS rate=$RATE)${NC}"

dnsx "${DNSX_FLAGS[@]}" -l <(printf "%s\n" "${INPUT_DOMAINS[@]}") \
  | awk '
      /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/ { print; next }   # IPv4
      /^[0-9A-Fa-f:]+$/ { print }                       # IPv6
    ' \
  | sort -u > "$OUT"

COUNT=$(wc -l < "$OUT" | tr -d " ")
echo -e "${GREEN}[+] Saved $COUNT unique IP(s) → $OUT${NC}"
