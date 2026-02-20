#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EMU_DIR="${ROOT_DIR}/workspace/emulation"
RISCV_DIR="${EMU_DIR}/riscv64"
IMAGES_DIR="${EMU_DIR}/buildroot/output/images"

KERNEL="${KERNEL:-${RISCV_DIR}/Image}"
ROOTFS="${ROOTFS:-${RISCV_DIR}/rootfs.ext2}"
BIOS="${BIOS:-${IMAGES_DIR}/fw_jump.bin}"
RAM_MB="${RAM_MB:-256}"
SMP="${SMP:-1}"

exec qemu-system-riscv64 \
  -machine virt \
  -cpu rv64 \
  -m "${RAM_MB}M" \
  -smp "${SMP}" \
  -nographic \
  -bios "${BIOS}" \
  -kernel "${KERNEL}" \
  -append "root=/dev/vda rw console=ttyS0" \
  -drive "file=${ROOTFS},format=raw,if=virtio" \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0
