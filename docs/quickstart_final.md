# Win-Libre_Auto — Guía rápida final (1 página)

ANTES DE INSTALAR, POR FAVOR LEER ESTOS PASOS

Resumen: Conecta el USB, arranca desde él, sigue las instrucciones en pantalla y pulsa “Iniciar Windows”. Si el asistente pide activar una opción en la BIOS te guiará paso a paso.

ANTES DE EMPEZAR (hacer esto sí o sí)
- Haz copia de seguridad de tus archivos importantes.
- Necesitas al menos 8 GB de RAM (16 GB recomendado).
- Usa un puerto USB 3.0 o un SSD externo para mejor rendimiento.
- Ten a mano tu licencia/ISO de Windows o la imagen `.qcow2`.

PREPARAR EL USB (en un PC que funcione)
1) Genera la ISO con el script `build.sh`:
   ```bash
   chmod +x build.sh
   ./build.sh
   ```
2) Graba la ISO (esto BORRA el pendrive):
   ```bash
   sudo dd if=win-live-trixie.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   (Reemplaza `/dev/sdX` por el dispositivo correcto)
3) Crea una segunda partición y etiqueta `IMAGES`:
   ```bash
   sudo parted /dev/sdX -- mkpart primary ext4 100% 100%
   sudo mkfs.ext4 -L IMAGES /dev/sdX2
   ```
4) Copia tu archivo:
   ```bash
   sudo mount /dev/sdX2 /mnt
   sudo cp /ruta/a/windows10_ltsc_master.qcow2 /mnt/    # o windows.iso
   sudo cp /ruta/virtio-win.iso /mnt/                 # opcional
   sudo umount /mnt
   ```

EN EL EQUIPO DESTINO (pasos para el usuario)
1) Conecta el pendrive e inicia el equipo desde USB (F12 / Esc / F2 al arrancar según el equipo).
2) En el menú, si no estás seguro, elige: `Diagnóstico BIOS` (te dirá si debes activar algo).
3) Opciones principales:
   - Iniciar Windows (usa SSD si existe; recomendado)
   - Instalar Windows desde ISO
   - Copiar imagen al disco interno (mejor rendimiento)
   - Diagnóstico BIOS / Exportar diagnóstico
4) Si te pide activar “Virtualization” (VT-x/AMD-V): sigue las instrucciones en pantalla (solo cambiar una opción en la BIOS; guarda y reinicia).
5) Si ves aviso sobre Secure Boot: el asistente explica cómo desactivarlo o inscribir una clave (MOK) si sabes qué haces.
6) Tras la copia/instalación, la VM arrancará y se abrirá automáticamente la ventana de Windows.

SI ALGO FALLA
- Selecciona `Exportar diagnóstico` en el menú. Obtendrás un archivo .tar.gz con logs.
- Abre un issue en GitHub y adjunta ese archivo (usa la plantilla “Bug report”).
- Si no entiendes un paso, envía una foto o el log y te ayudamos.

CONSEJOS PRÁCTICOS
- No necesitas conocimientos técnicos: el asistente te guía.
- Si no sabes qué tecla usar para la BIOS, prueba F2, Del, Esc o F12 al encender.
- Mantén el pendrive en puerto USB 3.0 si es posible.

¡Felicidades! Si llegas hasta aquí y todo funciona: “¡Felicidades, ya eres hacker!” 🎉

Repo: https://github.com/favm18/Win-Libre_Auto
