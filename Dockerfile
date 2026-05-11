FROM php:8.5-fpm

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
    libzip-dev \
    libpng-dev \
    libwebp-dev \
    libonig-dev \
    libbz2-dev \
    libssl-dev \
    libicu-dev \
    zip \
    unzip \
    curl \
    msmtp \
    && docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp \
    && docker-php-ext-install -j$(nproc) gd exif mbstring mysqli pdo pdo_mysql zip intl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*

COPY php.ini /usr/local/etc/php/conf.d/php.ini

# Configure connection to mail sender container
COPY .msmtprc /etc/msmtprc.template

RUN chown www:www /etc/msmtprc.template

USER www

# When runned - set msmtp configuration and up php-fpm
CMD sh -c '\
  cp /etc/msmtprc.template /etc/msmtprc && \
  sed -i "s/#EMAIL#/$SMTP_EMAIL/" /etc/msmtprc && \
  sed -i "s/#CONTAINER#/$SMTP_CONTAINER/" /etc/msmtprc && \
  exec php-fpm -F'
