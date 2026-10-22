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
        php7.3-cli \
        php7.3-fpm \
        php7.3-common \
        php7.3-curl \
        php7.3-gd \
        php7.3-mbstring \
        php7.3-mcrypt \
        php7.3-mysql \
        php7.3-opcache \
        php7.3-readline \
        php7.3-redis \
        php7.3-sqlite3 \
        php7.3-xml \
        php7.3-zip \
        git \
        zip \
        unzip \
        msmtp \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/sbin/php-fpm7.3 /usr/local/bin/php-fpm \
    # Use PHP's built-in defaults, as in the previous official PHP image. \
    && rm /etc/php/7.3/cli/php.ini /etc/php/7.3/fpm/php.ini \
    && mkdir -p /usr/local/etc/php/conf.d

# Fail the build if the repository does not provide the security backport.
RUN dpkg --compare-versions "$(dpkg-query -W -f='${Version}' php7.3-common)" ge '7.3.33-35'

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
