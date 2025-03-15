#!/bin/bash

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка базовых инструментов
sudo apt install -y fail2ban htop curl wget net-tools unattended-upgrades apt-listchanges iptables-persistent

# Настройка автоматического обновления
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# Очистка существующих правил iptables
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X

# Установка политик по умолчанию
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Разрешение установленных соединений
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Генерация случайного порта для SSH (1024-65535)
NEW_PORT=$(shuf -i 1024-65535 -n 1)

# Открытие портов
sudo iptables -A INPUT -p tcp --dport "$NEW_PORT" -j ACCEPT  # SSH

# Настройка NAT для OpenVPN (замените eth0 на ваш интерфейс, если нужно)
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Включение пересылки IP
sudo sysctl -w net.ipv4.tcp_syncookies=1
sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
sudo sysctl -p

# Сохранение правил iptables
sudo iptables-save > /etc/iptables/rules.v4

# Настройка Fail2Ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Настройка Fail2Ban для SSH на новом порту
sudo bash -c "cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 43200
findtime = 600
maxretry = 3
logpath = /var/log/auth.log

[sshd]
enabled = true
port = $NEW_PORT
filter = sshd
action = iptables[name=SSH, port=$NEW_PORT, protocol=tcp]
EOF"

sudo systemctl restart fail2ban

# Настройка SSH
sudo sed -i "s/#Port 22/Port $NEW_PORT/" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config
sudo sed -i "s/#ClientAliveInterval.*/ClientAliveInterval 300/" /etc/ssh/sshd_config
sudo sed -i "s/#ClientAliveCountMax.*/ClientAliveCountMax 2/" /etc/ssh/sshd_config
sudo systemctl enable ssh
sudo systemctl restart sshd

# Базовая защита ядра
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3"/' /etc/default/grub
sudo update-grub

# Защита от SYN-флуда и фильтрация
sudo bash -c 'cat >> /etc/sysctl.conf <<EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF'
sudo sysctl -p

# Установка лимитов на открытые файлы
sudo bash -c 'cat >> /etc/security/limits.conf <<EOF
* hard nofile 100000
* soft nofile 100000
EOF'

# Уведомление
echo "Настройка завершена!"
echo "SSH порт изменен на: $NEW_PORT"
echo "Открытые порты: SSH ($NEW_PORT/tcp)"

# Дальнейшие советы
echo "А теперь ручками вот что сделай"
echo "Добавление нового пользователя - sudo adduser <имя_пользователя>"
echo "Запрет на вход для root-юзера по SSH PermitRootLogin no - sudo nano /etc/ssh/sshd_config"
