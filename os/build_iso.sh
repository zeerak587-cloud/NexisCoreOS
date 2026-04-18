#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${REPO_ROOT}/dist"
WORK_DIR="${REPO_ROOT}/.build/os"
ISO_NAME="nexiscoreos.iso"
ISO_PATH="${OUT_DIR}/${ISO_NAME}"

KERNEL_PATH="${KERNEL_PATH:-/boot/vmlinuz-$(uname -r)}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    exit 1
  fi
}

require_cmd grub-mkrescue
require_cmd cpio
require_cmd gzip
require_cmd rsync
require_cmd find

if [[ ! -f "${KERNEL_PATH}" ]]; then
  echo "Kernel not found at ${KERNEL_PATH}" >&2
  echo "Set KERNEL_PATH to a valid Linux kernel image path." >&2
  exit 1
fi

if [[ ! -x /bin/busybox ]]; then
  echo "Expected /bin/busybox to exist and be executable." >&2
  echo "Install busybox and try again." >&2
  exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/iso/boot/grub" "${WORK_DIR}/initramfs"
mkdir -p "${OUT_DIR}"

cp "${REPO_ROOT}/os/grub.cfg" "${WORK_DIR}/iso/boot/grub/grub.cfg"
cp "${KERNEL_PATH}" "${WORK_DIR}/iso/boot/vmlinuz"

# Build initramfs filesystem
ROOTFS="${WORK_DIR}/initramfs"
mkdir -p "${ROOTFS}"/{bin,sbin,etc,proc,sys,dev,run,tmp,mnt/root,srv}
chmod 1777 "${ROOTFS}/tmp"

cp /bin/busybox "${ROOTFS}/bin/busybox"
for app in sh mount mkdir mknod sleep poweroff reboot clear cat ls cp echo chmod chown ps kill uname httpd; do
  ln -sf /bin/busybox "${ROOTFS}/bin/${app}"
done

cp "${REPO_ROOT}/os/init" "${ROOTFS}/init"
chmod +x "${ROOTFS}/init"

mkdir -p "${ROOTFS}/srv/nexis"
rsync -a \
  --exclude '.git' \
  --exclude '.build' \
  --exclude 'dist' \
  --exclude 'os' \
  "${REPO_ROOT}/" "${ROOTFS}/srv/nexis/"

(
  cd "${ROOTFS}"
  find . -print0 | cpio --null -ov --format=newc | gzip -9 > "${WORK_DIR}/iso/boot/initramfs.cpio.gz"
)

grub-mkrescue -o "${ISO_PATH}" "${WORK_DIR}/iso" >/dev/null 2>&1

echo "Created bootable image: ${ISO_PATH}"
echo "Run with: qemu-system-x86_64 -cdrom ${ISO_PATH} -m 1024"
