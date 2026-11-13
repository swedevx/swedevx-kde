# SweDevX KDE Setup

A ready‑to‑run installer that configures a KDE Plasma workstation on Fedora or Arch Linux.
The script pulls in dotfiles, installs packages, and applies system settings so you can jump straight into work or personal use.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Dotfiles](#dotfiles)
- [Directory Layout](#directory-layout)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview
This repository contains a collection of Bash scripts that automate the setup of a KDE Plasma desktop environment tailored to either a *personal* or *work* profile.
The installation is idempotent – running it multiple times will only install missing components.
All state is recorded under `$XDG_STATE_HOME/system-setup/selected`.

## Features
- **Dual profiles** – `personal` (default) and `work` with extra dev‑tools.
- **Distro detection** – supports Fedora (dnf) and Arch (pacman) automatically.
- **Dotfiles integration** – copies your `.zshrc`, `.vimrc`, etc. from `dotfiles/`.
- **Wallpaper set‑up** – KDE wallpapers are installed from `wallpapers/`.
- **System settings** – a curated set of Plasma tweaks in `scripts/install/system-settings.sh`.
- **Idempotent phases** – each phase checks whether the necessary packages or configuration already exist.

## Prerequisites
- A clean installation of **Fedora 39/40** or **Arch Linux** with the **KDE Plasma** meta‑package already installed.
- Internet access and `sudo` privileges.
- `git` installed locally.

## Installation
```bash
# Clone the repo
git clone https://github.com/swedevx/swedevx-kde.git
cd swedevx-kde

# Make the installer executable
chmod +x install.sh

# Run with the default personal profile
./install.sh

# Or run with the work profile
./install.sh --profile work
```

`install.sh` orchestrates the whole process:

1. Detects the distribution and sets the correct package manager.
2. Sources the shared library `scripts/install/lib.sh` (logging, helper functions).
3. Executes each phase script in order (`prerequisites.sh`, `packages.sh`, `dotfiles.sh`, `system-settings.sh`, etc.).
4. Records installed components in `$XDG_STATE_HOME/system-setup/selected`.

## Configuration
After the installer finishes, you can tweak the following:

- KDE system settings are stored in `~/.config/plasma-org.kde.plasma.desktop-appletsrc`.
- Dotfiles are copied to your home directory; edit them manually if you need customizations.
- To change the profile, edit the `--profile` flag or rerun the installer.

## Dotfiles
The `dotfiles/` directory contains personal configuration files for:

- `zshrc`
- `vimrc`
- `gitconfig`
- `tmux.conf`
- (add more as needed)

These are copied into the user's home directory during the `dotfiles.sh` phase.

## Directory Layout
```
├── install.sh
├── scripts
│   └── install
│       ├── lib.sh          # Helper functions
│       ├── prerequisites.sh
│       ├── packages.sh
│       ├── dotfiles.sh
│       ├── system-settings.sh
│       └── ... (other phases)
├── dotfiles/               # User dotfiles
├── wallpapers/             # KDE wallpapers
├── .gitignore
├── LICENSE
└── README.md
```

## Troubleshooting
| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `sudo: command not found` | `sudo` not installed | Install sudo manually. |
| Package manager errors | Incorrect distro detection | Verify `install.sh` runs on a supported OS. |
| Files not copied | Permissions issue | Run installer with `sudo` or ensure your user has write rights to the target directories. |
| KDE not loading custom wallpaper | `plasma-desktop` not restarted | Log out/in or restart Plasma after installation. |

## Contributing
Pull requests are welcome!  
1. Fork the repository.  
2. Create a feature branch.  
3. Run `./install.sh --profile personal` locally to test changes.  
4. Open a PR with clear description and tests if applicable.

## License
This project is licensed under the [MIT License](LICENSE).
