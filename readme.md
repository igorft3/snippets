# Руководство по созданию проекта

Что входит в готовый скрипт
-Родительская папка 
-Папки с файлами js/css/font/img
-Файлы со стилями commin/font/main/media
-Normalize.css
-index.html со всеми подлюченными стилями

## Шаг 1: написание скрипта

- Создайте баш скрипт `start.sh` или как хотите
- Вставьте в него код из start.sh (Мой файл)

## Шаг 2: Сохранение и установка прав

```bash
chmod +x /c/<Ваш путь до файла><название файла>.sh
```

Мой пример:

```bash
chmod +x /c/Users/dev/start.sh
```

## Шаг 3: Настройка пути для вызова скрипта

### 1: Открой файл с конфигурациями

```bash
nano ~/.bashrc
```

### 2: Добавь новую запись/алиас

```bash
alias <название скрипта>="/c/<путь до файла>/<название файла>.sh"
```

Мой пример:

```bash
alias startproj="/c/Users/dev/start.sh"
```

## Шаг 4: Обнови оболочку

```bash
source ~/.bashrc
```

## Шаг 5: Запуск скрипта

```bash
<название алиаса> <название проекта>
```

Мой пример:

```bash
startproj my_project
```
