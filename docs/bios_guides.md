# BIOS & UEFI Guides

Este documento reúne instrucciones breves y pasos de referencia para los fabricantes más comunes.

IMPORTANTE: Los pasos pueden variar según el modelo y la versión del firmware. Usa siempre la página oficial del fabricante para obtener instrucciones exactas.

## Pasos generales

1. Reinicia el equipo.
2. Presiona la tecla para entrar en BIOS/UEFI (F2, F10, F12, Del, Esc). Si no sabes cuál es la tecla, prueba rápidamente al encender: F2, Del o Esc.
3. Busca secciones llamadas 'Security', 'Advanced', 'System Configuration' o 'CPU Configuration'.
4. Activa 'Intel Virtualization Technology', 'VT-x' o 'SVM' (para AMD).
5. Si aparece 'Secure Boot', desactívalo si necesitas cargar drivers no firmados (ej. virtio) o sigue el flujo para inscribir claves MOK.
6. Guarda y reinicia.

## Dell
- Teclas comunes: F2 (BIOS), F12 (Boot Menu)
- Soporte: https://www.dell.com/support/home
- Notas: Busca 'Virtualization' en 'System Configuration'.

## Lenovo
- Teclas comunes: F1, F2 (varía con modelos)
- Soporte: https://support.lenovo.com/
- Notas: Los ThinkPads suelen usar F1; IdeaPads F2.

## HP
- Teclas comunes: Esc al arrancar -> F10 para BIOS
- Soporte: https://support.hp.com/
- Notas: Virtualization suele estar en 'System Configuration' o 'Security'.

## ASUS
- Teclas comunes: Del o F2
- Soporte: https://www.asus.com/support/
- Notas: Virtualization en 'Advanced' -> 'CPU Configuration'.

## Acer
- Teclas comunes: F2
- Soporte: https://www.acer.com/worldwide/support/

## MSI
- Teclas comunes: Del
- Soporte: https://www.msi.com/support

## Recursos adicionales
- Mokutil (inscribir claves MOK para Secure Boot): https://github.com/rhboot/shim
- LVFS / fwupd para actualizaciones firmadas de firmware: https://fwupd.org/


