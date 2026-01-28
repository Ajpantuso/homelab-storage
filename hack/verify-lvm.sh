#!/bin/bash
# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VG_NAME="${1:-myvg1}"
MIN_FREE_GB="${MIN_FREE_GB:-100}"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_help() {
    cat << EOF
Verify LVM setup for TopoLVM

Usage: $0 [VG_NAME]

Arguments:
  VG_NAME         Volume group name (default: myvg1)

Environment:
  VG_NAME         Volume group name
  MIN_FREE_GB     Minimum free space warning threshold (default: 100)

Examples:
  $0
  $0 myvg1
  VG_NAME=my-vg $0

EOF
}

check_vg_exists() {
    local vg_name=$1

    if ! sudo vgs "$vg_name" &>/dev/null; then
        log_error "Volume group '$vg_name' not found"
        log_info "Available volume groups:"
        sudo vgs --noheadings -o name || echo "  None found"
        exit 1
    fi
}

get_vg_info() {
    local vg_name=$1

    sudo vgs --noheadings -o vg_name,vg_size,vg_free,vg_extent_size "$vg_name" 2>/dev/null | tr -s ' ' | cut -d' ' -f2-
}

convert_size() {
    local size_str=$1
    # Remove the unit letter and return numeric value in GB
    echo "$size_str" | sed 's/[a-zA-Z]*$//'
}

main() {
    # Check for help flag
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi

    log_info "================================================"
    log_info "LVM Verification for TopoLVM"
    log_info "================================================"
    echo ""

    # Check if VG exists
    check_vg_exists "$VG_NAME"

    # Display VG information
    log_info "Volume Group: $VG_NAME"
    echo ""
    echo "Volume Group Status:"
    sudo vgs "$VG_NAME" || true
    echo ""

    # Extract size info
    read -r size free extent_size <<< "$(get_vg_info "$VG_NAME")"
    size_num=$(convert_size "$size")
    free_num=$(convert_size "$free")

    log_info "Capacity: $size"
    log_info "Free Space: $free"
    log_info "Extent Size: $extent_size"
    echo ""

    # Check free space warning
    if (( $(echo "$free_num < $MIN_FREE_GB" | bc -l 2>/dev/null || echo 0) )); then
        log_warning "Free space (${free}B) is below ${MIN_FREE_GB}GB threshold"
    else
        log_success "Sufficient free space available"
    fi

    # Display physical volumes
    log_info "Physical Volumes:"
    echo ""
    sudo pvs -S "vg_name=$VG_NAME" || true
    echo ""

    # Display logical volumes
    log_info "Logical Volumes:"
    if sudo lvs "$VG_NAME" &>/dev/null; then
        echo ""
        sudo lvs "$VG_NAME" || true
        echo ""
    else
        log_info "  No logical volumes yet"
        echo ""
    fi

    # Display detailed device information
    log_info "Block Device Information:"
    echo ""
    sudo pvs -S "vg_name=$VG_NAME" --noheadings -o pv_name,pv_size | while read -r pv_name pv_size; do
        if [[ -n "$pv_name" ]]; then
            echo "Device: $pv_name"
            lsblk -d "$pv_name" 2>/dev/null || true
        fi
    done
    echo ""

    # Provide configuration guidance
    log_info "TopoLVM HelmRelease Configuration:"
    echo ""
    cat << EOF
In the TopoLVM HelmRelease values, configure:

  lvmd:
    managed: true
    deviceClasses:
      - name: ssd
        volume-group: $VG_NAME
        default: true
        spare-gb: 10

Current capacity (approximately):
  Total: ${size}
  Available for provisioning: ~${free} (minus 10GB spare)

EOF

    log_success "LVM verification complete!"
}

main "$@"
