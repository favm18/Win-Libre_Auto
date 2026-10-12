# Quickstart — ANTES DE INSTALAR (punto de partida)

ANTES DE INSTALAR, POR FAVOR LEE ESTOS PASOS CON ATENCIÓN

Este documento es la guía rápida para usuarios que no quieren entrar en detalles técnicos.
Sigue cada paso en orden. Si tienes dudas, pídeles a tus amigos o al técnico que te ayude.

1) Preparar el pendrive USB (desde un PC que funcione)

- Descarga la ISO generada (`win-live-trixie.iso`) desde tu equipo donde la construiste.
- Graba la ISO en el pendrive (esto borrará todo lo que haya en el pendrive):
  sudo dd if=win-live-trixie.iso of=/dev/sdX bs=4M status=progress conv=fsync
  (Reemplaza /dev/sdX por el dispositivo correcto).

- Crea una SEGUNDA partición en el espacio libre del pendrive y formatea con etiqueta IMAGES:
  sudo parted /dev/sdX -- mkpart primary ext4 100% 100%
  sudo mkfs.ext4 -L IMAGES /dev/sdX2

- Monta la partición IMAGES y copia TU imagen de Windows (.qcow2) o la ISO de Windows:
  sudo mkdir -p /mnt/images
  sudo mount /dev/sdX2 /mnt/images
  sudo cp /ruta/a/windows10_ltsc_master.qcow2 /mnt/images/
  # o si tienes ISO:
  sudo cp /ruta/a/windows.iso /mnt/images/
  sudo umount /mnt/images

2) Antes de arrancar en el equipo destino

- Haz copia de seguridad de tus datos importantes (si hay datos en el equipo).
- Asegúrate de que el equipo tiene al menos 8 GB de RAM (16 GB recomendado).
- Conecta el pendrive en un puerto USB 3.0 si está disponible.

3) Al arrancar desde el pendrive

- Enciende el equipo y arranca desde el pendrive (puede ser F12, Esc, o cambiar el orden de arranque en BIOS).
- Aparecerá un menú sencillo. Si el asistente detecta que la virtualización no está habilitada, te mostrará instrucciones.
- Selecciona "Diagnóstico BIOS" si no estás seguro; sigue los pasos indicados para habilitar Virtualization (VT-x/AMD-V).
- Luego elige "Iniciar Windows (uso SSD si existe)" o "Instalar Windows desde ISO" si quieres hacer una instalación limpia.

4) Si el asistente pide que actives Virtualization (VT-x/AMD-V)

- No te asustes: esto se hace en la BIOS/UEFI de tu equipo.
- Las teclas más habituales para entrar en BIOS son: F2, F10, F12, Del, Esc.
- Si no sabes, prueba a presionar una de esas teclas al encender el equipo.
- En la BIOS busca opciones llamadas: "Virtualization", "Intel Virtualization Technology", "VT-x", "SVM" y actívalas.
- Guarda y reinicia.

5) Si ves mensajes sobre Secure Boot

- Secure Boot puede impedir algunos drivers. Si el Live te avisa, puedes:
  - Desactivar Secure Boot en la BIOS (guía que muestra el asistente), o
  - Seguir la opción de inscribir MOK si sabes cómo (avanzado).

6) Tras la copia al SSD

- El asistente copiará la imagen al SSD si hay espacio y si confirmas la copia. Esto agiliza mucho el rendimiento.
- No borra otras particiones: solo copia el archivo .qcow2 en una carpeta llamada VMs en el primer volumen con suficiente espacio.

7) Si algo falla

- Selecciona "Exportar diagnóstico" en el menú. El sistema generará un archivo con logs que podrás adjuntar al crear un issue en GitHub.
- Pide a quien te ayude que suba ese archivo al issue para revisar el problema.

8) ¿Tienes dudas?

- Lee el README del proyecto en GitHub: https://github.com/favm18/Win-Libre_Auto
- Abre un issue con la plantilla "bug report" y adjunta el ZIP de diagnóstico.

Gracias por probar Win-Libre_Auto. Tus comentarios ayudarán mucho a mejorar la experiencia para usuarios sin conocimientos técnicos.
