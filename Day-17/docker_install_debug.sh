#!/usr/bin/env bash
# install_docker.sh
# Installs Docker Engine + Compose plugin on Debian/Ubuntu-based systems,with logging, error trapping, and a built-in debug/diagnostics mode.


set -Eeuo pipefail

LOG_FILE="/var/log/install_docker.log"
SCRIPT_NAME="$(basename "$0")"
DEBUG_MODE=0
MODE="install"

for arg in "$@"; do
    case "$arg" in
        --debug)     DEBUG_MODE=1 ;;
        --diagnose)  MODE="diagnose" ;;
        --uninstall) MODE="uninstall" ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

[[ "$DEBUG_MODE" -eq 1 ]] && set -x

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || LOG_FILE="./install_docker.log"
touch "$LOG_FILE" 2>/dev/null || true

log()   { printf '[%s] [INFO]  %s\n'  "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }
warn()  { printf '[%s] [WARN]  %s\n'  "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >&2; }
error() { printf '[%s] [ERROR] %s\n'  "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >&2; }

on_error() {
    local exit_code=$?
    local line_no=$1
    error "Script failed at line $line_no (exit code $exit_code)."
    error "Command was: ${BASH_COMMAND}"
    echo
    warn "Running automatic diagnostics to help pinpoint the problem..."
    run_diagnostics
    error "See $LOG_FILE for the full log. Common fixes are listed above/below in the diagnostics."
    exit "$exit_code"
}
trap 'on_error $LINENO' ERR

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "This script must be run as root (try: sudo $SCRIPT_NAME)."
        exit 1
    fi
}

detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "/etc/os-release not found — cannot detect your Linux distribution."
        error "This script supports Debian/Ubuntu family distros only."
        exit 1
    fi
    # shellcheck disable=SC1091
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_ID_LIKE="${ID_LIKE:-}"
    OS_CODENAME="${VERSION_CODENAME:-}"

    if [[ "$OS_ID" == "ubuntu" ]]; then
        DOCKER_REPO_OS="ubuntu"
    elif [[ "$OS_ID" == "debian" ]]; then
        DOCKER_REPO_OS="debian"
    elif [[ "$OS_ID_LIKE" == *debian* ]]; then
        warn "Distro '$OS_ID' is Debian-like but not officially Debian/Ubuntu."
        warn "Attempting to proceed using the Debian repository as a fallback."
        DOCKER_REPO_OS="debian"
    else
        error "Unsupported distro: $OS_ID. This script targets Debian/Ubuntu."
        error "For other distros, see: https://docs.docker.com/engine/install/"
        exit 1
    fi

    if [[ -z "$OS_CODENAME" ]]; then
        error "Could not detect VERSION_CODENAME from /etc/os-release."
        exit 1
    fi

    log "Detected OS: $OS_ID ($OS_CODENAME), using Docker repo for: $DOCKER_REPO_OS"
}

check_connectivity() {
    log "Checking network connectivity to download.docker.com..."
    if ! curl -fsSL --max-time 10 -o /dev/null "https://download.docker.com"; then
        error "Cannot reach download.docker.com. Check your internet connection,"
        error "proxy settings, or firewall rules (port 443 outbound must be open)."
        exit 1
    fi
    log "Connectivity OK."
}

check_disk_space() {
    local avail_kb
    avail_kb=$(df /var --output=avail | tail -1 | tr -d ' ')
    if [[ "$avail_kb" -lt 2097152 ]]; then # < ~2GB
        warn "Less than 2GB free on /var (found $((avail_kb/1024))MB). Docker images can be large; installation may fail later."
    fi
}

remove_conflicting_packages() {
    log "Removing any conflicting old Docker packages (if present)..."
    local pkgs=(docker.io docker-doc docker-compose podman-docker containerd runc)
    for pkg in "${pkgs[@]}"; do
        apt-get remove -y "$pkg" >>"$LOG_FILE" 2>&1 || true
    done
}

install_prereqs() {
    log "Updating apt package index..."
    apt-get update -y >>"$LOG_FILE" 2>&1

    log "Installing prerequisites (ca-certificates, curl, gnupg)..."
    apt-get install -y ca-certificates curl gnupg >>"$LOG_FILE" 2>&1
}

add_docker_repo() {
    log "Adding Docker's official GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
        curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO_OS}/gpg" \
            | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
    else
        log "GPG key already present, skipping."
    fi

    log "Adding Docker apt repository..."
    local arch
    arch="$(dpkg --print-architecture)"
    echo \
        "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_REPO_OS} ${OS_CODENAME} stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null

    log "Refreshing apt package index with new repo..."
    apt-get update -y >>"$LOG_FILE" 2>&1
}

install_docker_packages() {
    log "Installing Docker Engine, CLI, containerd, buildx, and compose plugin..."
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin >>"$LOG_FILE" 2>&1
}

enable_and_start_docker() {
    log "Enabling and starting the Docker service..."
    systemctl enable docker >>"$LOG_FILE" 2>&1
    systemctl start docker >>"$LOG_FILE" 2>&1

    log "Waiting for Docker daemon to become responsive..."
    local tries=0
    until docker info >/dev/null 2>&1; do
        tries=$((tries+1))
        if [[ "$tries" -gt 15 ]]; then
            error "Docker daemon did not become ready in time."
            return 1
        fi
        sleep 1
    done
    log "Docker daemon is running."
}

add_user_to_docker_group() {
    local target_user="${SUDO_USER:-$USER}"
    if [[ "$target_user" != "root" ]]; then
        log "Adding user '$target_user' to the 'docker' group (run without sudo after re-login)..."
        groupadd docker 2>/dev/null || true
        usermod -aG docker "$target_user"
        warn "You must log out and back in (or run 'newgrp docker') for the group change to take effect."
    fi
}

verify_installation() {
    log "Verifying installation with 'docker run hello-world'..."
    if docker run --rm hello-world >>"$LOG_FILE" 2>&1; then
        log "SUCCESS: Docker is installed and working correctly."
        docker --version | tee -a "$LOG_FILE"
        docker compose version | tee -a "$LOG_FILE"
    else
        error "'hello-world' test container failed to run."
        return 1
    fi
}

run_diagnostics() {
    echo "----------------------------------------------------------------"
    echo " DOCKER INSTALLATION DIAGNOSTICS"
    echo "----------------------------------------------------------------"

    echo "--- OS info ---"
    cat /etc/os-release 2>/dev/null || echo "No /etc/os-release found."

    echo "--- Docker service status ---"
    systemctl status docker --no-pager 2>&1 | head -n 20 || echo "systemctl not available or docker service not found."

    echo "--- Docker daemon logs (last 30 lines) ---"
    journalctl -u docker --no-pager -n 30 2>&1 || echo "journalctl not available."

    echo "--- Docker version ---"
    docker --version 2>&1 || echo "docker CLI not found."

    echo "--- Docker info ---"
    docker info 2>&1 | head -n 30 || echo "'docker info' failed — daemon likely not running or permission denied."

    echo "--- apt sources for docker ---"
    cat /etc/apt/sources.list.d/docker.list 2>/dev/null || echo "No docker.list repo file found."

    echo "--- Disk space ---"
    df -h / /var 2>&1

    echo "--- Common fixes ---"
    cat <<'EOF'
1. "Cannot connect to the Docker daemon" -> the service isn't running:
     sudo systemctl start docker
2. "permission denied while trying to connect to the Docker daemon socket" ->
     your user isn't in the docker group yet, or you haven't re-logged in:
     sudo usermod -aG docker $USER && newgrp docker
3. "E: Unable to locate package docker-ce" -> the Docker apt repo wasn't
   added correctly, or apt update wasn't run after adding it:
     sudo apt-get update
4. GPG signature errors -> the keyring file may be stale/corrupted:
     sudo rm /etc/apt/keyrings/docker.gpg   # then re-run this script
5. No internet / behind a proxy -> configure apt and Docker daemon proxy
   settings, see: https://docs.docker.com/config/daemon/systemd/#httphttps-proxy
6. Conflicting old packages (docker.io, podman-docker) -> remove them:
     sudo apt-get remove docker.io podman-docker
EOF
    echo "----------------------------------------------------------------"
}

uninstall_docker() {
    log "Stopping Docker service..."
    systemctl stop docker 2>/dev/null || true

    log "Removing Docker packages..."
    apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >>"$LOG_FILE" 2>&1 || true
    apt-get autoremove -y >>"$LOG_FILE" 2>&1 || true

    log "Removing Docker data directories (/var/lib/docker, /var/lib/containerd)..."
    rm -rf /var/lib/docker /var/lib/containerd

    log "Removing Docker apt repo and key..."
    rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg

    log "Docker uninstall"
main() {
    require_root

    case "$MODE" in
        diagnose)
            run_diagnostics
            exit 0
            ;;
        uninstall)
            detect_os
            uninstall_docker
            exit 0
            ;;
        install)
            log "Starting Docker installation on $(hostname)..."
            detect_os
            check_connectivity
            check_disk_space
            remove_conflicting_packages
            install_prereqs
            add_docker_repo
            install_docker_packages
            enable_and_start_docker
            add_user_to_docker_group
            verify_installation
            log "Installation complete. Log saved to $LOG_FILE."
            ;;
    esac
}

main "$@"
