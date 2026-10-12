#!/bin/bash
set -euo pipefail

# autostart-windows.sh
# Menú gráfico y lógica para:
# - buscar imagen en USB (partición IMAGES)
# - detectar disco interno y copiar si el usuario confirma
# - importar/arrancar VM y lanzar virt-viewer
# - instalar Windows desde ISO (crear disco qcow2 y lanzar el instalador)
# - diagnóstico BIOS automático y opción para exportar logs

LOGFILE="/var/log/autostart-windows.log"
exec 3>&1
log() { echo "[$(date '+%F %T')] $*" >>"$LOGFILE"; }

VM_NAME="Windows_Libre"
USB_LABEL="IMAGES"
USB_IMAGE="windows10_ltsc_master.qcow2"
USB_MOUNT="/media/IMAGES"
INTERNAL_MOUNT_BASE="/mnt/internal_vm_target"
INTERNAL_VMS_DIR="VMs"
RAM_MB=6144
VCPUS=4

# GUI helpers (zenity)
zen_info() { zenity --info --width=480 --height=200 --text="$1"; }
zen_error() { zenity --error --width=480 --height=200 --text="$1"; }
zen_question() { zenity --question --width=480 --height=200 --text="$1"; return $?; }
zen_list() {
  zenity --list --radiolist --height=520 --width=700 \
    --title="Windows Libre — Selecciona una acción" \
    --column "" --column "Acción" \
    TRUE "Iniciar Windows (uso SSD si existe, si no USB)" \
    FALSE "Iniciar Windows desde USB (no copiar)" \
    FALSE "Copiar imagen al disco interno (recomendado para rendimiento)" \
    FALSE "Instalar Windows desde ISO (tengo una ISO en la USB)" \
    FALSE "Diagnóstico BIOS (recomendado si hay problemas)" \
    FALSE "Exportar diagnóstico (crear ZIP con logs)" \
    FALSE "Ver ayuda / Logs" \
    FALSE "Apagar / Reiniciar" \
    --ok-label="Ir" --cancel-label="Salir"
}

mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE" || true
log "Script iniciado."

# Run bios detection non-interactive and, if problems, run interactive helper
if command -v /usr/local/bin/bios-helper.sh >/dev/null 2>&1; then
  # call detect mode
  detect_out=$(/usr/local/bin/bios-helper.sh --detect 2>/dev/null || true)
  # parse
  KVM_OK_MSG=$(echo "$detect_out" | awk -F"=" '/KVM_OK_MSG/ {print $2}' | tr -d '\r' || true)
  VT_FLAG=$(echo "$detect_out" | awk -F"=" '/VT_FLAG/ {print $2}' | tr -d '\r' || true)
  # If virtualization not present or KVM not usable, show interactive helper
  if [ -z "$VT_FLAG" ] || [ "$KVM_OK_MSG" != "si" ]; then
    # run interactive helper to guide user
    /usr/local/bin/bios-helper.sh || true
  fi
fi

mount_usb_image() {
  mkdir -p "$USB_MOUNT"
  dev=$(blkid -L "$USB_LABEL" 2>/dev/null || true)
  if [ -n "$dev" ]; then
    if ! mountpoint -q "$USB_MOUNT"; then
      mount -o ro "$dev" "$USB_MOUNT" 2>/dev/null && log "Montada $dev en $USB_MOUNT"
    fi
  fi
}

find_usb_image() {
  mount_usb_image
  if [ -f "$USB_MOUNT/$USB_IMAGE" ]; then
    echo "$USB_MOUNT/$USB_IMAGE"
    return 0
  fi

  for d in /dev/sd* /dev/nvme?n*p?; do
    [ -b "$d" ] || continue
    tmp="/tmp/usbprobe_$$"
    mkdir -p "$tmp"
    if mount -o ro "$d" "$tmp" 2>/dev/null; then
      if [ -f "$tmp/$USB_IMAGE" ]; then
        umount "$tmp" 2>/dev/null || true
        mkdir -p "$USB_MOUNT"
        mount -o ro "$d" "$USB_MOUNT" 2>/dev/null && log "Montada $d en $USB_MOUNT"
        echo "$USB_MOUNT/$USB_IMAGE"
        return 0
      fi
      umount "$tmp" 2>/dev/null || true
    fi
    rmdir "$tmp" 2>/dev/null || true
  done
  return 1
}

find_iso_images() {
  mount_usb_image
  if [ -d "$USB_MOUNT" ]; then
    find "$USB_MOUNT" -maxdepth 2 -type f -iname "*.iso" 2>/dev/null || true
  fi
}

select_iso() {
  mapfile -t isos < <(find_iso_images)
  if [ ${#isos[@]} -eq 0 ]; then
    echo ""
    return 1
  fi
  if [ ${#isos[@]} -eq 1 ]; then
    echo "${isos[0]}"
    return 0
  fi
  list_args=()
  for i in "${isos[@]}"; do
    list_args+=(FALSE "$i")
  done
  choice=$(zenity --list --radiolist --title="Selecciona la ISO" --column="" --column="ISO" --height=400 --width=800 "${list_args[@]}" 2>/dev/null) || true
  if [ -n "$choice" ]; then
    echo "$choice"
    return 0
  fi
  echo ""
  return 1
}

find_internal_device() {
  while read -r name type tran; do
    [ "$type" = "part" ] || continue
    dev="/dev/$name"
    tranval=$(lsblk -dn -o TRAN "$dev" 2>/dev/null || true)
    if [ "$tranval" = "usb" ]; then
      continue
    fi
    tmp="/tmp/intprobe_$$"
    mkdir -p "$tmp"
    if mount "$dev" "$tmp" 2>/dev/null; then
      free_kb=$(df -k "$tmp" | awk 'NR==2 {print $4}')
      umount "$tmp" 2>/dev/null || true
      rmdir "$tmp" 2>/dev/null || true
      if [ -n "$free_kb" ] && [ "$free_kb" -gt $((20*1024*1024)) ]; then
        echo "$dev"
        return 0
      fi
    fi
  done < <(lsblk -dn -o NAME,TYPE,TRAN)
  return 1
}

copy_with_progress() {
  local src="$1"; local dst="$2"
  size_bytes=$(stat -c%s "$src" 2>/dev/null || echo 0)
  size_mb=$((size_bytes/1024/1024))
  if ! zen_question --text="Se copiará la imagen ($size_mb MB) al disco interno. ¿Deseas continuar?"; then
    return 2
  fi

  (
    cp "$src" "$dst" &
    cp_pid=$!
    while kill -0 "$cp_pid" 2>/dev/null; do
      echo "# Copiando imagen... por favor espera"
      sleep 1
    done
    wait "$cp_pid"
    rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "ERROR"
      exit 1
    fi
    echo "# Copia completada"
    exit 0
  ) | zenity --progress --title="Copiando imagen" --auto-close --pulsate --no-cancel --width=480

  if [ "${PIPESTATUS[1]:-0}" -ne 0 ]; then
    return 1
  fi
  return 0
}

vm_exists() {
  virsh dominfo "$VM_NAME" >/dev/null 2>&1
}

create_or_import_vm() {
  local path="$1"
  if vm_exists; then
    log "VM existente: $VM_NAME. Reinicializando definición..."
    virsh destroy "$VM_NAME" 2>/dev/null || true
    virsh undefine "$VM_NAME" --nvram 2>/dev/null || true
  fi
  log "Definiendo/importando VM con $path"
  if ! virt-install --name="$VM_NAME" --memory="$RAM_MB" --vcpus="$VCPUS" \
    --cpu host-passthrough --disk path="$path",bus=virtio,format=qcow2 \
    --os-variant=win10 --network network=default,model=virtio \
    --video=virtio --graphics none --import --noautoconsole; then
    log "virt-install falló"
    return 1
  fi
  return 0
}

start_vm_and_viewer() {
  local path="$1"
  if ! vm_exists; then
    if ! create_or_import_vm "$path"; then
      zen_error "No se pudo crear la VM. Revisa /var/log/autostart-windows.log"
      return 1
    fi
  fi
  virsh start "$VM_NAME" 2>/dev/null || true

  user=$(awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}' /etc/passwd || true)
  [ -n "$user" ] || user="root"
  user_home=$(getent passwd "$user" | cut -d: -f6 || echo "/root")
  display=":0"
  xauth="$user_home/.Xauthority"

  if [ -f "$xauth" ]; then
    su - "$user" -c "env DISPLAY=$display XAUTHORITY=$xauth virt-viewer --domain-name $VM_NAME --attach --full-screen &" || true
  else
    su - "$user" -c "env DISPLAY=$display virt-viewer --domain-name $VM_NAME --attach --full-screen &" || true
  fi
  return 0
}

create_vm_from_iso() {
  local iso="$1"
  local target_dev="$2"
  local target_mount
  if [ -b "$target_dev" ]; then
    mkdir -p "$INTERNAL_MOUNT_BASE"
    mount "$target_dev" "$INTERNAL_MOUNT_BASE" 2>/dev/null || true
    target_mount="$INTERNAL_MOUNT_BASE"
  else
    target_mount="$target_dev"
  fi
  mkdir -p "$target_mount/$INTERNAL_VMS_DIR"
  local disk_path="$target_mount/$INTERNAL_VMS_DIR/${VM_NAME}.qcow2"

  size_default=60
  size_choice=$(zenity --entry --title="Tamaño del disco" --text="Tamaño del disco QCOW2 en GB (por defecto $size_default):" --entry-text="$size_default") || true
  if [ -z "$size_choice" ]; then
    size_choice=$size_default
  fi

  log "Creando disco qcow2: $disk_path size=${size_choice}G"
  if [ ! -f "$disk_path" ]; then
    qemu-img create -f qcow2 "$disk_path" "${size_choice}G" || { zen_error "No se pudo crear el disco"; return 1; }
  fi
  chown root:root "$disk_path" || true
  chmod 600 "$disk_path" || true

  virtio_iso=""
  if [ -d "$USB_MOUNT" ]; then
    if [ -f "$USB_MOUNT/virtio-win.iso" ]; then
      virtio_iso="$USB_MOUNT/virtio-win.iso"
    fi
  fi

  cmd=(virt-install --name "$VM_NAME" --memory "$RAM_MB" --vcpus "$VCPUS" --cpu host-passthrough \
    --disk path="$disk_path",format=qcow2,bus=virtio \
    --os-variant=win10 --network network=default,model=virtio --video=virtio)

  cmd+=(--cdrom "$iso")
  if [ -n "$virtio_iso" ]; then
    cmd+=(--disk "path=$virtio_iso,device=cdrom,readonly=on")
  fi

  cmd+=(--graphics none)

  log "Ejecutando virt-install para instalar desde ISO: $iso"
  if ! "${cmd[@]}"; then
    zen_error "La instalación no pudo iniciarse. Revisa los logs en $LOGFILE"
    return 1
  fi
  return 0
}

export_diagnostics() {
  /usr/local/bin/export-diagnostics.sh || true
}

show_logs() {
  if [ -f "$LOGFILE" ]; then
    zenity --text-info --width=800 --height=600 --filename="$LOGFILE" --title="Logs de autostart"
  else
    zen_info "No hay logs aún."
  fi
}

# Main menu
ACTION=$(zen_list) || { log "Usuario canceló menú"; exit 0; }
log "Acción seleccionada: $ACTION"

case "$ACTION" in
  "Iniciar Windows (uso SSD si existe, si no USB)")
    usb_img=$(find_usb_image) || usb_img=""
    if dev=$(find_internal_device); then
      mkdir -p "$INTERNAL_MOUNT_BASE"
      if ! mountpoint -q "$INTERNAL_MOUNT_BASE"; then
        if ! mount "$dev" "$INTERNAL_MOUNT_BASE" 2>/dev/null; then
          log "No se pudo montar $dev; intentar USB"
          if [ -n "$usb_img" ]; then
            start_vm_and_viewer "$usb_img" || zen_error "No se pudo iniciar la VM desde USB."
          else
            zen_error "No se encontró imagen en USB ni disco interno disponible."
          fi
          exit 0
        fi
      fi
      mkdir -p "$INTERNAL_MOUNT_BASE/$INTERNAL_VMS_DIR"
      final="$INTERNAL_MOUNT_BASE/$INTERNAL_VMS_DIR/${VM_NAME}.qcow2"
      if [ -f "$final" ]; then
        start_vm_and_viewer "$final" || zen_error "No se pudo iniciar la VM desde SSD."
      else
        if [ -n "$usb_img" ]; then
          if copy_with_progress "$usb_img" "$final"; then
            chown root:root "$final" || true
            chmod 600 "$final" || true
            start_vm_and_viewer "$final" || zen_error "No se pudo iniciar la VM desde SSD tras copiar."
          else
            zen_error "Copia fallida. Intentando iniciar desde USB si está disponible."
            if [ -f "$usb_img" ]; then
              start_vm_and_viewer "$usb_img" || zen_error "No se pudo iniciar la VM desde USB."
            fi
          fi
        else
          zen_error "No se encontró imagen en USB para copiar."
        fi
      fi
    else
      if usb_img=$(find_usb_image); then
        start_vm_and_viewer "$usb_img" || zen_error "No se pudo iniciar la VM desde USB."
      else
        zen_error "No se encontró imagen en USB ni disco interno disponible."
      fi
    fi
    ;;

  "Iniciar Windows desde USB (no copiar)")
    if usb_img=$(find_usb_image); then
      start_vm_and_viewer "$usb_img" || zen_error "No se pudo iniciar la VM desde USB."
    else
      zen_error "No se encontró la imagen en la USB."
    fi
    ;;

  "Copiar imagen al disco interno (recomendado para rendimiento)")
    if usb_img=$(find_usb_image); then
      if dev=$(find_internal_device); then
        mkdir -p "$INTERNAL_MOUNT_BASE"
        mount "$dev" "$INTERNAL_MOUNT_BASE" 2>/dev/null || { zen_error "No se pudo montar $dev"; exit 1; }
        mkdir -p "$INTERNAL_MOUNT_BASE/$INTERNAL_VMS_DIR"
        final="$INTERNAL_MOUNT_BASE/$INTERNAL_VMS_DIR/${VM_NAME}.qcow2"
        if copy_with_progress "$usb_img" "$final"; then
          chown root:root "$final" || true
          chmod 600 "$final" || true
          zen_info "Copia completada. Puedes iniciar Windows ahora."
        else
          zen_error "Copia fallida o cancelada."
        fi
      else
        zen_error "No se detectó disco interno con espacio suficiente."
      fi
    else
      zen_error "No se encontró la imagen en la USB."
    fi
    ;;

  "Instalar Windows desde ISO (tengo una ISO en la USB)")
    iso_sel=$(select_iso) || iso_sel=""
    if [ -z "$iso_sel" ]; then
      zen_error "No se encontró ninguna ISO en la partición IMAGES. Asegúrate de que la ISO esté copiada y etiquetada en IMAGES."
      exit 0
    fi
    if dev=$(find_internal_device); then
      if zen_question --text="Se detectó un disco interno con espacio. ¿Deseas crear la VM e instalar en el disco interno?"; then
        if create_vm_from_iso "$iso_sel" "$dev"; then
          zen_info "Instalador lanzado. Sigue la instalación dentro de la ventana de la VM." || true
        fi
      else
        if create_vm_from_iso "$iso_sel" "$USB_MOUNT"; then
          zen_info "Instalador lanzado desde USB. Sigue la instalación dentro de la VM." || true
        fi
      fi
    else
      if create_vm_from_iso "$iso_sel" "$USB_MOUNT"; then
        zen_info "Instalador lanzado desde USB. Sigue la instalación dentro de la VM." || true
      fi
    fi
    ;;

  "Diagnóstico BIOS (recomendado si hay problemas)")
    /usr/local/bin/bios-helper.sh || true
    ;;

  "Exportar diagnóstico (crear ZIP con logs)")
    export_diagnostics
    ;;

  "Ver ayuda / Logs")
    show_logs
    ;;

  "Apagar / Reiniciar")
    if zen_question --text="¿Apagar el equipo? (Cancelar = reiniciar)"; then
      poweroff
    else
      reboot
    fi
    ;;

  *)
    log "Opción desconocida: $ACTION"
    ;;
esac

log "Script finalizado."
exit 0
