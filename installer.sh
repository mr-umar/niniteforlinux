#!/bin/bash

# ---------------------------------
#     Linux Bulk Installer 
# ---------------------------------

declare -A PROGRAMS
PROGRAMS=(
  # --- Browsers ---
  ["Brave Browser"]="brave-browser"
  ["Google Chrome"]="google-chrome-stable"
  ["Firefox"]="firefox"
  ["Chromium Browser"]="chromium-browser" # Name varies: 'chromium' on Arch/Fedora

  # --- Development & System Tools ---
  ["Visual Studio Code"]="code"
  ["Git"]="git"
  ["Docker"]="docker.io" # Name varies: 'docker' on other distros
  ["Vim"]="vim"
  ["Curl"]="curl"
  ["Wget"]="wget"
  ["htop"]="htop"
  ["Neofetch"]="neofetch"
  ["FileZilla"]="filezilla"
  ["Node.js"]="nodejs"
  ["Python 3"]="python3"

  # --- Utilities & Media ---
  ["Cloudflare WARP"]="cloudflare-warp"
  ["VLC"]="vlc"
  ["GIMP"]="gimp"
  ["Telegram Desktop"]="telegram-desktop"
  ["Spotify"]="spotify-client"
)

# --- Function to handle repository setup ---
add_third_party_repos_apt() {
    echo "Checking and adding third-party repositories for Debian/Ubuntu..."
    sudo apt-get install -y curl gpg apt-transport-https

    # Brave Browser
    if ! dpkg -s brave-browser &>/dev/null; then
        echo "-> Adding Brave Browser repository..."
        curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    fi

    # Google Chrome
    if ! dpkg -s google-chrome-stable &>/dev/null; then
        echo "-> Adding Google Chrome repository..."
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-linux-signing-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    fi

    # Cloudflare WARP
    if ! dpkg -s cloudflare-warp &>/dev/null; then
        echo "-> Adding Cloudflare WARP repository..."
        curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ stable main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
    fi

    # Spotify
    if ! dpkg -s spotify-client &>/dev/null; then
        echo "-> Adding Spotify repository..."
        curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    fi

    echo "-> Updating package list after adding repositories..."
    sudo apt-get update
}

# --- Package Manager Detection ---
PM=""
INSTALL_CMD=""
NEEDS_REPO_SETUP=false

if command -v apt-get &>/dev/null; then
    PM="apt"
    INSTALL_CMD="sudo apt-get install -y"
    NEEDS_REPO_SETUP=true
elif command -v dnf &>/dev/null; then
    PM="dnf"
    INSTALL_CMD="sudo dnf install -y"
    echo "INFO: For Chrome/Brave on Fedora, enable third-party repos or install manually."
    # Example for Chrome on Fedora:
    # sudo dnf install fedora-workstation-repositories
    # sudo dnf config-manager --set-enabled google-chrome
elif command -v pacman &>/dev/null; then
    PM="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    echo "INFO: For AUR packages like Chrome, Brave, etc., you'll need an AUR helper (e.g., yay, paru)."
    # Example: yay -S google-chrome brave-bin cloudflare-warp-bin spotify
elif command -v zypper &>/dev/null; then
    PM="zypper"
    INSTALL_CMD="sudo zypper install -y"
    echo "INFO: For third-party apps on OpenSUSE, you may need to add repositories manually via 'zypper ar'."
else
    echo "ERROR: Unsupported package manager. This script won't work."
    exit 1
fi

echo "Detected package manager: $PM"

# --- Add Repos if needed ---
if [ "$NEEDS_REPO_SETUP" = true ]; then
    add_third_party_repos_apt
fi

# --- Program Selection ---
# Use whiptail for a better UI if available
if command -v whiptail &>/dev/null; then
    CHOICES=$(whiptail --title "Program Installer" --checklist \
    "Choose programs to install (use spacebar to select):" 25 80 18 \
    $(for i in "${!PROGRAMS[@]}"; do echo "$i" "" "OFF"; done) \
    3>&1 1>&2 2>&3)
else
    echo "---"
    echo "whiptail not found, using basic text menu."
    echo "Select programs to install (e.g., 1 3 5):"
    
    mapfile -t options < <(printf "%s\n" "${!PROGRAMS[@]}")
    for i in "${!options[@]}"; do
        printf "%d) %s\n" "$((i+1))" "${options[$i]}"
    done
    
    read -p "Your selection: " -a selections_indices
    
    CHOICES_ARRAY=()
    for index in "${selections_indices[@]}"; do
        program_name="${options[$((index-1))]}"
        [[ -n "$program_name" ]] && CHOICES_ARRAY+=("\"$program_name\"")
    done
    CHOICES=$(IFS=" "; echo "${CHOICES_ARRAY[*]}")
fi

if [ -z "$CHOICES" ]; then
    echo "No programs selected. Exiting."
    exit 0
fi

# --- Installation ---
echo "The following will be installed:"
for CHOICE in $CHOICES; do echo "- $(echo $CHOICE | tr -d '"')"; done
read -p "Continue? (y/n) " -n 1 -r; echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

for CHOICE in $CHOICES; do
    CLEAN_CHOICE=$(echo $CHOICE | tr -d '"')
    PACKAGE_NAME=${PROGRAMS[$CLEAN_CHOICE]}
    
    echo "--- Installing $CLEAN_CHOICE ($PACKAGE_NAME) ---"
    $INSTALL_CMD "$PACKAGE_NAME"
    
    if [ $? -eq 0 ]; then
        echo ">>> Successfully installed $CLEAN_CHOICE."
    else
        echo "!!! FAILED to install $CLEAN_CHOICE. Check if '$PACKAGE_NAME' is correct for your system or if the repo was added correctly."
    fi
    echo
done

echo "---------------------------------"
echo "      Installation complete!     "
echo "---------------------------------"
