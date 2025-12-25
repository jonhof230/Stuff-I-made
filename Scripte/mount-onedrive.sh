#!/bin/bash
set -euo pipefail

# ===============================
# Konfiguration
# ===============================
export PATH="/bin:/usr/bin:$PATH"

RCLONE="$HOME/.root/usr/bin/rclone"
MOUNTPOINT="$HOME/OneDriveMount"
LOGFILE="$HOME/Scripte/rclone-mount.log"
NOTIFY_SEND="/usr/bin/notify-send"
LOCKFILE="/home/deck/tmp/rclone-onedrive.lock"
MAX_LOG_SIZE=51200

# ===============================
# Lock gegen Doppelstarts
# ===============================
exec 9>"$LOCKFILE"
flock -n 9 || exit 0

# ===============================
# Log rotieren
# ===============================
if [ -f "$LOGFILE" ] && [ "$(stat -c%s "$LOGFILE")" -gt "$MAX_LOG_SIZE" ]; then
    : > "$LOGFILE"
fi

echo "🔧 Mount-Skript gestartet um $(date)" >> "$LOGFILE"
$NOTIFY_SEND "🔄 OneDrive Mount" "Starte…" || true

# ===============================
# Mount sauber auflösen
# ===============================
if mountpoint -q "$MOUNTPOINT"; then
    echo "⚠️ Alter Mount gefunden – unmount…" >> "$LOGFILE"
    fusermount -uz "$MOUNTPOINT" || umount -l "$MOUNTPOINT" || true
fi

mkdir -p "$MOUNTPOINT"

# ===============================
# Bereits gemountet?
# ===============================
if mountpoint -q "$MOUNTPOINT"; then
    echo "ℹ️ Mount läuft bereits." >> "$LOGFILE"
    exit 0
fi

# ===============================
# OneDrive erreichbar?
# ===============================
if ! timeout 8s "$RCLONE" about OneDrive: >/dev/null 2>&1; then
    echo "⚠️ OneDrive-Vorabcheck fehlgeschlagen – Mount wird trotzdem versucht" >> "$LOGFILE"
fi

# ===============================
# Mount starten
# ===============================
echo "🕒 Starte rclone mount…" >> "$LOGFILE"

"$RCLONE" mount OneDrive: "$MOUNTPOINT" \
  --vfs-cache-mode full \
  --vfs-cache-max-size 500M \
  --vfs-read-chunk-size 32M \
  --vfs-cache-mode writes\
  --allow-other \
  --disable-http2 \
  --timeout 1m \
  --retries 5 \
  --log-level INFO \
  --log-file "$LOGFILE" \
  --dir-cache-time 5m \
  --poll-interval 0 \
  --write-back-cache

# ===============================
# Healthcheck (einfacher)
# ===============================
sleep 5

if mountpoint -q "$MOUNTPOINT" && ls "$MOUNTPOINT" >/dev/null 2>&1; then
    echo "✅ Erfolgreich gemountet um $(date)" >> "$LOGFILE"
    $NOTIFY_SEND "✅ OneDrive Mount" "Mount aktiv" || true
else
    echo "❌ Mount fehlgeschlagen." >> "$LOGFILE"
    $NOTIFY_SEND "❌ OneDrive Mount" "Mount fehlgeschlagen – siehe Log" || true
    exit 1
fi

# ===============================
# OneDrive API Fehler nur warnen
# ===============================
if grep -q "invalidResourceId" "$LOGFILE"; then
    echo "⚠️ OneDrive API inkonsistent – überprüfe Dateien, aber Mount bleibt aktiv ($(date))" >> "$LOGFILE"
    $NOTIFY_SEND "⚠️ OneDrive Mount" "API-Fehler entdeckt – Mount bleibt aktiv" || true
fi

# ===============================
# rclone-Helper
# ===============================
rclone_move() {
    "$RCLONE" move "OneDrive:$1" "OneDrive:$2" >> "$LOGFILE" 2>&1
}

rclone_delete() {
    "$RCLONE" delete "OneDrive:$1" >> "$LOGFILE" 2>&1
}

# ===============================
# CLI
# ===============================
case "${1:-}" in
    move)   rclone_move "$2" "$3" ;;
    delete) rclone_delete "$2" ;;
esac
