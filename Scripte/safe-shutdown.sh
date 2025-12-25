#!/bin/bash

MOUNTPOINT="$HOME/OneDriveMount"

# Überprüfen, ob der Mountpoint gemountet ist
if ! mount | grep -q "$MOUNTPOINT"; then
    notify-send "Shutdown" "OneDrive ist nicht gemountet. Fahre herunter."
    systemctl poweroff
    exit 0
fi

# Überprüfen, ob Dateien im Mountpoint verwendet werden
COPYING=$(lsof | grep "$MOUNTPOINT" | grep -v rclone)

# Ausgabe der offenen Dateien ins Log
echo "$COPYING" > ~/rclone-open-files.log

# Wenn Dateien noch verwendet werden
if [ -n "$COPYING" ]; then
    notify-send "⚠️ Achtung" "Dateien aus OneDriveMount werden noch verwendet!"

    # Benutzer fragen, ob der Shutdown trotzdem durchgeführt werden soll
    kdialog --warningyesno "⚠️ Es sind noch Dateioperationen aktiv.\nJetzt trotzdem herunterfahren?" --title "Sicherer Shutdown"

    if [ $? -eq 0 ]; then
        # Wenn der Benutzer zustimmt
        sync
        systemctl poweroff
    else
        # Wenn der Benutzer abbricht
        notify-send "Shutdown abgebrochen"
        exit 0
    fi
else
    # Wenn keine Dateioperationen erkannt wurden
    notify-send "Herunterfahren" "Keine Dateioperationen erkannt. Fahre herunter."
    sync
    systemctl poweroff
fi
