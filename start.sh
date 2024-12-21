#!/bin/bash

# Проверяем, передана ли папка проекта
if [ -z "$1" ]; then
  echo "Пожалуйста, укажите имя папки для проекта."
  exit 1
fi

# Создаем основную папку проекта
mkdir "$1"
cd "$1" || exit

# Создаем папки
mkdir css js img font

# Создаем и заполняем файл index.html
cat <<EOL > index.html
<!DOCTYPE html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="shortcut icon" href="img/favicon.svg" type="image/x-icon" />
    <link rel="stylesheet" href="css/normalize.css" />
    <link rel="stylesheet" href="css/main.css" />
    <link rel="stylesheet" href="css/media.css" />
    <title>Title</title>
  </head>
  <body>
    <header></header>
    <main></main>
    <footer></footer>
    <script src="js/script.js"></script>
  </body>
</html>
EOL

# Создаем и заполняем файл main.css
cat <<EOL > css/main.css
@import url('font.css');
@import url('common.css');
EOL

# Создаем и заполняем файл common.css
cat <<EOL > css/common.css
* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
  scrollbar-gutter: stable;
}

body {
  color: #1f1f1d;
  font-family: "Inter", Arial, Helvetica, sans-serif;
}

h1,
h2,
h3,
h4,
h5,
h6,
p {
  margin: 0;
}

ul {
  display: flex;
  margin: 0;
  padding: 0;
  list-style: none;
}

button {
  background-color: transparent;
  border: none;
  cursor: pointer;
}

a {
  color: inherit;
  text-decoration: none;
}

/* container {
  font-family: "Inter", "Arial, Helvetica, sans-serif;
} */

body.lock-scroll {
  overflow: hidden;
}

.container {
  max-width: 1440px;
  margin: 0 auto;
}

body.lock {
  overflow: hidden;
}

.hidden {
  opacity: 0;
  visibility: hidden;
}

.visible {
  opacity: 1;
  visibility: visible;
}

.none {
  display: none;
}

EOL

# Загружаем файл normalize.css с GitHub
curl -o css/normalize.css https://raw.githubusercontent.com/necolas/normalize.css/master/normalize.css

# Создаем пустые файлы
touch css/font.css
touch css/media.css
touch js/script.js

echo "Проект $1 успешно создан."
