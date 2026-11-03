# ubuntu_initialize

**English** | [한국어](README.ko.md)

Setup script for a fresh Ubuntu 24.04 desktop: Korean IBus input, dev tools, Docker, Miniconda and ROS 2 Jazzy.

## Overview

A single Bash script that quickly initializes an Ubuntu 24.04 Desktop machine. In one run it sets up Korean input (IBus), common development tools, Google Chrome, VS Code, Docker, a Miniconda research environment and ROS 2 Jazzy.

The main script in this repository is `ubuntu24_init_ibus_ros2_research_v2.sh`. Its progress messages are printed in Korean.

## Target environment

- Ubuntu 24.04 Desktop
- An amd64 (x86_64) machine: the Google Chrome package and the Miniconda installer the script downloads are amd64/x86_64 builds
- An account that can use `sudo`
- A working internet connection
- A machine where it is fine to change system-wide packages and settings

## Quick start

```bash
git clone https://github.com/AnJunHo98/ubuntu_initialize.git
cd ubuntu_initialize
chmod +x ubuntu24_init_ibus_ros2_research_v2.sh
./ubuntu24_init_ibus_ros2_research_v2.sh
```

## What the script does

- Refreshes the APT package index and installs basic development tools.
- Pins the Korean input method to IBus.
- Sets the locale to `en_US.UTF-8` and also generates `ko_KR.UTF-8`.
- Installs Google Chrome and VS Code.
- Registers Docker's official repository and installs Docker Engine and the Compose plugin.
- Installs Miniconda and creates a `research` conda environment.
- Registers the ROS 2 Jazzy repository and installs the Desktop distribution and development tools.
- Also sets up `~/.bashrc`, `~/.tmux.conf`, global Git settings and VS Code extensions.

## Before you run it

- It installs a large number of system packages and adds several APT repositories.
- It tries to remove existing distro Docker packages such as `docker.io`, `docker-compose`, `containerd` and `runc`, and replaces them with Docker's official packages.
- It runs `sudo apt upgrade -y`, so existing system packages are upgraded as well.
- It modifies or creates `~/.bashrc`, `~/.tmux.conf` and `~/.config/environment.d/im.conf`.
- Log out and log back in afterwards so that the Docker group membership and the IBus environment variables take effect.
- The `code --install-extension` step assumes VS Code was installed successfully.
- The ROS 2 repository step queries the GitHub API for the latest `ros-apt-source` release at run time.
- The script runs with `set -euo pipefail`, so it stops at the first failing command, except for commands explicitly followed by `|| true`.

## Step-by-step details

### 0. Check the basic environment

- Checks that the `sudo` command exists.
- Exits immediately if it does not.
- Sets `DEBIAN_FRONTEND=noninteractive` to reduce interactive prompts during APT installs.

### 1. Refresh the package index and install basic development tools

Installs packages in these groups:

- Download and repository tools: `wget`, `curl`, `ca-certificates`, `gpg`, `apt-transport-https`, `software-properties-common`, `gnupg`, `lsb-release`
- Build tools: `build-essential`, `cmake`, `ninja-build`, `pkg-config`, `clang`, `gdb`, `valgrind`, `ccache`
- Basic CLI tools: `git`, `git-lfs`, `vim`, `nano`, `tmux`, `zsh`, `unzip`, `zip`, `p7zip-full`, `jq`, `tree`, `htop`, `net-tools`
- SSH: `openssh-client`, `openssh-server`
- Python basics: `python3-pip`, `python3-venv`, `python3-dev`, `pipx`
- Multimedia/GUI dependencies: `ffmpeg`, `libgl1`, `libglib2.0-0`, `terminator`
- Korean input and locale: `ibus`, `ibus-hangul`, `im-config`, `language-pack-ko`, `locales`

It also runs:

- `git lfs install || true`
- `pipx ensurepath || true`

### 2. Pin the Korean input method to IBus

Cleans up input method settings:

- Selects IBus as the input method framework with `im-config -n ibus`.
- Writes a new `~/.config/environment.d/im.conf`.
- Deletes any existing `im.conf` first and recreates it.

The generated content:

```ini
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
SDL_IM_MODULE=ibus
INPUT_METHOD=ibus
```

This makes GTK, Qt and SDL applications use IBus.

### 3. Configure locales

- Generates the `en_US`, `en_US.UTF-8`, `ko_KR` and `ko_KR.UTF-8` locales.
- Sets the default system locale to `LANG=en_US.UTF-8` and `LC_ALL=en_US.UTF-8`.

In other words, the system language/locale is English UTF-8, with the Korean locale also available.

### 4. Install Google Chrome

- Installs only if the `google-chrome` command is missing.
- Downloads and installs `https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb`.
- Skips this step if Chrome is already installed.

### 5. Register the VS Code repository and install VS Code

Registers the Microsoft package key and repository, then installs VS Code:

- Creates `/usr/share/keyrings/microsoft.gpg` (if it does not exist)
- Creates `/etc/apt/sources.list.d/vscode.sources`
- `sudo apt update`
- `sudo apt install -y code`

Repository entry that is added:

```text
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
```

### 6. Register Docker's official repository and install Docker

Tries to remove the distro Docker packages, then reinstalls from Docker's official repository.

Packages it tries to remove:

- `docker.io`
- `docker-compose`
- `docker-compose-v2`
- `docker-doc`
- `podman-docker`
- `containerd`
- `runc`

Then it:

- Saves Docker's GPG key to `/etc/apt/keyrings/docker.asc`
- Creates `/etc/apt/sources.list.d/docker.sources`
- Runs `sudo apt update`
- Installs:
  - `docker-ce`
  - `docker-ce-cli`
  - `containerd.io`
  - `docker-buildx-plugin`
  - `docker-compose-plugin`
- Tries to create the `docker` group
- Adds the current user to the `docker` group
- Enables and starts the Docker service

So after installation Docker is prepared for use without `sudo`, although the group change may require logging in again.

### 7. Install Miniconda

- Installs Miniconda if `~/miniconda3` does not exist.
- Does not reinstall if it already exists.
- Uses the `Miniconda3-latest-Linux-x86_64.sh` installer.

So the script assumes an x86_64 Miniconda install.

### 8. Initialize conda for bash and create the research environment

If Miniconda is installed, it:

- Enables conda in the current shell with `conda shell.bash hook`
- Runs `conda init bash`
- Creates a conda environment named `research` (`python=3.11`) if it does not exist yet
- Upgrades `pip` in the `research` environment
- Installs Python packages into the `research` environment

Python packages installed:

- `numpy`
- `scipy`
- `pandas`
- `matplotlib`
- `jupyterlab`
- `notebook`
- `ipykernel`
- `scikit-learn`
- `sympy`
- `opencv-python`
- `pyserial`
- `tqdm`
- `seaborn`

This gives a minimal research setup for data analysis, Jupyter, basic numerical computing, plotting, OpenCV and serial communication.

### 9. Register the ROS 2 Jazzy repository and install ROS 2

In this order:

- Tries to enable the `universe` repository
- Makes sure `curl` is installed
- Looks up the latest release tag of `ros-infrastructure/ros-apt-source` via the GitHub API
- Downloads and installs the `ros2-apt-source_..._all.deb` package for the current Ubuntu codename
- `sudo apt update`
- `sudo apt upgrade -y`
- Installs ROS 2 packages:
  - `ros-dev-tools`
  - `ros-jazzy-desktop`
  - `python3-colcon-common-extensions`
  - `python3-rosdep`
- `sudo rosdep init`
- `rosdep update`

This prepares the full ROS 2 Jazzy Desktop together with the build and dependency tools.

### 10. Initialize the ROS 2 environment and workspace

- Creates `~/ros2_ws/src`
- Adds ROS 2 and workspace settings to `~/.bashrc` (each line only if it is not already there)

Lines added:

```bash
source /opt/ros/jazzy/setup.bash
if [ -f "$HOME/ros2_ws/install/setup.bash" ]; then source "$HOME/ros2_ws/install/setup.bash"; fi
alias cw="cd $HOME/ros2_ws"
alias cs="cd $HOME/ros2_ws/src"
alias sb="source /opt/ros/jazzy/setup.bash"
alias cb="cd $HOME/ros2_ws && colcon build --symlink-install"
alias ct="colcon test --event-handlers console_direct+"
```

New terminals load the ROS 2 environment right away and get aliases for moving to, building and testing the workspace.

### 11. tmux and convenience settings

- Creates `~/.tmux.conf` only if it does not exist
- Enables mouse support, a larger history and vi key mode
- Adds `ll`, `la` and `l` aliases to `~/.bashrc`
- Sets the global Git default branch to `main`
- Sets the global Git editor to `code --wait` if VS Code is available

Generated `~/.tmux.conf`:

```tmux
set -g mouse on
set -g history-limit 100000
setw -g mode-keys vi
bind r source-file ~/.tmux.conf \; display-message "tmux reloaded"
```

### 12. Install recommended VS Code extensions

If the `code` command is available, installs:

- `ms-python.python`
- `ms-toolsai.jupyter`
- `ms-vscode.cpptools`
- `ms-iot.vscode-ros`
- `ms-azuretools.vscode-docker`

This prepares VS Code for Python, Jupyter, C/C++, ROS and Docker work.

### 13. Verify the installation

At the end it prints versions and status for:

- Git
- Google Chrome
- VS Code
- Docker
- Docker Compose
- conda
- tmux
- zsh
- ROS 2
- colcon
- IBus-related environment variables
- the contents of `~/.config/environment.d/im.conf`
- the current IBus engine
- `ROS_DISTRO`
- the `~/ros2_ws` path

## Files and settings changed

Main items the script creates or modifies directly:

- `~/.config/environment.d/im.conf`
- `~/.bashrc`
- `~/.tmux.conf` (created only if missing)
- `/usr/share/keyrings/microsoft.gpg`
- `/etc/apt/sources.list.d/vscode.sources`
- `/etc/apt/keyrings/docker.asc`
- `/etc/apt/sources.list.d/docker.sources`
- Global Git settings
  - `init.defaultBranch=main`
  - `core.editor="code --wait"` (when VS Code is available)
- Docker service enabled and started
- Current user added to the `docker` group
- `~/miniconda3` installed and the `research` conda environment created
- `~/ros2_ws/src` workspace created

## Expected result

When the script finishes successfully:

- General development tools and terminal utilities are installed
- Korean input with IBus + ibus-hangul is configured
- Chrome, VS Code, Docker and Miniconda are installed
- Scientific computing and Jupyter packages are ready in the `research` conda environment
- ROS 2 Jazzy Desktop, `colcon` and `rosdep` are ready to use
- New terminals have the ROS 2 environment and convenience aliases

## After running

- Log out and log back in so the Docker group and input method environment variables take effect.
- If needed, run `source ~/.bashrc` to apply the aliases and ROS settings immediately.
- Keep your ROS 2 packages under `~/ros2_ws/src`.

## Repository layout

- `ubuntu24_init_ibus_ros2_research_v2.sh`: the actual install and configuration script
- `README.ko.md`: Korean version of this README

## Status

Single-script project; last updated in April 2026.

## License

Released under the MIT License. See [LICENSE](LICENSE).
