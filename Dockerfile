FROM debian:bookworm-slim

ENV UID=1000
ENV GID=1000
ENV SMTP_CONTAINER="mail"
ENV SMTP_EMAIL="example@mail.com"
# Keep the configuration override path used by the official PHP image.
ENV PHP_INI_DIR=/usr/local/etc/php
ENV PHP_INI_SCAN_DIR=:/usr/local/etc/php/conf.d

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL https://packages.sury.org/debsuryorg-archive-keyring.deb -o /tmp/debsuryorg-archive-keyring.deb \
    && dpkg -i /tmp/debsuryorg-archive-keyring.deb \
    && rm /tmp/debsuryorg-archive-keyring.deb \
    && echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ bookworm main" > /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        php8.0-cli \
        php8.0-fpm \
        php8.0-common \
        php8.0-curl \
        php8.0-gd \
        php8.0-intl \
        php8.0-mbstring \
        php8.0-mcrypt \
        php8.0-mysql \
        php8.0-opcache \
        php8.0-readline \
        php8.0-redis \
        php8.0-sqlite3 \
        php8.0-xml \
        php8.0-zip \
        git \
        zip \
        unzip \
        msmtp \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/sbin/php-fpm8.0 /usr/local/bin/php-fpm \
    # Use PHP's built-in defaults, as in the previous official PHP image. \
    && rm /etc/php/8.0/cli/php.ini /etc/php/8.0/fpm/php.ini \
    && mkdir -p /usr/local/etc/php/conf.d

# Fail the build if the repository does not provide the security backport.
RUN dpkg --compare-versions "$(dpkg-query -W -f='${Version}' php8.0-common)" ge '1:8.0.30-25'

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN groupadd -g ${GID} www \
    && useradd -u ${UID} -g www -m -s /bin/bash www \
    && install -d -o www -g www /var/log/msmtp /var/webserver/log/php

COPY php.ini /usr/local/etc/php/conf.d/php.ini

COPY php-fpm.conf /usr/local/etc/php-fpm.conf

# Configure connection to mail sender container.
COPY --chown=www:www .msmtprc /etc/msmtprc
COPY --chown=www:www .msmtprc /etc/msmtprc.template

WORKDIR /var/www/html
USER www

EXPOSE 9000
STOPSIGNAL SIGQUIT

CMD cp /etc/msmtprc.template /tmp/msmtprc \
    && sed -i "s/#EMAIL#/$SMTP_EMAIL/" /tmp/msmtprc \
    && sed -i "s/#CONTAINER#/$SMTP_CONTAINER/" /tmp/msmtprc \
    && cat /tmp/msmtprc >/etc/msmtprc \
    && rm /tmp/msmtprc \
    && exec php-fpm -y /usr/local/etc/php-fpm.conf -R
