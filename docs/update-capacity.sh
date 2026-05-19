#!/usr/bin/env bash
# Queries each lab host for vCPU and RAM, then prints a Markdown host capacity
# table for the "Host Capacity Table" section of docs/lab-authoring.md.
#
# Usage:
#   bash docs/update-capacity.sh
#
# Hosts are read from ansible/inventory.yml. Override with positional args:
#   bash docs/update-capacity.sh lab-01=100.110.163.67 lab-02=100.122.128.16
#
# Requirements: ssh access as root (or ansible_user) to each host.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INVENTORY="$REPO_ROOT/ansible/inventory.yml"

# Per-node resource requirements
VCPU_PER_NODE=4
RAM_PER_NODE=5   # GB

# Build host->IP map from arguments (name=ip pairs) or inventory.yml
declare -A HOSTS

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        name="${arg%%=*}"
        ip="${arg##*=}"
        HOSTS["$name"]="$ip"
    done
else
    # Parse ansible/inventory.yml: lines matching "ansible_host: <ip>"
    # Capture the host name from the preceding line and the IP from this one.
    if [[ ! -f "$INVENTORY" ]]; then
        echo "ERROR: $INVENTORY not found. Pass hosts as arguments: name=ip ..." >&2
        exit 1
    fi
    prev_name=""
    while IFS= read -r line; do
        trimmed="${line#"${line%%[![:space:]]*}"}"   # ltrim
        if [[ "$trimmed" =~ ^([a-zA-Z0-9_-]+):$ ]]; then
            prev_name="${BASH_REMATCH[1]}"
        elif [[ "$trimmed" =~ ^ansible_host:[[:space:]]*\"?([0-9.]+)\"?$ ]]; then
            if [[ -n "$prev_name" && "$prev_name" != "all" && "$prev_name" != "lab_hosts" && "$prev_name" != "hosts" && "$prev_name" != "children" && "$prev_name" != "vars" ]]; then
                HOSTS["$prev_name"]="${BASH_REMATCH[1]}"
            fi
        fi
    done < "$INVENTORY"
fi

if [[ ${#HOSTS[@]} -eq 0 ]]; then
    echo "ERROR: No hosts found. Check $INVENTORY or pass hosts as arguments." >&2
    exit 1
fi

# Print table header
printf "| %-8s | %-20s | %-6s | %-10s | %-17s |\n" "Host" "Ansible Host" "vCPU" "RAM (GB)" "Max vJunos Nodes"
printf "|%-10s|%-22s|%-8s|%-12s|%-19s|\n" "----------" "----------------------" "--------" "------------" "-------------------"

for name in $(echo "${!HOSTS[@]}" | tr ' ' '\n' | sort); do
    ip="${HOSTS[$name]}"
    if vcpu=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "root@$ip" nproc 2>/dev/null) && \
       ram=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "root@$ip" "free -g | awk '/^Mem:/{print \$2}'" 2>/dev/null); then
        max=$(( vcpu / VCPU_PER_NODE < ram / RAM_PER_NODE ? vcpu / VCPU_PER_NODE : ram / RAM_PER_NODE ))
        printf "| %-8s | %-20s | %-6s | %-10s | %-17s |\n" "$name" "$ip" "$vcpu" "$ram" "$max"
    else
        printf "| %-8s | %-20s | %-6s | %-10s | %-17s |\n" "$name" "$ip" "ERR" "ERR" "ERR"
    fi
done
