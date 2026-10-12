#!/bin/bash
set -euo pipefail

# bios-helper.sh
# Detecta fabricante/modelo, UEFI/SecureBoot, soporte de virtualización, y muestra
# instrucciones y enlaces para que un usuario pueda habilitar VT-x/AMD-V o
# desactivar Secure Boot. Muestra enlaces oficiales por fabricante.

LOGFILE="/var/log/autostart-windows.log"

log() { echo "[$(date '+%F %T')] [bios-helper] $*" >>"$LOGFILE"; }

# Detect hardware/firmware
SYSVENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Desconocido")
MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Desconocido")
UEFI="no"
[ -d /sys/firmware/efi ] && UEFI="si"

# Secure Boot detection
SB_STATE="desconocido"
if command -v mokutil >/dev/null 2>&1; then
  SB_STATE=$(mokutil --sb-state 2>/dev/null | tr -d '\r') || SB_STATE="desconocido"
else
  if [ -d /sys/firmware/efi/vars ]; then
    SB_STATE="posible"
  else
    SB_STATE="no-uefi"
  fi
fi

# Virtualization flags
VT_FLAG=$(egrep -o 'vmx|svm' /proc/cpuinfo | head -n1 || true)
VT_PRESENT="no"
if [ -n "$VT_FLAG" ]; then
  VT_PRESENT="si"
fi

# Check if virtualization enabled (basic heuristic)
KVM_OK_MSG="desconocido"
if command -v kvm-ok >/dev/null 2>&1; then
  if kvm-ok 2>&1 | grep -q "KVM acceleration can be used"; then
    KVM_OK_MSG="si"
  else
    KVM_OK_MSG="no"
  fi
else
  KVM_OK_MSG="instala-cpu-checker-para-verificar"
fi

# libvirt status
LIBVIRT_ACTIVE="no"
if systemctl is-active --quiet libvirtd 2>/dev/null; then
  LIBVIRT_ACTIVE="si"
fi

# Prepare messages
SUMMARY="Fabricante: $SYSVENDOR\nModelo: $MODEL\nUEFI: $UEFI\nSecureBoot: $SB_STATE\nVirtualization flags: ${VT_FLAG:-none}\nKVM usable: $KVM_OK_MSG\nlibvirtd activo: $LIBVIRT_ACTIVE"

# Guide links per vendor (generic search fallback)
declare -A VENDOR_URLS
VENDOR_URLS["Dell"]="https://www.dell.com/support/home"
VENDOR_URLS["HP"]="https://support.hp.com/"
VENDOR_URLS["Hewlett-Packard"]="https://support.hp.com/"
VENDOR_URLS["Lenovo"]="https://support.lenovo.com/"
VENDOR_URLS["ASUS"]="https://www.asus.com/support/"
VENDOR_URLS["Acer"]="https://www.acer.com/worldwide/support/"
VENDOR_URLS["MSI"]="https://www.msi.com/support"

OPEN_URL="https://www.google.com/search?q=habilitar+virtualization+"$(echo "$MODEL" | sed 's/ /+/g')
for k in "${!VENDOR_URLS[@]}"; do
  if echo "$SYSVENDOR" | grep -i "$k" >/dev/null 2>&1; then
    OPEN_URL=${VENDOR_URLS[$k]}
    break
  fi
done

# Steps to show user (simple and non-technical)
STEPS="Pasos rápidos (guía general):\n\n1) Reinicia el equipo y entra en la BIOS/UEFI pulsando la tecla indicada por el fabricante (F2, F10, F12, Del o Esc).\n2) Busca una sección llamada 'Advanced', 'System Configuration' o 'Security'.\n3) Activa opciones llamadas 'Intel Virtualization Technology', 'VT-x', 'SVM' o 'Virtualization'.\n4) Comprueba la opción 'Secure Boot' y desactívala si da problemas con drivers no firmados.\n5) Guarda los cambios y reinicia.\n\nSi no sabes qué tecla usar para entrar en BIOS, prueba F2, Del, Esc o F12 al arrancar."

# Offer detailed vendor-specific hints (very short)
VENDOR_HINTS=""
if echo "$SYSVENDOR" | grep -i "Dell" >/dev/null 2>&1; then
  VENDOR_HINTS="Dell suele usar F2 para acceder a BIOS y F12 para disco/boot menu. Busca 'Virtualization' en 'System Configuration'."
elif echo "$SYSVENDOR" | grep -i "Lenovo" >/dev/null 2>&1; then
  VENDOR_HINTS="Lenovo ThinkPad/IdeaPad: generalmente F1 o F2. Puede tener 'Security' > 'Virtualization'."
elif echo "$SYSVENDOR" | grep -i "HP" >/dev/null 2>&1; then
  VENDOR_HINTS="HP: F10 o Esc al arranque. Virtualization está en 'System Configuration' o 'Security'."
elif echo "$SYSVENDOR" | grep -i "Acer" >/dev/null 2>&1; then
  VENDOR_HINTS="Acer: F2 para BIOS. Virtualization a menudo en 'Main' o 'Advanced'."
elif echo "$SYSVENDOR" | grep -i "ASUS" >/dev/null 2>&1; then
  VENDOR_HINTS="ASUS: Suelen usar Del o F2. Busca 'Advanced' > 'CPU Configuration' > 'Intel Virtualization Technology'."
fi

# Show summary and options to user via zenity
if command -v zenity >/dev/null 2>&1; then
  zenity --question --width=720 --height=320 --text="Estado del sistema:\n\n$SUMMARY\n\n¿Quieres abrir la página de soporte del fabricante o ver pasos para activar Virtualization?" --ok-label="Abrir guía" --cancel-label="Ver pasos";
  choice=$?
  if [ "$choice" -eq 0 ]; then
    log "Usuario abrió página de fabricante: $OPEN_URL"
    xdg-open "$OPEN_URL" 2>/dev/null || true
    exit 0
  else
    # show steps and vendor hints
    zenity --info --width=720 --height=420 --text="$STEPS\n\n$VENDOR_HINTS" --ok-label="Entendido" || true
  fi

  # Offer advanced actions
  zenity --question --width=720 --height=240 --text="¿Quieres ejecutar comprobaciones adicionales (kvm-ok, status libvirt) y ver instrucciones avanzadas?" --ok-label="Si" --cancel-label="No"
  adv=$?
  if [ "$adv" -eq 0 ]; then
    # run checks and show results
    out=""
    out+="\n== Comprobaciones ==\n"
    out+="KVM flags: ${VT_FLAG:-none}\n"
    out+="KVM usable (kvm-ok): $KVM_OK_MSG\n"
    out+="libvirtd activo: $LIBVIRT_ACTIVE\n"
    out+="UEFI: $UEFI\n"
    out+="SecureBoot: $SB_STATE\n"
    zenity --text-info --width=800 --height=420 --title="Comprobaciones" --filename=<(echo -e "$out") || true
  fi
else
  echo -e "Estado del sistema:\n$SUMMARY\n"
  echo -e "Abrir soporte: $OPEN_URL\n"
  echo -e "$STEPS\n\n$VENDOR_HINTS\n"
fi

log "bios-helper finalizado."
exit 0
