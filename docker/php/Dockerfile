FROM php:8.0-fpm-buster
LABEL maintainer="hanadev <hanadev@gaogao.asia>"
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

ENV TZ=UTC \
    # locale
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    # composer environment
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer

COPY --from=composer:2.0 /usr/bin/composer /usr/bin/composer

RUN apt-get update && \
    apt-get -y install git libicu-dev libonig-dev libzip-dev unzip locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 && \
    localedef -f UTF-8 -i en_US en_US.UTF-8 && \
    mkdir /var/run/php-fpm && \
    docker-php-ext-install intl pdo_mysql zip bcmath && \
    composer config -g process-timeout 3600 && \
    composer config -g repos.packagist composer https://packagist.org

# Python Install
# RUN apt-get update && apt install -y \
#     zlib1g-dev \
#     libssl-dev \
#     libreadline-dev \
#     libsqlite3-dev \
#     libbz2-dev \
#     libncurses5-dev \
#     libgdbm-dev \
#     liblzma-dev \
#     tk-dev zlibc \
#     libffi-dev \
#     zip \
#     unzip \
#     && apt-get clean \
#     && curl https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz | tar zx -C /usr/local/src/ \
#     && cd /usr/local/src/Python-3.7.5 \
#     && ./configure \
#     && make && make install \
#     && ln -s /usr/local/bin/python3 /usr/local/bin/python

# RUN curl https://s3.ap-southeast-1.amazonaws.com/amazon-ssm-ap-southeast-1/latest/debian_amd64/amazon-ssm-agent.deb -o /tmp/amazon-ssm-agent.deb \
#     && dpkg -i /tmp/amazon-ssm-agent.deb \
#     && cp /etc/amazon/ssm/seelog.xml.template /etc/amazon/ssm/seelog.xml

COPY ./docker/php/php-fpm.d/zzz-www.conf /usr/local/etc/php-fpm.d/zzz-www.conf
COPY ./docker/php/php.ini /usr/local/etc/php/php.ini

WORKDIR /var/www/app

COPY ./backend .

RUN composer install --no-progress --optimize-autoloader --no-dev \
    && chmod -R 777 storage
    # && php artisan config:cache \ 
    # && php artisan view:cache 

