FROM php:7.1.9-alpine

ENV BUILD_DEPS \
                cmake \
                autoconf \
                g++ \
                gcc \
                make \
                pcre-dev \
                openssl-dev \
                libuv-dev \
                gmp-dev

RUN docker-php-ext-install pdo_mysql

RUN apk update && apk add --no-cache --virtual .build-deps $BUILD_DEPS \
    && apk add --no-cache git libuv gmp libstdc++ mariadb-client python py-pip

# Install DataStax C/C++ Driver
WORKDIR /lib
RUN git clone https://github.com/datastax/cpp-driver.git cpp-driver \
    && cd cpp-driver \
    && mkdir build \
    && cd build \
    && cmake -DCASS_BUILD_STATIC=ON -DCASS_BUILD_SHARED=ON .. \
    && make -j4 \
    && make install

RUN ln -s /usr/local/lib64/* /usr/local/lib \
    && ln -s /usr/lib64/* /usr/lib

# Install Cassandra PHP extension
RUN pecl install cassandra-1.3.2 --with-cassandra=/lib/cpp-driver  \
    && docker-php-ext-enable cassandra \
    && php -m | grep cassandra


# Install composer
WORKDIR /tmp
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Install cqlsh
RUN pip install cqlsh

# Remove builddeps
RUN apk del .build-deps

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]