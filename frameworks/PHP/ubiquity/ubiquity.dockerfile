FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -yqq && apt-get install -yqq software-properties-common > /dev/null
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt-get update -yqq > /dev/null && \
    apt-get install -yqq nginx git unzip php8.4 php8.4-common php8.4-cli php8.4-fpm php8.4-mysql php8.4-dev > /dev/null

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

COPY deploy/conf/* /etc/php/8.4/fpm/

ADD ./ /ubiquity
WORKDIR /ubiquity

RUN if [ $(nproc) = 2 ]; then sed -i "s|pm.max_children = 1024|pm.max_children = 512|g" /etc/php/8.4/fpm/php-fpm.conf ; fi;

RUN composer install --optimize-autoloader --classmap-authoritative --no-dev --quiet

RUN chmod 777 -R /ubiquity/app/cache/*

COPY deploy/conf/ubiquity-config.php app/config/config.php

RUN echo "opcache.preload=/ubiquity/app/config/preloader.script.php" >> /etc/php/8.4/fpm/php.ini

EXPOSE 8080

CMD service php8.4-fpm start && \
    nginx -c /ubiquity/deploy/nginx.conf -g "daemon off;"
