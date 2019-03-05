# vim:set ft=dockerfile:

FROM madebyewave/nginx-php7
MAINTAINER eWave <alex@ewave.com , eldaniz.gasymov@ewave.com >
ENV PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data"

#install blackfire profiler
ENV PHP_INI_DIR="/etc/php/7.0/fpm"
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

# nginx: remove default config and enable our magento config
RUN rm /etc/nginx/sites-available/default \
    && rm /etc/nginx/sites-enabled/default \
    && ln -sf /etc/nginx/sites-available/website.conf /etc/nginx/sites-enabled/

# prepare directories & permissions for project
RUN echo 'www-data:www-data' | chpasswd \
    && echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && mkdir -p /home/www-data/public_html \
    && mkdir -p /home/www-data/state \
    && chown -R www-data:www-data /home/www-data \
    && mkdir -p /var/www/public_html \
    && chown -R www-data:www-data /var/www

# unison: copy config & sh files
ADD config/.unison/public_html.prf /home/www-data/.unison/public_html.prf
ADD config/unison.sh /usr/local/bin/unison.sh
ADD config/entrypoint.sh /usr/local/bin/entrypoint.sh
ADD config/check-unison.sh /usr/local/bin/check-unison.sh

# unison: install
RUN apt-get update && apt-get install -y \
    apt-utils \
    php-xdebug \
    make \
    ocaml \
    unzip \
    htop \
    vim \
    && curl -L https://github.com/bcpierce00/unison/archive/2.48.4.tar.gz | tar zxv -C /tmp \
    && cd /tmp/unison-2.48.4 \
    && sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' src/fsmonitor/linux/inotify_stubs.c \
    && make \
    && cp src/unison src/unison-fsmonitor /usr/local/bin \
    && cd /root \
    && rm -rf /tmp/unison-2.48.4 \
    && chmod +x /usr/local/bin/unison.sh \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/check-unison.sh \
    && npm install -g grunt-cli

# unsion: download for windows
RUN mkdir /windows \
 && cd /windows \
 && curl -L -o unison-windows.zip https://www.irif.fr/~vouillon/unison/unison%202.48.3%20-%20OCaml%204.02.1.zip \
 && unzip unison-windows.zip \
 && rm unison-windows.zip \
 && mv 'unison 2.48.3 text.exe' unison.exe \
 && rm 'unison 2.48.3 GTK.exe' \
 && chown -R www-data:www-data .

# php config
COPY config/php/ini/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini
COPY config/php/ini/zzz-custom.ini /etc/php/7.0/mods-available/zzz-custom.ini
RUN ln -sf /etc/php/7.0/mods-available/zzz-custom.ini /etc/php/7.0/cli/conf.d/99-zzz-custom.ini \
    && ln -sf /etc/php/7.0/mods-available/zzz-custom.ini /etc/php/7.0/fpm/conf.d/99-zzz-custom.ini \
    && rm -f /etc/php/7.0/cli/conf.d/20-xdebug.ini

# git config
RUN git config --add --global core.fileMode false && git config --add --global core.autocrlf input && git config --add --global core.eol lf
RUN su - www-data -c 'git config --add --global core.fileMode false && git config --add --global core.autocrlf input && git config --add --global core.eol lf'

# cleanup
RUN apt-get clean

WORKDIR /home/www-data

USER root

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]