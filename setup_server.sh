#!/bin/bash

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка базовых инструментов
sudo apt install -y ufw fail2ban htop curl wget net-tools unattended-upgrades apt-listchanges

# Настройка автоматического обновления
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Настройка брандмауэра (UFW)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Настройка Fail2Ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Настройка правил Fail2Ban для SSH
sudo bash -c 'cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 43200
findtime = 600
maxretry = 3
logpath = /var/log/auth.log
action = iptables[name=SSH, port=ssh, protocol=tcp]
filter = sshd

[sshd]
enabled = true
EOF'

sudo systemctl restart fail2ban

# Отключение root-доступа по SSH
# sudo sed -i "s/PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
# sudo systemctl restart sshd

# Установка таймаута для SSH
# sudo sed -i "s/#ClientAliveInterval.*/ClientAliveInterval 300/" /etc/ssh/sshd_config
# sudo sed -i "s/#ClientAliveCountMax.*/ClientAliveCountMax 2/" /etc/ssh/sshd_config
# sudo systemctl restart sshd

# Базовая защита: скрытие версии ядра
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3"/' /etc/default/grub
sudo update-grub

# Отключение IPv6 (по необходимости, для безопасности)
sudo bash -c 'cat >> /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF'
sudo sysctl -p

# Установка ограничений на количество подключений
sudo bash -c 'cat >> /etc/security/limits.conf <<EOF
* hard nofile 100000
* soft nofile 100000
EOF'

# Установка защиты от SYN-флудов
sudo bash -c 'cat >> /etc/sysctl.conf <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF'
sudo sysctl -p

# Генерация случайного порта в диапазоне от 1024 до 65535
NEW_PORT=$(shuf -i 1024-65535 -n 1)

# Изменяем конфигурацию SSH для нового порта
sudo sed -i "s/#Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config

# Включаем SSH, если не включен
sudo systemctl enable ssh

# Перезапускаем SSH для применения изменений
sudo systemctl restart sshd

# Оповещаем пользователя
echo "SSH порт изменён на $NEW_PORT"

# Открываем новый порт в UFW
sudo ufw allow $NEW_PORT/tcp

# Уведомление о завершении
echo "Базовая настройка и защита сервера завершена."

# Дальнейшие советы
echo "А теперь ручками вот что сделай"
echo "Добавление нового пользователя - sudo adduser <имя_пользователя>"
echo "Запрет на вход для root-юзера по SSH PermitRootLogin no - sudo nano /etc/ssh/sshd_config"
