# Ninite for Linux

A simple Bash script to bulk-install common applications on Linux systems, inspired by Ninite for Windows.

## Quick Star

To download and run the script directly, execute the following command in your terminal. The script requires `sudo` privileges to install software and manage repositories.
```bash
curl -sS https://raw.githubusercontent.com/mr-umar/niniteforlinux/main/installer.sh | sudo bash
```

## How It Works

1.  **Detects Package Manager:** Identifies whether the system uses `apt`, `dnf`, `pacman`, `yum`, or `zypper`.
2.  **Adds Repositories:** For Debian-based systems (`apt`), it automatically adds the official repositories for third-party applications like Google Chrome, Brave, and Cloudflare WARP.
3.  **Shows Menu:** Displays an interactive menu to select which programs to install. `whiptail` is used for a better UI if available.
4.  **Installs:** Downloads and installs the selected applications in a single, non-interactive process.

## Supported systems

The script is designed to be as universal as possible:

*   **Full Support (Debian, Ubuntu, & derivatives):** Automatic repository setup and installation are fully supported. This includes distros like Linux Mint, Pop!_OS, and KDE Neon.
*   **Partial Support (Fedora, Arch Linux, OpenSUSE, etc.):** The script will work for installing applications available in the default system repositories. For applications not in the main repos (e.g., Chrome, Brave), you must add the required third-party repositories or use an AUR helper (on Arch) manually. The script provides informational messages in these cases.
