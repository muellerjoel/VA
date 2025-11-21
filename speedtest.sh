#!/bin/bash

# ======================================
# Einstellungen
# ======================================

# Ordner mit Tierbildern
# -> hier liegen: Schnecke.jpg, Schildkroete.jpg, Elefant.jpg, Kangroo.jpg, Delfin.jpg, Hund.jpg, Pferd.jpg, Vogel.jpg, Loewe.jpg, Leoprard.jpg
IMAGE_DIR="$HOME/tiere"

# Pfade zu deinen Programmen (falls sie woanders liegen, hier anpassen)
TEXT_SCROLLER="$HOME./rpi..../text-scroller"
LED_IMAGE_VIEWER="$HOME/rpi...../led-image-viewer"

# LED-Matrix-Parameter (ggf. anpassen)
LED_ROWS=64
LED_COLS=64
LED_CHAIN=4
LED_GPIO_MAPPING="adafruit-hat"

# ======================================
# Ookla Speedtest installieren (falls nicht vorhanden)
# ======================================
if ! command -v speedtest &> /dev/null; then
    echo "Installing Ookla Speedtest CLI..."

    sudo apt-get update
    sudo apt-get install -y curl gnupg

    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install -y speedtest
fi

# ======================================
# Zufälligen Server auswählen
# ======================================
echo "Fetching servers..."
server_id=$(speedtest --servers --accept-license --accept-gdpr \
    | grep -Eo "id=[0-9]+" | cut -d= -f2 | shuf -n 1)

echo "Selected random server: $server_id"

# ======================================
# Speedtest ausführen
# ======================================
echo "Running speedtest..."
output=$(speedtest --server-id="$server_id" \
                   --format=json \
                   --accept-license \
                   --accept-gdpr)

# Download / Upload extrahieren (bandwidth in Bytes/s)
download=$(echo "$output" | grep -oP '"bandwidth":\s*\K[0-9]+' | head -1)
upload=$(echo   "$output" | grep -oP '"bandwidth":\s*\K[0-9]+' | tail -1)

# Ganze Mbps (ohne Nachkommastellen) -> Bytes/s * 8 / 1_000_000
download_mbps=$(( download * 8 / 1000000 ))
upload_mbps=$(( upload * 8 / 1000000 ))

echo "Download speed: ${download_mbps} Mbps"
echo "Upload speed:   ${upload_mbps} Mbps"

# ======================================
# Tier-Stufe nach Download-Speed bestimmen
# >100 Mbps = min. Tier 1, bis 1000 in 10 Stufen
# ======================================
get_tier() {
    local s=$1

    if (( s <= 100 )); then
        echo 1         # minimale Stufe bzw. Tier
    elif (( s >= 1000 )); then
        echo 11        # maximale Stufe bzw. Tier
    else
        # 101–199 -> 1, 200–299 -> 2, ..., 900–999 -> 9
        echo $(( (s / 100 ))
    fi
}

tier=$(get_tier "$download_mbps")

# ======================================
# Bildname je nach Tier-Stufe
# ======================================
get_image_name() {
    case $1 in
        1)  echo "Schnecke.jpg" ;;
        2)  echo "Schildkroete.jpg" ;;
        3)  echo "Elefant.jpg" ;;
        4)  echo "Kangroo.jpg" ;;
        5)  echo "Delfin.jpg" ;;
        6)  echo "Hund.jpg" ;;
        7)  echo "Hase.jp" ;;
        8)  echo "Pferd.jpg" ;;
        9)  echo "Vogel.jpg" ;;
        10)  echo "Loewe.jpg" ;;
        11)  echo "Leopard.jpg" ;;
         *)  echo "" ;;
    esac
}

# ======================================
# LED-Ausgabe: Down, Up, Tier-Bild
# ======================================

# 1) Download-Wert scrollen
sudo timeout 5 "$TEXT_SCROLLER" \
    -f ../fonts/9x18.bdf \
    -C255,0,0 \
    --led-chain="$LED_CHAIN" \
    --led-gpio-mapping="$LED_GPIO_MAPPING" \
    -s0 "Down: ${download_mbps} Mbps"

# 2) Upload-Wert scrollen
sudo timeout 5 "$TEXT_SCROLLER" \
    -f ../fonts/9x18.bdf \
    -C255,0,0 \
    --led-chain="$LED_CHAIN" \
    --led-gpio-mapping="$LED_GPIO_MAPPING" \
    -s0 "Up: ${upload_mbps} Mbps"

image_file=$(get_image_name "$tier")
image_path="$IMAGE_DIR/$image_file"

if [[ -n "$image_file" && -f "$image_path" ]]; then
    echo "Showing image on LED matrix: $image_path"
    sudo timeout 10 "$LED_IMAGE_VIEWER" \
        --led-rows="$LED_ROWS" \
        --led-cols="$LED_COLS" \
        --led-chain="$LED_CHAIN" \
        --led-gpio-mapping="$LED_GPIO_MAPPING" \
        "$image_path"
else
fi

# Ende
