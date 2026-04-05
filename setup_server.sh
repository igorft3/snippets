#!/bin/bash
set -euo pipefail

# ========================
# CONFIG
# ========================
SSH_PORT=${SSH_PORT:-22}
ADMIN_USER=${ADMIN_USER:-""}
DISABLE_PASSWORD_AUTH=${DISABLE_PASSWORD_AUTH:-"yes"}
ALLOW_ROOT_LOGIN="prohibit-password"
TIMEZONE="UTC"

# ========================
# COLORS
# ========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

trap 'err "Ошибка на строке $LINENO"' ERR

# ========================
# ROOT CHECK
# ========================
if [[ $EUID -ne 0 ]]; then
   err "Запусти через sudo -i"
   exit 1
fi

# ========================
# OS CHECK
# ========================
source /etc/os-release
if [[ "$VERSION_ID" != "24.04" ]]; then
  warn "Скрипт рассчитан на Ubuntu 24.04 (текущая: $VERSION_ID)"
fi

log "🚀 Старт настройки системы"

# ========================
# UPDATE SYSTEM
# ========================
log "Обновление системы"
apt-get update -y
apt-get upgrade -y

# ========================
# INSTALL BASE PACKAGES
# ========================
log "Установка пакетов"
apt-get install -y \
  curl \
  vim \
  git \
  ufw \
  fail2ban \
  unattended-upgrades \
  auditd \
  audispd-plugins

# ========================
# TIME
# ========================
log "Настройка времени"
timedatectl set-timezone "$TIMEZONE"
systemctl enable --now systemd-timesyncd

# ========================
# ADMIN USER
# ========================
if [[ -n "$ADMIN_USER" ]]; then
  if ! id "$ADMIN_USER" &>/dev/null; then
    log "Создание пользователя $ADMIN_USER"
    useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
    passwd "$ADMIN_USER"
  fi
fi

# ========================
# SSH HARDENING
# ========================
log "Настройка SSH"

SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%F-%H%M%S)"

update_sshd_param() {
    local param=$1
    local value=$2
    if grep -q "^${param}" "$SSHD_CONFIG"; then
        sed -i "s/^${param}.*/${param} ${value}/" "$SSHD_CONFIG"
    elif grep -q "^#${param}" "$SSHD_CONFIG"; then
        sed -i "s/^#${param}.*/${param} ${value}/" "$SSHD_CONFIG"
    else
        echo "${param} ${value}" >> "$SSHD_CONFIG"
    fi
}

# Проверка порта
if ss -tln | awk '{print $4}' | grep -q ":${SSH_PORT}$"; then
  warn "Порт ${SSH_PORT} уже используется"
fi

update_sshd_param "Port" "${SSH_PORT}"
update_sshd_param "PermitRootLogin" "${ALLOW_ROOT_LOGIN}"
update_sshd_param "PubkeyAuthentication" "yes"
update_sshd_param "PasswordAuthentication" "$([ "$DISABLE_PASSWORD_AUTH" = "yes" ] && echo "no" || echo "yes")"
update_sshd_param "ClientAliveInterval" "300"
update_sshd_param "ClientAliveCountMax" "2"
update_sshd_param "MaxAuthTries" "3"
update_sshd_param "X11Forwarding" "no"
update_sshd_param "AllowAgentForwarding" "no"
update_sshd_param "AllowTcpForwarding" "no"
update_sshd_param "LogLevel" "AUTH"

# Проверка SSH ключей перед отключением пароля
if [[ "$DISABLE_PASSWORD_AUTH" = "yes" ]]; then
  TARGET_USER=${ADMIN_USER:-root}
  if [[ ! -f /home/$TARGET_USER/.ssh/authorized_keys && "$TARGET_USER" != "root" ]]; then
    err "Нет SSH ключей у $TARGET_USER — нельзя отключить пароль"
    exit 1
  fi
fi

sshd -t
systemctl restart ssh

# ========================
# UFW FIREWALL
# ========================
log "Настройка UFW"

ufw default deny incoming
ufw default allow outgoing
ufw allow ${SSH_PORT}/tcp
ufw --force enable

# ========================
# FAIL2BAN
# ========================
log "Настройка Fail2Ban"

cat <<EOF | tee /etc/fail2ban/jail.local >/dev/null
[DEFAULT]
bantime = 1d
findtime = 10m
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ${SSH_PORT}
EOF

systemctl enable --now fail2ban

# ========================
# UNATTENDED UPGRADES
# ========================
log "Настройка автообновлений"

dpkg-reconfigure -f noninteractive unattended-upgrades
systemctl enable --now unattended-upgrades

# ========================
# SYSCTL HARDENING
# ========================
log "Настройка sysctl"

cat <<EOF | tee /etc/sysctl.d/99-security.conf >/dev/null
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.rp_filter = 1

kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
EOF

sysctl --system

# ========================
# NEEDRESTART
# ========================
log "Настройка needrestart"

if [ -f /etc/needrestart/needrestart.conf ]; then
    sed -i "s/^#\$nrconf{restart}.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf || true
fi

# ========================
# AUDITD
# ========================
log "Запуск auditd"
systemctl enable --now auditd

# ========================
# FINAL CHECK
# ========================
log "Финальные проверки"

sshd -t || warn "Ошибка SSH"
ufw status verbose || true
fail2ban-client status || true

log "✅ Настройка завершена!"

warn "Проверь доступ по SSH перед выходом!"
warn "journalctl -xe | grep -i error"
