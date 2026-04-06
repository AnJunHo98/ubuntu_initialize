#!/usr/bin/env bash
set -euo pipefail

log() {
  echo
  echo "[$1] $2"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

append_if_missing() {
  local line="$1"
  local file="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

log "0/13" "기본 환경 확인"
if ! need_cmd sudo; then
  echo "sudo가 필요합니다. Ubuntu Desktop 환경에서 다시 실행하세요."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

log "1/13" "패키지 인덱스 갱신 및 기본 개발 도구 설치"
sudo apt update
sudo apt install -y \
  wget curl ca-certificates gpg apt-transport-https software-properties-common gnupg lsb-release \
  build-essential cmake ninja-build pkg-config clang gdb valgrind ccache \
  git git-lfs vim nano tmux zsh unzip zip p7zip-full jq tree htop net-tools \
  openssh-client openssh-server \
  python3-pip python3-venv python3-dev pipx \
  ffmpeg libgl1 libglib2.0-0 \
  terminator \
  ibus ibus-hangul im-config language-pack-ko locales

git lfs install || true
pipx ensurepath || true

log "2/13" "한글 입력기를 IBus로 고정"
mkdir -p "$HOME"/.config/environment.d
rm -f "$HOME"/.config/environment.d/im.conf || true
im-config -n ibus || true
mkdir -p "$HOME"/.config/environment.d
cat > "$HOME"/.config/environment.d/im.conf <<'EOT'
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
SDL_IM_MODULE=ibus
INPUT_METHOD=ibus
EOT

log "3/13" "로케일 설정"
sudo locale-gen en_US en_US.UTF-8 ko_KR ko_KR.UTF-8 || true
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true

log "4/13" "Google Chrome 설치"
if ! need_cmd google-chrome; then
  wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo apt install -y /tmp/google-chrome.deb
else
  echo "Google Chrome already installed"
fi

log "5/13" "VS Code 저장소 등록 및 설치"
if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
  rm -f /tmp/microsoft.gpg
fi

sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<'EOT'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOT

sudo apt update
sudo apt install -y code

log "6/13" "Docker 공식 저장소 등록 및 설치"
sudo apt remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc || true
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOT
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOT

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER" || true
sudo systemctl enable docker || true
sudo systemctl start docker || true

log "7/13" "Miniconda 설치"
if [ ! -d "$HOME/miniconda3" ]; then
  wget -O /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
else
  echo "Miniconda already exists at $HOME/miniconda3"
fi

log "8/13" "conda bash 초기화 및 연구용 환경 생성"
if [ -x "$HOME/miniconda3/bin/conda" ]; then
  eval "$("$HOME/miniconda3/bin/conda" shell.bash hook)"
  "$HOME/miniconda3/bin/conda" init bash || true
  if ! "$HOME/miniconda3/bin/conda" env list | awk '{print $1}' | grep -qx research; then
    "$HOME/miniconda3/bin/conda" create -y -n research python=3.11
  fi
  "$HOME/miniconda3/bin/conda" run -n research python -m pip install --upgrade pip
  "$HOME/miniconda3/bin/conda" run -n research python -m pip install \
    numpy scipy pandas matplotlib jupyterlab notebook ipykernel scikit-learn sympy \
    opencv-python pyserial tqdm seaborn
fi

log "9/13" "ROS 2 Jazzy 저장소 등록 및 설치"
sudo add-apt-repository -y universe || true
sudo apt update
sudo apt install -y curl

ROS_APT_SOURCE_VERSION="$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F 'tag_name' | awk -F'"' '{print $4}')"
if [ -z "$ROS_APT_SOURCE_VERSION" ]; then
  echo "ros-apt-source 최신 버전을 가져오지 못했습니다. 네트워크를 확인하세요."
  exit 1
fi

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
sudo dpkg -i /tmp/ros2-apt-source.deb

sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-dev-tools ros-jazzy-desktop python3-colcon-common-extensions python3-rosdep
sudo rosdep init 2>/dev/null || true
rosdep update || true

log "10/13" "ROS 2 환경 및 워크스페이스 초기화"
mkdir -p "$HOME/ros2_ws/src"
append_if_missing 'source /opt/ros/jazzy/setup.bash' "$HOME/.bashrc"
append_if_missing 'if [ -f "$HOME/ros2_ws/install/setup.bash" ]; then source "$HOME/ros2_ws/install/setup.bash"; fi' "$HOME/.bashrc"
append_if_missing 'alias cw="cd $HOME/ros2_ws"' "$HOME/.bashrc"
append_if_missing 'alias cs="cd $HOME/ros2_ws/src"' "$HOME/.bashrc"
append_if_missing 'alias sb="source /opt/ros/jazzy/setup.bash"' "$HOME/.bashrc"
append_if_missing 'alias cb="cd $HOME/ros2_ws && colcon build --symlink-install"' "$HOME/.bashrc"
append_if_missing 'alias ct="colcon test --event-handlers console_direct+"' "$HOME/.bashrc"

log "11/13" "tmux 및 편의 설정"
if [ ! -f "$HOME/.tmux.conf" ]; then
  cat > "$HOME/.tmux.conf" <<'EOT'
set -g mouse on
set -g history-limit 100000
setw -g mode-keys vi
bind r source-file ~/.tmux.conf \; display-message "tmux reloaded"
EOT
fi

if ! grep -q "# user convenience aliases" "$HOME/.bashrc" 2>/dev/null; then
  {
    echo
    echo "# user convenience aliases"
    echo "alias ll='ls -alF'"
    echo "alias la='ls -A'"
    echo "alias l='ls -CF'"
  } >> "$HOME/.bashrc"
fi

git config --global init.defaultBranch main || true
if need_cmd code; then
  git config --global core.editor "code --wait" || true
fi

log "12/13" "VS Code 권장 확장 설치"
if need_cmd code; then
  code --install-extension ms-python.python || true
  code --install-extension ms-toolsai.jupyter || true
  code --install-extension ms-vscode.cpptools || true
  code --install-extension ms-iot.vscode-ros || true
  code --install-extension ms-azuretools.vscode-docker || true
fi

log "13/13" "설치 확인"
echo
echo "===== Versions ====="
git --version || true
google-chrome --version || true
code --version | head -n 1 || true
docker --version || true
docker compose version || true
"$HOME/miniconda3/bin/conda" --version || true
tmux -V || true
zsh --version || true
ros2 --version || true
colcon version-check 2>/dev/null || true
echo
echo "===== Input Method Check ====="
echo "GTK_IM_MODULE=${GTK_IM_MODULE:-<next login required>}"
echo "QT_IM_MODULE=${QT_IM_MODULE:-<next login required>}"
echo "XMODIFIERS=${XMODIFIERS:-<next login required>}"
cat "$HOME/.config/environment.d/im.conf" || true
ibus engine || true
echo
echo "===== ROS 2 Check ====="
source /opt/ros/jazzy/setup.bash || true
printenv ROS_DISTRO || true
echo "$HOME/ros2_ws"
echo
echo "===== Done ====="
