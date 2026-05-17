FROM php:7.3-fpm

ENV UID=1000
ENV GID=1000
ENV SMTP_CONTAINER="mail"
ENV SMTP_EMAIL="example@mail.com"

USER root

# Creating user and group
RUN groupadd -g ${GID} www || true \
 && useradd -u ${UID} -g www -m -s /bin/bash www || true

# Fix PHP-FPM user
RUN sed -i "s/^user = .*/user = www/" /usr/local/etc/php-fpm.d/www.conf \
 && sed -i "s/^group = .*/group = www/" /usr/local/etc/php-fpm.d/www.conf \
 && echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Installation of services and php extensions configuration

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libmcrypt-dev \
    libzip-dev \
    libpng-dev \
    zip \
    unzip \
    curl \
    msmtp \
    && docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ --with-freetype-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) mcrypt mysqli gd sockets zip opcache \
    && pecl install redis-5.3.7 \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

COPY php.ini /usr/local/etc/php/conf.d/php.ini

# Configure connection to mail sender container
COPY --chown=www:www .msmtprc /etc/msmtprc
COPY .msmtprc /etc/msmtprc.template

RUN chown www:www /etc/msmtprc.template

USER www

# When runned - set msmtp configuration and up php-fpm
CMD cp /etc/msmtprc.template /tmp/msmtprc \
    && sed -i "s/#EMAIL#/$SMTP_EMAIL/" /tmp/msmtprc \
    && sed -i "s/#CONTAINER#/$SMTP_CONTAINER/" /tmp/msmtprc \
    && cat /tmp/msmtprc >/etc/msmtprc \
    && rm /tmp/msmtprc \
    && php-fpm -y /usr/local/etc/php-fpm.conf -R
