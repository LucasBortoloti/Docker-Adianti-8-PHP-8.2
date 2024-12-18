FROM debian:11

# Instalação do Debian e atualizações
RUN apt-get update && apt-get upgrade -y

# Instalação de facilitadores
RUN apt-get -y install locate mlocate wget apt-utils curl apt-transport-https lsb-release \
    ca-certificates software-properties-common zip unzip vim rpl apt-utils

# Correção do 'add-apt-repository command not found'
RUN apt-get install -y software-properties-common

# Adicionar repositório Sury para PHP
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    lsb-release \
    ca-certificates \
    curl \
    gnupg \
    && curl -fsSL https://packages.sury.org/php/apt.gpg | apt-key add - \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update

# Instalar PHP 8.2 e extensões necessárias
RUN apt-get install -y \
    php8.2-fpm \
    php8.2-mysqlnd \
    php8.2-pdo php8.2-pdo-mysql php8.2-sqlite3 \
    php8.2-mbstring \
    php8.2-xml php8.2-intl php8.2-dev


# Instalação do PHPUnit
RUN wget -O /usr/local/bin/phpunit-9.phar https://phar.phpunit.de/phpunit-9.0.phar; \
    chmod +x /usr/local/bin/phpunit-9.phar; \
    ln -s /usr/local/bin/phpunit-9.phar /usr/local/bin/phpunit

## Configuração personalizada do PHP para Adianti
# Set PHP custom settings
RUN echo "\n# Custom settings" >> /etc/php/8.2/fpm/php.ini \
    && echo "memory_limit = 256M"                                 >> /etc/php/8.2/fpm/php.ini \
    && echo "max_execution_time = 120"                            >> /etc/php/8.2/fpm/php.ini \
    && echo "file_uploads = On"                                   >> /etc/php/8.2/fpm/php.ini \
    && echo "post_max_size = 100M"                                >> /etc/php/8.2/fpm/php.ini \
    && echo "upload_max_filesize = 100M"                          >> /etc/php/8.2/fpm/php.ini \
    && echo "session.gc_maxlifetime = 14000"                      >> /etc/php/8.2/fpm/php.ini \
    && echo "display_errors = On"                                 >> /etc/php/8.2/fpm/php.ini \
    && echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /etc/php/8.2/fpm/php.ini

# Set PHP security settings
RUN echo "\n# Security settings"                    >> /etc/php/8.2/fpm/php.ini \
    && echo "session.name = CUSTOMSESSID"           >> /etc/php/8.2/fpm/php.ini \
    && echo "session.use_only_cookies = 1"          >> /etc/php/8.2/fpm/php.ini \
    && echo "session.cookie_httponly = true"        >> /etc/php/8.2/fpm/php.ini \
    && echo "session.use_trans_sid = 0"             >> /etc/php/8.2/fpm/php.ini \
    && echo "session.entropy_file = /dev/urandom"   >> /etc/php/8.2/fpm/php.ini \
    && echo "session.entropy_length = 32"           >> /etc/php/8.2/fpm/php.ini

## Instalação de pré-requisitos para o Drive SQL Server
RUN apt-get -y install php8.2-dev php8.2-xml php8.2-intl unixodbc-dev

# Definição da variável de ambiente ACCEPT_EULA
ENV ACCEPT_EULA=Y

# Configuração da chave GPG e lista de fontes para o repositório Microsoft SQL Server
RUN curl -s https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl -s https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update

# Instalação de pacotes adicionais
RUN apt-get install -y --no-install-recommends \
    locales \
    apt-transport-https

## Instalação do Driver SQL Server (versão mais recente compatível)
RUN pecl install sqlsrv \
    && pecl install pdo_sqlsrv

# Configuração para PHP CLI
RUN echo extension=pdo_sqlsrv.so >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini \
    && echo extension=sqlsrv.so >> `php --ini | grep "Scan for additional  .ini files" | sed -e "s|.*:\s*||"`/20-sqlsrv.ini

# Configuração para PHP WEB
RUN echo extension=pdo_sqlsrv.so >> /etc/php/8.2/fpm/conf.d/30-pdo_sqlsrv.ini \
    && echo "extension=sqlsrv.so" >> /etc/php/8.2/fpm/conf.d/20-sqlsrv.ini

# Instalação do Nginx
RUN apt-get update && apt-get install -y nginx

# Adiciona um usuário chamado "usuario" e concede privilégios temporários
USER root
RUN useradd -ms /bin/bash usuario && usermod -aG www-data usuario

# Criação de diretórios necessários e ajuste de permissões
RUN mkdir -p /run/php /var/log/nginx /var/lib/nginx/body /var/run/nginx /var/run/php \
    && chown -R usuario:usuario /run/php /var/log/nginx /var/lib/nginx /var/run/nginx /var/run/php

# Configuração do PHP-FPM
RUN service php8.2-fpm start \
    && mkdir -p /var/run/php \
    && chown -R usuario:usuario /var/run/php

# Criação manual do arquivo de PID do Nginx
RUN mkdir -p /var/run/nginx \
    && touch /var/run/nginx.pid \
    && chown -R usuario:usuario /var/run/nginx

# Criação do diretório do soquete do PHP-FPM e ajuste de permissões
RUN mkdir -p /var/run/php /var/log/php-fpm \
    && chown -R usuario:usuario /var/run/php /var/log/php-fpm

# Configuração do PHP-FPM para usar o novo diretório de log e soquete TCP/IP
RUN sed -i 's|error_log = /var/log/php8.2-fpm.log|error_log = /var/log/php-fpm/error.log|' /etc/php/8.2/fpm/php-fpm.conf \
    && sed -i 's|user = www-data|user = usuario|' /etc/php/8.2/fpm/pool.d/www.conf \
    && sed -i 's|group = www-data|group = usuario|' /etc/php/8.2/fpm/pool.d/www.conf \
    && sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 127.0.0.1:9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Configuração do nginx.conf
RUN echo "worker_processes 1;" > /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "events {" >> /etc/nginx/nginx.conf \
    && echo "    worker_connections 1024;" >> /etc/nginx/nginx.conf \
    && echo "}" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "http {" >> /etc/nginx/nginx.conf \
    && echo "    include /etc/nginx/mime.types;" >> /etc/nginx/nginx.conf \
    && echo "    default_type application/octet-stream;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "    sendfile on;" >> /etc/nginx/nginx.conf \
    && echo "    keepalive_timeout 65;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "    server {" >> /etc/nginx/nginx.conf \
    && echo "       listen 8080 default_server;" >> /etc/nginx/nginx.conf \
    && echo "       listen [::]:8080 default_server;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "       root /var/www/html/adianti8;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "       index index.php index.html index.htm index.nginx-debian.html;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "       server_name _;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "       location / {" >> /etc/nginx/nginx.conf \
    && echo "           try_files \$uri \$uri/ =404;" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "           rewrite ^/auth$ /rest.php?class=ApplicationAuthenticationRestService&method=getToken last;" >> /etc/nginx/nginx.conf \
    && echo "           rewrite ^/api/([\w]+)/([\w]+)$ /rest.php?class=$1RestService&method=handle&id=$2&$args last;" >> /etc/nginx/nginx.conf \
    && echo "           rewrite ^/api/([\w]+)/([\w]+)/([\w]+)$ /rest.php?class=$1RestService&method=$3&id=$2&$args last;" >> /etc/nginx/nginx.conf \
    && echo "           rewrite ^/api/([\w]+)$ /rest.php?class=$1RestService&method=handle&$args last;" >> /etc/nginx/nginx.conf \
    && echo "       }" >> /etc/nginx/nginx.conf \
    && echo "" >> /etc/nginx/nginx.conf \
    && echo "       location ~ \.php$ {" >> /etc/nginx/nginx.conf \
    && echo "           include snippets/fastcgi-php.conf;" >> /etc/nginx/nginx.conf \
    && echo "           fastcgi_pass 127.0.0.1:9000;" >> /etc/nginx/nginx.conf \
    && echo "           fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" >> /etc/nginx/nginx.conf \
    && echo "           include fastcgi_params;" >> /etc/nginx/nginx.conf \
    && echo "       }" >> /etc/nginx/nginx.conf \
    && echo "   }" >> /etc/nginx/nginx.conf \
    && echo "}" >> /etc/nginx/nginx.conf \
    && echo "pid /var/lib/nginx/nginx.pid;" >> /etc/nginx/nginx.conf  # Move a diretiva "pid" para fora do bloco "http"


# Muda os donos dos diretórios
RUN chown usuario:usuario /var/
RUN chown usuario:usuario /var/www/
RUN chown usuario:usuario /var/www/html/

# Remove os privilégios de root concedidos anteriormente
USER usuario

# Exporta a porta 880 para o Nginx
EXPOSE 8080

# Inicialização dos serviços
CMD php-fpm8.2 && nginx -g "daemon off;"
