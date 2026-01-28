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
DEVICE="${DEVICE:-}"
VG_NAME="${VG_NAME:-myvg1}"
MIN_SIZE_GB="${MIN_SIZE_GB:-100}"

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
Setup LVM volume group for TopoLVM storage

Usage: $0 [OPTIONS]

Options:
  --device DEVICE          Block device to use (e.g., /dev/sda, /dev/sdb)
                           Environment: DEVICE
  --vg-name NAME           Volume group name (default: myvg1)
                           Environment: VG_NAME
  --min-size GB            Minimum device size in GB (default: 100)
                           Environment: MIN_SIZE_GB
  --help                   Show this help message

Examples:
  $0 --device /dev/sda --vg-name myvg1
  DEVICE=/dev/sdb $0
  sudo $0 --device /dev/sdb

Notes:
  - Requires root/sudo access
  - Device must exist and not be in use
  - Can extend existing volume groups
  - Minimum device size: ${MIN_SIZE_GB}GB
EOF
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

validate_device() {
    local device=$1

    if [[ ! -b "$device" ]]; then
        log_error "Device $device is not a valid block device"
        exit 1
    fi

    # Check if device is in use
    if lsblk -d "$device" 2>/dev/null | grep -q part; then
        log_warning "Device $device appears to have partitions"
    fi

    # Get device size in GB
    local size_bytes
    size_bytes=$(blockdev --getsize64 "$device" 2>/dev/null || echo 0)
    local size_gb=$((size_bytes / 1024 / 1024 / 1024))

    log_info "Device: $device"
    log_info "Size: ${size_gb}GB"

    if [[ $size_gb -lt $MIN_SIZE_GB ]]; then
        log_error "Device size (${size_gb}GB) is less than minimum (${MIN_SIZE_GB}GB)"
        exit 1
    fi
}

check_vg_exists() {
    local vg_name=$1

    if sudo vgs "$vg_name" &>/dev/null; then
        return 0  # VG exists
    else
        return 1  # VG doesn't exist
    fi
}

get_pv_status() {
    local device=$1

    if sudo pvs "$device" &>/dev/null; then
        return 0  # PV exists
    else
        return 1  # PV doesn't exist
    fi
}

confirm_action() {
    local prompt=$1
    local response

    while true; do
        read -p "$prompt (yes/no): " response
        case "$response" in
            yes) return 0 ;;
            no) return 1 ;;
            *) echo "Please answer 'yes' or 'no'" ;;
        esac
    done
}

setup_new_vg() {
    local device=$1
    local vg_name=$2

    log_info "Creating new LVM volume group: $vg_name"

    if ! confirm_action "Create new volume group on $device?"; then
        log_warning "Aborted"
        exit 1
    fi

    # Create physical volume
    log_info "Creating physical volume on $device..."
    sudo pvcreate --force --yes "$device"

    # Create volume group
    log_info "Creating volume group $vg_name..."
    sudo vgcreate "$vg_name" "$device"

    log_success "Volume group created successfully"
}

extend_vg() {
    local device=$1
    local vg_name=$2

    log_info "Extending existing volume group: $vg_name"

    if ! confirm_action "Extend volume group $vg_name with $device?"; then
        log_warning "Aborted"
        exit 1
    fi

    # Create physical volume
    log_info "Creating physical volume on $device..."
    sudo pvcreate --force --yes "$device"

    # Extend volume group
    log_info "Extending volume group $vg_name..."
    sudo vgextend "$vg_name" "$device"

    log_success "Volume group extended successfully"
}

show_vg_status() {
    local vg_name=$1

    log_info "Current volume group status:"
    echo ""
    sudo vgs "$vg_name" || true
    echo ""
    log_info "Physical volumes:"
    sudo pvs -S "vg_name=$vg_name" || true
    echo ""
    log_info "Logical volumes:"
    sudo lvs "$vg_name" 2>/dev/null || echo "  No logical volumes yet"
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --device)
                DEVICE="$2"
                shift 2
                ;;
            --vg-name)
                VG_NAME="$2"
                shift 2
                ;;
            --min-size)
                MIN_SIZE_GB="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate inputs
    if [[ -z "$DEVICE" ]]; then
        log_error "DEVICE is required"
        show_help
        exit 1
    fi

    log_info "================================================"
    log_info "LVM Setup for TopoLVM"
    log_info "================================================"

    # Check root access
    check_root

    # Validate device
    validate_device "$DEVICE"

    # Check if PV already exists
    if get_pv_status "$DEVICE" 2>/dev/null; then
        log_warning "Device $DEVICE is already a physical volume"
        sudo pvs "$DEVICE"
        log_warning "Skipping physical volume creation"
    fi

    # Check VG and decide action
    if check_vg_exists "$VG_NAME"; then
        log_info "Volume group $VG_NAME already exists"

        # Check if device is already in this VG
        if sudo pvs -S "vg_name=$VG_NAME" --noheadings | grep -q "$DEVICE"; then
            log_warning "Device $DEVICE is already in volume group $VG_NAME"
            show_vg_status "$VG_NAME"
            log_info "No action needed"
            exit 0
        else
            extend_vg "$DEVICE" "$VG_NAME"
        fi
    else
        setup_new_vg "$DEVICE" "$VG_NAME"
    fi

    # Show final status
    echo ""
    show_vg_status "$VG_NAME"
    log_success "LVM setup complete!"
}

main "$@"
