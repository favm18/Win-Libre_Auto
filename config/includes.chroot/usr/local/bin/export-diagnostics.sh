#!/bin/bash
set -euo pipefail

OUT_DIR=/tmp/winlibre-diagnostics
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUT_ZIP="/tmp/winlibre-diagnostics-${TIMESTAMP}.tar.gz"

mkdir -p "$OUT_DIR"

# Collect logs and outputs
cp /var/log/autostart-windows.log "$OUT_DIR/" 2>/dev/null || true
/usr/local/bin/bios-helper.sh --detect > "$OUT_DIR/bios-detect.txt" 2>/dev/null || true
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT > "$OUT_DIR/lsblk.txt" 2>/dev/null || true
blkid > "$OUT_DIR/blkid.txt" 2>/dev/null || true
virsh list --all > "$OUT_DIR/virsh-list.txt" 2>/dev/null || true
ps aux > "$OUT_DIR/ps.txt" 2>/dev/null || true

# package versions
dpkg -l qemu-kvm libvirt-daemon-system virt-viewer 2>/dev/null > "$OUT_DIR/packages.txt" || true

# Create zip
tar -czf "$OUT_ZIP" -C /tmp winlibre-diagnostics-${TIMESTAMP} 2>/dev/null || true

# Inform user
if command -v zenity >/dev/null 2>&1; then
  zenity --info --width=560 --text="Diagnóstico guardado en: $OUT_ZIP\n\nAdjunta este archivo al crear un issue en GitHub para que podamos ayudarte."
else
  echo "Diagnóstico guardado en: $OUT_ZIP"
fi

# cleanup temp dir
rm -rf "$OUT_DIR" || true

exit 0
