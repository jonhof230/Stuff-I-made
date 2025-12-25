#!/bin/bash
# SteamDeck Optimized Monitor (korrigiert)

clear
echo "=== SteamDeck Performance Monitor ==="
echo "Drücke CTRL+C zum Beenden."
echo ""

while true; do
    echo "----- RAM & Swap -----"
    free -h
    echo ""

    echo "----- ZRAM -----"
    cat /proc/swaps | grep zram || echo "Keine ZRAM gefunden"
    echo ""

    echo "----- Swapfile -----"
    cat /proc/swaps | grep swapfile || echo "Keine Swapfile gefunden"
    echo ""

    echo "----- NVMe I/O -----"
    nvme_stat=$(cat /sys/block/nvme0n1/stat)
    read -r r_c r_m r_s r_t w_c w_m w_s w_t ios iot wt <<< "$nvme_stat"
    echo "Reads completed: $r_c, Writes completed: $w_c"
    echo "Sectors read: $r_s, Sectors written: $w_s"
    echo "I/O in progress: $ios, Time doing I/O (ms): $iot"
    echo ""

    echo "----- Network -----"
    echo "Default Queueing: $(sysctl -n net.core.default_qdisc)"
    echo "TCP Congestion Control: $(sysctl -n net.ipv4.tcp_congestion_control)"
    echo "Ping 8.8.8.8 (1 Paket):"
    ping -c1 8.8.8.8 | grep time || echo "Ping fehlgeschlagen"

    echo ""
    sleep 2
done
