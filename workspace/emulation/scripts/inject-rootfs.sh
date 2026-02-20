#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <rootfs.ext2|rootfs.ext4> <host_file> <guest_path>"
  exit 1
fi

ROOTFS="$1"
HOST_FILE="$2"
GUEST_PATH="$3"

if [[ ! -f "${ROOTFS}" ]]; then
  echo "Rootfs image not found: ${ROOTFS}"
  exit 1
fi

if [[ ! -f "${HOST_FILE}" ]]; then
  echo "Host file not found: ${HOST_FILE}"
  exit 1
fi

if [[ "${GUEST_PATH}" != /* ]]; then
  echo "guest_path must be absolute, got: ${GUEST_PATH}"
  exit 1
fi

guest_dir="$(dirname "${GUEST_PATH}")"
guest_file="${GUEST_PATH}"

# Ensure parent directories exist inside the image.
IFS='/' read -r -a parts <<< "${guest_dir#/}"
current=""
for part in "${parts[@]}"; do
  [[ -z "${part}" ]] && continue
  current="${current}/${part}"
  debugfs -w -R "mkdir ${current}" "${ROOTFS}" >/dev/null 2>&1 || true
done

# Replace file atomically from debugfs perspective.
debugfs -w -R "rm ${guest_file}" "${ROOTFS}" >/dev/null 2>&1 || true
debugfs -w -R "write ${HOST_FILE} ${guest_file}" "${ROOTFS}" >/dev/null

echo "Injected ${HOST_FILE} -> ${guest_file} in ${ROOTFS}"
