# NexisCoreOS bootable image

This folder turns the repository into a bootable Linux ISO.

## What it does

- Builds a bootable GRUB ISO.
- Uses your host Linux kernel (`/boot/vmlinuz-$(uname -r)` by default).
- Packs this repository into initramfs at `/srv/nexis`.
- Boots into a tiny BusyBox userspace.
- Serves repository files over HTTP at `http://127.0.0.1:8080`.

## Prerequisites

Install these tools on your host:

- `grub-mkrescue`
- `cpio`
- `gzip`
- `rsync`
- `busybox` at `/bin/busybox`
- a Linux kernel image (default path `/boot/vmlinuz-$(uname -r)`)

## Build

```bash
./os/build_iso.sh
```

Output ISO:

```text
dist/nexiscoreos.iso
```

## Run in QEMU

```bash
qemu-system-x86_64 -cdrom dist/nexiscoreos.iso -m 1024
```

Once booted:

- open `http://127.0.0.1:8080` from inside the VM networking context
- inspect repository files under `/srv/nexis`
