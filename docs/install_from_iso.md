# Debian Trixie Live — Instalar Windows desde ISO

Esta documentación explica la nueva opción "Instalar Windows desde ISO" incluida en el menú del Live.

Flujo resumido
- El usuario copia una ISO de Windows en la partición IMAGES del USB (o en otra ubicación dentro de IMAGES).
- Al arrancar el Live, en el menú se elige "Instalar Windows desde ISO".
- El script lista las ISOs encontradas y permite seleccionar una.
- Si hay un disco interno con espacio, el script ofrece crear un disco qcow2 allí (recomendado) o usar la USB.
- El script crea un disco qcow2 (por ejemplo 60G por defecto) y lanza virt-install con la ISO seleccionada como CDROM.
- Si en IMAGES hay un archivo `virtio-win.iso`, el script lo adjunta como CDROM adicional para facilitar la instalación de drivers de red/disco en Windows.

Recomendaciones para preparar la ISO:
- Copia la ISO de Windows a la partición IMAGES del USB.
- Opcional: copia también `virtio-win.iso` (drivers virtio). Puedes descargarla desde https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/

Limitaciones y avisos:
- No se distribuye Windows ni licencias. El usuario debe aportar su propia ISO y su licencia.
- Si la creación del disco falla por permisos o espacio, revisa /var/log/autostart-windows.log.
- Secure Boot puede impedir la ejecución de KVM; si falla, desactiva Secure Boot en BIOS.
