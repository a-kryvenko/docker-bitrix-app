# PHP-FPM for CMS Bitrix

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://stand-with-ukraine.pp.ua)

Docker image of PHP-FPM for CMS Bitrix. Image include compiled php-fpm and smtp for
sending emails through separate smtp container.

**Latest** tag based **PHP 8.1**. Tags **:8.1**, **:8.0**, **:7.4** based on specified php versions.

Image expects at least 2 environment variables:

 - SMTP_CONTAINER - required. Name of container, which is responsible for sending emails;
 - SMTP_EMAIL - required. Email account "From", which used to send emails;
 - UID - optional. System user id. Default: 1000;
 - GID - optional. System group id. Default: 1000.

Example of run image:

```shell
docker run -d --rm --name --env SMTP_CONTAINER=smtp --env SMTP_EMAIL=example@mail.com bitrix-application andriykryvenko/bitrix-app:8.1
```

Or via docker-compose:

```yaml
version: '3'
services:
  app:
    container_name: wApplication
    restart: always
    image: andriykryvenko/bitrix-app:8.1
    tty: true
    environment:
      SMTP_CONTAINER: "smtp"
      SMTP_EMAIL: "example@mail.com"
    ports:
      - "9000:9000"
    working_dir: /var/webserver/www
    volumes:
      - ./app:/var/webserver/www
      - ./log:/var/webserver/log
  
  smtp:
    ...
```

Logfiles stored in
 - /var/webserver/log/php/error.log - for php exceptions log
 - /var/webserver/log/php/mail.log - for email sending log

Full docker webserver for CMS Bitrix provided in **[docker-bitrix-webserver](https://github.com/a-kryvenko/docker-bitrix-webserver)** repository.

