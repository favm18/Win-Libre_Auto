# Win‑Libre_Auto

Live Debian Trixie para arrancar Windows en KVM desde USB — guía paso a paso, diagnóstico BIOS, instalación desde ISO y una experiencia pensada para usuarios no técnicos.

**Estado:** Beta — probando con testers.  
**Contacto:** pablo.vallejo.ik.me

---

## Resumen

Win‑Libre_Auto permite bootear un equipo desde un USB y ejecutar (o instalar) Windows dentro de una máquina virtual lista para usar, sin que el usuario tenga que instalar Debian ni tocar la terminal. El objetivo es ofrecer una experiencia "enchufar y usar" para personas sin conocimientos técnicos.

---

## Antes de instalar — LEE ESTO

**ANTES DE INSTALAR, POR FAVOR LEE ESTOS PASOS:**

- Haz copia de seguridad de tus archivos importantes.
- Equipo: mínimo 8 GB RAM (16 GB recomendado).
- Usa USB 3.0 o SSD USB para mejor rendimiento.
- Ten disponible tu ISO/imagen Windows (.qcow2 o .iso) y la licencia correspondiente.

---

## Características principales

- Menú gráfico sencillo (zenity) orientado a usuarios no técnicos.
- Diagnóstico BIOS / UEFI: detecta UEFI, Secure Boot y si la virtualización está disponible; muestra guías por fabricante.
- Copia automática de la imagen `.qcow2` al disco interno (si hay espacio) para mejor rendimiento.
- Opción “Instalar Windows desde ISO”: crea disco qcow2 y lanza el instalador.
- Exportador de diagnóstico (logs + salidas clave) para facilitar soporte.
- Documentación rápida (Quickstart) y A4 imprimible para entregar al usuario.
- No incluye Windows — el usuario debe aportar su ISO/.qcow2 y licencia.

---

## ¿Para quién es esto?

- Usuarios con equipos antiguos o sin soporte de Microsoft que desean seguir usando Windows en una VM.
- Técnicos y organizaciones que quieran una solución guiada para replicar en máquinas múltiples.
- Personas que prefieren una experiencia “enchufar y usar” sin complejidad.

---

## Requisitos (resumen)

- Host físico con CPU que soporte virtualización (VT‑x/AMD‑V). Debe estar activado en BIOS/UEFI.
- 8 GB RAM mínimo (16 GB recomendado).
- USB 3.0 o SSD USB (recomendado).
- Imagen Windows (.qcow2) o ISO de instalación de Windows + licencia.
- En la máquina que genera la ISO: Debian (para ejecutar live‑build) y live‑build instalado.

---

## Quickstart (resumen para quien crea el USB)

1. Clona el repo:
   ```bash
   git clone https://github.com/favm18/Win-Libre_Auto
   ```
2. En el host Debian:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
   -> Genera `win-live-trixie.iso`
3. Graba la ISO en un pendrive (ATENCIÓN: borra el dispositivo):
   ```bash
   sudo dd if=win-live-trixie.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   (reemplaza /dev/sdX por el dispositivo correcto)
4. Crea segunda partición en el pendrive y etiqueta `IMAGES`:
   ```bash
   sudo parted /dev/sdX -- mkpart primary ext4 100% 100%
   sudo mkfs.ext4 -L IMAGES /dev/sdX2
   ```
5. Monta /dev/sdX2 y copia la imagen o ISO:
   ```bash
   sudo mount /dev/sdX2 /mnt
   sudo cp /ruta/a/windows10_ltsc_master.qcow2 /mnt/    # o windows.iso
   (opcional) sudo cp /ruta/virtio-win.iso /mnt/
   sudo umount /mnt
   ```

---

## Usar en la máquina destino (pasos para el usuario final)

1. Inserta el USB y arranca desde él (puede requerir F12 / Esc / F2 al encender).
2. Sigue el menú sencillo:
   - Diagnóstico BIOS (recomendado si dudas)
   - Iniciar Windows (usa SSD si existe)
   - Instalar Windows desde ISO
   - Copiar imagen al disco interno
   - Exportar diagnóstico
3. Si el asistente solicita activar “Virtualization” en BIOS, sigue las instrucciones que aparecen en pantalla (te dirá qué tecla y qué opción activar).
4. Si aparece aviso sobre Secure Boot y causa problemas, el asistente te explicará cómo desactivarlo o inscribir una clave (MOK).
5. Si algo falla: selecciona “Exportar diagnóstico” y adjunta el archivo al crear un issue en GitHub.

---

## Diagnóstico y soporte

- Logs principales: `/var/log/autostart-windows.log`
- Herramienta de diagnóstico integrada genera un .tar.gz con:
  - bios-detect, lsblk, blkid, virsh list, paquetes instalados, etc.
- Si pruebas con testers, pídeles que adjunten ese .tar.gz al abrir issues.

---

## Documentación imprimible

- `docs/quickstart_A4.html` (listo para imprimir en A4)
- `docs/quickstart_final.md` (versión texto)
- `docs/PRINT_INSTRUCTIONS.md`

---

## Licencia y legal

- Proyecto con licencia MIT (LICENSE).
- No distribuyas imágenes de Windows ni claves: el usuario debe usar su propia ISO y licencia.
- No se realizan cambios en firmware/BIOS de forma automática sin consentimiento explícito.

---

## Contribuir

- Abre PRs pequeños y bien descritos.
- Usa Issues para bugs: hay plantilla `.github/ISSUE_TEMPLATE/bug_report.md`.
- Antes de subir ISOs o imágenes, comprueba licencias: no subas Windows ni binarios con restricciones.

---

## Contacto

Para consultas y soporte: pablo.vallejo.ik.me

---

## Etiquetas sugeridas (topics)

win-libre, live-build, debian, trixie, kvm, qemu, libvirt, virtio, live-iso, virtual-machine, windows-vm, rescue
