#!/bin/bash
set -e

SSH_PORT=${SSH_PORT:-22}

echo "Start setup..."

# Обновление системы
apt-get update -y
apt-get upgrade -y

# Установка пакетов
apt-get install -y fail2ban ufw

# ========================
# SSH (только порт)
# ========================
SSHD_CONFIG="/etc/ssh/sshd_config"

if grep -q "^Port" "$SSHD_CONFIG"; then
    sed -i "s/^Port.*/Port ${SSH_PORT}/" "$SSHD_CONFIG"
elif grep -q "^#Port" "$SSHD_CONFIG"; then
    sed -i "s/^#Port.*/Port ${SSH_PORT}/" "$SSHD_CONFIG"
else
    echo "Port ${SSH_PORT}" >> "$SSHD_CONFIG"
fi

systemctl restart ssh

# ========================
# UFW
# ========================
ufw default deny incoming
ufw default allow outgoing
ufw allow ${SSH_PORT}/tcp
ufw --force enable

# ========================
# Fail2Ban
# ========================
cat <<EOF > /etc/fail2ban/jail.local
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

echo "Done!"
