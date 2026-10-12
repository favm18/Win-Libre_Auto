# README: Instalación desde ISO añadida

He añadido la opción "Instalar Windows desde ISO" al menú principal del Live.

Cómo usarla - resumen rápido:
1. Copia tu ISO de instalación de Windows a la partición IMAGES del USB.
2. (Opcional) copia virtio-win.iso a la misma partición IMAGES para tener los drivers.
3. Arranca desde el USB Live y selecciona "Instalar Windows desde ISO".
4. Selecciona la ISO cuando se te pida.
5. Si hay un SSD interno, se ofrecerá crear un disco qcow2 allí (recomendado). Si no, se usará la USB.
6. Sigue el instalador de Windows dentro de la VM.

Logs y depuración:
- /var/log/autostart-windows.log

Notas:
- El proceso crea un disco qcow2 del tamaño que elijas (60GB por defecto). Asegúrate de tener espacio.
- Si quieres una instalación no asistida (autounattend), puedes colocar el archivo de respuesta en la ISO o adjuntarlo según tu workflow de Windows.
