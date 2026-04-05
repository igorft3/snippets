# Серверный скрипт базовой настройки и защиты

Этот скрипт выполняет автоматическую настройку сервера Ubuntu
Сразу после запуска скрипта:
1. Проверить порт
2. Поменять пароль
3. Открыть тот порт который надо
`
sudo ufw allow 3000
`
- И можно закрыть
`
sudo ufw delete allow 3000/tcp
`
- и перезагрузить ufw
`
sudo ufw reload
`

## Использование

1. Скачайте репозиторий и запустите скрипт одной командой:
   ```bash
   git clone -b cheklistServer https://github.com/igorft3/snippets.git && cd snippets && chmod +x setup_server.sh && sudo ./setup_server.sh
   ```

## Update IMPORTANT
- Установка и проверка брэндмауера 
