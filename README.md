# ubuntu_initialize

Ubuntu 24.04 Desktop 환경을 빠르게 초기화하기 위한 스크립트입니다. 한글 입력기(IBus), 개발 도구, Google Chrome, VS Code, Docker, Miniconda 연구용 환경, ROS 2 Jazzy까지 한 번에 설정합니다.

저장소에 포함된 메인 스크립트는 `ubuntu24_init_ibus_ros2_research_v2.sh` 입니다.

## 대상 환경

- Ubuntu 24.04 Desktop 계열 환경
- `sudo` 사용 가능 계정
- 인터넷 연결 가능 환경
- 시스템 전역 패키지와 설정을 변경해도 되는 머신

## 빠른 실행

```bash
cp /mnt/data/ubuntu24_init_ibus_ros2_research_v2.sh ~/
chmod +x ~/ubuntu24_init_ibus_ros2_research_v2.sh
~/ubuntu24_init_ibus_ros2_research_v2.sh
```

## 이 스크립트가 하는 일

- APT 패키지 인덱스를 갱신하고 기본 개발 도구를 설치합니다.
- 한글 입력기를 IBus 기반으로 고정합니다.
- 로케일을 `en_US.UTF-8` 중심으로 설정하고 `ko_KR.UTF-8`도 생성합니다.
- Google Chrome과 VS Code를 설치합니다.
- Docker 공식 저장소를 등록하고 Docker Engine 및 Compose 플러그인을 설치합니다.
- Miniconda를 설치하고 `research` 가상환경을 생성합니다.
- ROS 2 Jazzy 저장소를 등록하고 Desktop 배포판과 개발 도구를 설치합니다.
- `~/.bashrc`, `~/.tmux.conf`, Git 전역 설정, VS Code 확장까지 함께 정리합니다.

## 실행 전 주의사항

- 시스템 패키지를 대량으로 설치하고, 여러 APT 저장소를 추가합니다.
- `docker.io`, `docker-compose`, `containerd`, `runc` 같은 기존 Docker 관련 패키지는 제거 시도 후 Docker 공식 패키지로 교체합니다.
- `sudo apt upgrade -y` 가 포함되어 있어 기존 시스템 패키지도 함께 업그레이드됩니다.
- `~/.bashrc`, `~/.tmux.conf`, `~/.config/environment.d/im.conf` 를 수정하거나 생성합니다.
- Docker 그룹 반영과 IBus 환경 변수 반영을 위해 로그아웃 후 다시 로그인하는 것이 좋습니다.
- `code --install-extension` 단계는 VS Code가 정상 설치된 환경을 전제로 합니다.
- ROS 2 저장소 등록 단계는 실행 시점의 최신 `ros-apt-source` 릴리스를 GitHub API로 조회합니다.

## 단계별 상세 설명

### 0. 기본 환경 확인

- `sudo` 명령이 있는지 확인합니다.
- 없으면 바로 종료합니다.
- `DEBIAN_FRONTEND=noninteractive` 를 설정해서 APT 설치 중 대화형 입력을 줄입니다.

### 1. 패키지 인덱스 갱신 및 기본 개발 도구 설치

다음 범주의 패키지를 설치합니다.

- 다운로드 및 저장소 관련: `wget`, `curl`, `ca-certificates`, `gpg`, `apt-transport-https`, `software-properties-common`, `gnupg`, `lsb-release`
- 빌드 도구: `build-essential`, `cmake`, `ninja-build`, `pkg-config`, `clang`, `gdb`, `valgrind`, `ccache`
- 기본 CLI 도구: `git`, `git-lfs`, `vim`, `nano`, `tmux`, `zsh`, `unzip`, `zip`, `p7zip-full`, `jq`, `tree`, `htop`, `net-tools`
- SSH: `openssh-client`, `openssh-server`
- Python 기본 환경: `python3-pip`, `python3-venv`, `python3-dev`, `pipx`
- 멀티미디어/GUI 의존성: `ffmpeg`, `libgl1`, `libglib2.0-0`, `terminator`
- 한글 입력 및 로케일 관련: `ibus`, `ibus-hangul`, `im-config`, `language-pack-ko`, `locales`

추가로 다음도 실행합니다.

- `git lfs install || true`
- `pipx ensurepath || true`

### 2. 한글 입력기를 IBus로 고정

입력기 관련 설정을 정리합니다.

- `im-config -n ibus` 로 입력기 프레임워크를 IBus로 지정합니다.
- `~/.config/environment.d/im.conf` 파일을 새로 작성합니다.
- 기존 `im.conf` 가 있으면 삭제 후 다시 생성합니다.

생성되는 내용은 아래와 같습니다.

```ini
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
XMODIFIERS=@im=ibus
SDL_IM_MODULE=ibus
INPUT_METHOD=ibus
```

이 설정은 GTK, Qt, SDL 계열 애플리케이션에서 IBus를 사용하도록 유도합니다.

### 3. 로케일 설정

다음 작업을 수행합니다.

- `en_US`, `en_US.UTF-8`, `ko_KR`, `ko_KR.UTF-8` 로케일 생성
- 기본 시스템 로케일을 `LANG=en_US.UTF-8`, `LC_ALL=en_US.UTF-8` 로 설정

즉, 시스템 기본 언어/로케일은 영문 UTF-8로 맞추고, 한국어 로케일도 함께 사용할 수 있게 준비합니다.

### 4. Google Chrome 설치

- `google-chrome` 명령이 없을 때만 설치합니다.
- `https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb` 를 내려받아 설치합니다.
- 이미 설치되어 있으면 건너뜁니다.

### 5. VS Code 저장소 등록 및 설치

Microsoft 패키지 키와 저장소를 등록한 뒤 VS Code를 설치합니다.

- `/usr/share/keyrings/microsoft.gpg` 생성
- `/etc/apt/sources.list.d/vscode.sources` 생성
- `sudo apt update`
- `sudo apt install -y code`

추가되는 저장소 정보는 아래와 같습니다.

```text
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
```

### 6. Docker 공식 저장소 등록 및 설치

기존 배포판 Docker 패키지를 제거 시도한 뒤 Docker 공식 저장소 기반으로 다시 설치합니다.

제거 시도 대상:

- `docker.io`
- `docker-compose`
- `docker-compose-v2`
- `docker-doc`
- `podman-docker`
- `containerd`
- `runc`

이후 수행되는 작업:

- `/etc/apt/keyrings/docker.asc` 에 Docker GPG 키 저장
- `/etc/apt/sources.list.d/docker.sources` 생성
- `sudo apt update`
- 다음 패키지 설치
  - `docker-ce`
  - `docker-ce-cli`
  - `containerd.io`
  - `docker-buildx-plugin`
  - `docker-compose-plugin`
- `docker` 그룹 생성 시도
- 현재 사용자를 `docker` 그룹에 추가
- Docker 서비스 `enable` 및 `start`

즉, 설치 후에는 `sudo` 없이 Docker를 쓰기 위한 준비까지 같이 합니다. 다만 그룹 반영은 재로그인이 필요할 수 있습니다.

### 7. Miniconda 설치

- `~/miniconda3` 디렉터리가 없으면 Miniconda를 설치합니다.
- 이미 있으면 재설치하지 않습니다.
- 설치 파일은 `Miniconda3-latest-Linux-x86_64.sh` 를 사용합니다.

즉, 이 스크립트는 x86_64 기준 Miniconda 설치 경로를 가정합니다.

### 8. conda bash 초기화 및 연구용 환경 생성

Miniconda가 설치되어 있으면 다음을 수행합니다.

- `conda shell.bash hook` 로 현재 셸에서 conda 사용 가능하게 설정
- `conda init bash`
- `research` 이름의 conda 환경 생성 (`python=3.11`)
- `research` 환경의 `pip` 업그레이드
- `research` 환경에 Python 패키지 설치

설치되는 Python 패키지:

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

즉, 데이터 분석, Jupyter, 기초 수치 계산, 시각화, OpenCV, 시리얼 통신까지 바로 연구용으로 쓸 수 있는 최소 구성을 만듭니다.

### 9. ROS 2 Jazzy 저장소 등록 및 설치

다음 순서로 진행합니다.

- `universe` 저장소 활성화 시도
- `curl` 설치 보장
- GitHub API에서 `ros-infrastructure/ros-apt-source` 최신 릴리스 태그 조회
- 현재 Ubuntu 코드네임에 맞는 `ros2-apt-source_..._all.deb` 패키지 다운로드 및 설치
- `sudo apt update`
- `sudo apt upgrade -y`
- ROS 2 관련 패키지 설치
  - `ros-dev-tools`
  - `ros-jazzy-desktop`
  - `python3-colcon-common-extensions`
  - `python3-rosdep`
- `sudo rosdep init`
- `rosdep update`

즉, ROS 2 Jazzy Desktop 전체와 빌드/의존성 도구를 함께 준비합니다.

### 10. ROS 2 환경 및 워크스페이스 초기화

- `~/ros2_ws/src` 생성
- `~/.bashrc` 에 ROS 2 및 워크스페이스 관련 설정 추가

추가되는 내용:

```bash
source /opt/ros/jazzy/setup.bash
if [ -f "$HOME/ros2_ws/install/setup.bash" ]; then source "$HOME/ros2_ws/install/setup.bash"; fi
alias cw="cd $HOME/ros2_ws"
alias cs="cd $HOME/ros2_ws/src"
alias sb="source /opt/ros/jazzy/setup.bash"
alias cb="cd $HOME/ros2_ws && colcon build --symlink-install"
alias ct="colcon test --event-handlers console_direct+"
```

즉, 새 터미널을 열면 ROS 2 기본 환경을 바로 불러오고, 워크스페이스 이동/빌드/테스트용 alias도 함께 제공합니다.

### 11. tmux 및 편의 설정

다음 작업을 수행합니다.

- `~/.tmux.conf` 가 없을 때만 생성
- 마우스 사용, 히스토리 확장, vi 키 모드 설정
- `~/.bashrc` 에 `ll`, `la`, `l` alias 추가
- Git 전역 기본 브랜치를 `main` 으로 설정
- VS Code가 있으면 Git 전역 에디터를 `code --wait` 로 설정

생성되는 `~/.tmux.conf` 내용:

```tmux
set -g mouse on
set -g history-limit 100000
setw -g mode-keys vi
bind r source-file ~/.tmux.conf \; display-message "tmux reloaded"
```

### 12. VS Code 권장 확장 설치

`code` 명령이 있으면 다음 확장을 설치합니다.

- `ms-python.python`
- `ms-toolsai.jupyter`
- `ms-vscode.cpptools`
- `ms-iot.vscode-ros`
- `ms-azuretools.vscode-docker`

즉, Python, Jupyter, C/C++, ROS, Docker 작업을 바로 시작할 수 있게 맞춥니다.

### 13. 설치 확인

설치 마지막에는 버전과 상태를 출력합니다.

확인 대상:

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
- IBus 관련 환경 변수
- `~/.config/environment.d/im.conf` 내용
- 현재 IBus 엔진
- `ROS_DISTRO`
- `~/ros2_ws` 경로

## 변경되는 파일 및 설정 요약

이 스크립트가 직접 생성하거나 수정하는 대표 항목은 아래와 같습니다.

- `~/.config/environment.d/im.conf`
- `~/.bashrc`
- `~/.tmux.conf` (없을 때만 생성)
- `/usr/share/keyrings/microsoft.gpg`
- `/etc/apt/sources.list.d/vscode.sources`
- `/etc/apt/keyrings/docker.asc`
- `/etc/apt/sources.list.d/docker.sources`
- Git 전역 설정
  - `init.defaultBranch=main`
  - `core.editor="code --wait"` (VS Code가 있을 때)
- Docker 서비스 활성화 및 시작
- 현재 사용자의 Docker 그룹 추가
- `~/miniconda3` 설치 및 `research` conda 환경 생성
- `~/ros2_ws/src` 워크스페이스 생성

## 설치 결과 요약

스크립트가 정상 완료되면 다음 상태를 기대할 수 있습니다.

- 일반 개발 도구와 터미널 유틸리티가 설치됨
- IBus + ibus-hangul 기반 한글 입력 환경이 구성됨
- Chrome, VS Code, Docker, Miniconda가 설치됨
- `research` conda 환경에서 과학 계산 및 Jupyter 관련 패키지를 바로 사용 가능함
- ROS 2 Jazzy Desktop 및 `colcon`, `rosdep` 사용 준비가 끝남
- 새 터미널에서 ROS 2 환경과 편의 alias를 바로 사용할 수 있음

## 실행 후 권장 사항

- 로그아웃 후 다시 로그인해서 Docker 그룹과 입력기 환경 변수를 반영하는 것을 권장합니다.
- 필요하면 `source ~/.bashrc` 를 실행해 alias와 ROS 설정을 즉시 반영합니다.
- ROS 2 워크스페이스를 사용할 때는 `~/ros2_ws/src` 아래에서 패키지를 관리하면 됩니다.

## 포함 파일

- `ubuntu24_init_ibus_ros2_research_v2.sh`: 실제 설치 및 설정 스크립트
