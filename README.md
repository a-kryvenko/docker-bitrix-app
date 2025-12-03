# PHP-FPM for CMS Bitrix

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Docker image of PHP-FPM for CMS Bitrix. Image include compiled php-fpm and smtp for
sending emails through separate smtp container.

**Latest** tag based on **PHP 8.3**. Tags **:8.3**, **:8.2**, **:8.1**, **:8.0**, **:7.4** based on the corresponding php versions.

Image expects at least 2 environment variables:

 - SMTP_CONTAINER - required. Name of container, which is responsible for sending emails;
 - SMTP_EMAIL - required. Email account "From", which used to send emails;
 - UID - optional. System user id. Default: 1000;
 - GID - optional. System group id. Default: 1000.

Example of run image:

```shell
docker run -d --rm --name bitrix-application --env SMTP_CONTAINER=smtp --env SMTP_EMAIL=example@mail.com andriykryvenko/bitrix-app:8.3
```

Or via docker-compose:

```yaml
version: '3'
services:
  app:
    container_name: wApplication
    restart: always
    image: andriykryvenko/bitrix-app:8.3
    tty: true
    environment:
      SMTP_CONTAINER: "smtp"
      SMTP_EMAIL: "example@mail.com"
    expose:
      - "9000"
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

