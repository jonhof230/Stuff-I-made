#!/bin/bash
# ~/.deckenv.sh – Steam Deck Userspace ENV für Profil
# ❗ Wird automatisch beim Start ausgeführt (z.B. über .bash_profile)

# Root-Schutz
if [ "$(id -u)" -eq 0 ]; then
    echo "⚠️ deckenv: nicht als root – übersprungen"
    return 0 2>/dev/null || exit 0
fi

# Wayland-Schutz
if [ -n "$WAYLAND_DISPLAY" ]; then
    echo "⚠️ Wayland läuft – ENV wird nicht aktiviert."
    return 0
fi

echo "🔹 deckenv: Normale Systemumgebung aktiv."

# Prüfen, ob ENV schon geladen wurde
if [ -n "$DECKENV_ACTIVE" ]; then
    echo "➡️ Userspace-ENV schon aktiv, übersprungen."
    return 0
fi

# Bestätigung abfragen
read -r -p "👉 Userspace-ENV aktivieren? (j/N): " __deckenv_choice
if [[ "$__deckenv_choice" =~ ^[JjYy]$ ]]; then
    export DECKENV_ACTIVE=1
    export USERROOT="$HOME/.root"

    export LD_LIBRARY_PATH="$USERROOT/lib:$USERROOT/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export C_INCLUDE_PATH="$USERROOT/usr/include${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}"
    export LIBRARY_PATH="$USERROOT/usr/lib:$USERROOT/usr/lib64${LIBRARY_PATH:+:$LIBRARY_PATH}"
    export PKG_CONFIG_PATH="$USERROOT/usr/lib/pkgconfig:$USERROOT/usr/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export PERL5LIB="$USERROOT/usr/share/perl5/vendor_perl:$USERROOT/usr/lib/perl5/5.38/vendor_perl:$USERROOT/usr/share/perl5/core_perl:$USERROOT/usr/lib/perl5/5.38/core_perl"
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$USERROOT/usr/bin:$USERROOT/usr/local/bin${PATH:+:$PATH}"


    # Benutzer-pacman
    pacman_() {
        sudo pacman \
            -r "$USERROOT" \
            --config "$USERROOT/etc/pacman.conf" \
            --gpgdir "$USERROOT/etc/pacman.d/gnupg" \
            "$@"
    }

    # NVM laden
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    # venv optional
    read -r -p "📦 Python-Projekt starten und venv aktivieren? (j/N): " __venv_choice
    if [[ "$__venv_choice" =~ ^[JjYy]$ ]]; then
        cd ~/mein-python-projekt 2>/dev/null || echo "❗ Projektordner nicht gefunden!"
        [ -f "venv/bin/activate" ] && source venv/bin/activate && echo "✅ venv aktiviert." || echo "❗ Keine Python venv gefunden."
    fi

    echo "✅ Userspace-ENV aktiviert."

else
    echo "➡️ Normale Systempfade bleiben aktiv."
    /bin/bash
fi

# Variablen aufräumen
unset __deckenv_choice __venv_choice
Based on https://www.jeromeswannack.com/projects/2024/11/29/steamdeck-userspace-pacman.html
