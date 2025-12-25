#!/bin/bash

FUSECONF="/etc/fuse.conf"
LOGFILE="/home/deck/Scripte/fuse-check.log"
MAXSIZE=51200  # 50 KB
DATE="$(date '+%a %d. %b %H:%M:%S %Z %Y')"

# Logdatei begrenzen
if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE")" -gt "$MAXSIZE" ]; then
    rm -f "$LOGFILE"
fi

echo "🔐 FUSE Check gestartet um $DATE" >> "$LOGFILE"

# Prüfen, ob Root-Rechte vorhanden sind
if [ "$(id -u)" -eq 0 ]; then
    echo "✅ Skript läuft als root, keine Aktion nötig." >> "$LOGFILE"
    exit 0
fi

# Prüfen, ob Datei existiert
if [ ! -f "$FUSECONF" ]; then
    echo "⚠️ $FUSECONF existiert nicht. Wird angelegt..." >> "$LOGFILE"
    konsole -e "bash -c 'echo \"🔐 Root-Terminal für FUSE-Konfiguration\"; echo; sudo touch \"$FUSECONF\"; sudo chmod 644 \"$FUSECONF\"; sudo sh -c \"echo user_allow_other > $FUSECONF\"; read -r -p \"✅ Fertig. Enter zum Schließen...\" </dev/tty; exit'" &
    exit 0
fi

# Prüfen, ob 'user_allow_other' schon enthalten ist
if grep -q '^[[:space:]]*user_allow_other' "$FUSECONF" 2>/dev/null; then
    echo "✅ FUSE-Konfiguration ist korrekt." >> "$LOGFILE"
    exit 0
fi

# Prüfen, ob das System read-only ist
if grep -q "ro," /proc/mounts | grep -q "/etc"; then
    echo "⚠️ Systempartition scheint schreibgeschützt zu sein." >> "$LOGFILE"
    readonly_hint="(Möglicherweise ist steamos-readonly aktiv)"
else
    readonly_hint=""
fi

# Root-Terminal für Korrektur öffnen
echo "⚠️ FUSE nicht richtig konfiguriert. Starte Root-Terminal... $readonly_hint" >> "$LOGFILE"
konsole -e "bash -c '
echo \"🔐 Root-Terminal für FUSE-Konfiguration\";
echo;
echo \"Erstelle Backup und aktiviere user_allow_other...\";
sudo cp \"$FUSECONF\" \"$FUSECONF.bak_$(date +%s)\" 2>/dev/null;
sudo steamos-readonly disable 2>/dev/null;
if ! grep -q \"^user_allow_other\" \"$FUSECONF\" 2>/dev/null; then
    echo user_allow_other | sudo tee -a \"$FUSECONF\" >/dev/null;
fi
sudo steamos-readonly enable 2>/dev/null;
sudo chmod u+s \$(which fusermount3) 2>/dev/null;
echo;
read -r -p \"✅ FUSE-Konfiguration abgeschlossen. Enter zum Schließen...\" </dev/tty;
exit
'" &

echo "📂 Root-Terminal geöffnet, um FUSE zu reparieren." >> "$LOGFILE"
sleep 8
exit 0
