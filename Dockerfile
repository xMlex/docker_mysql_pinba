FROM debian:jessie

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ROOT_PASSWORD=""

# ncurses-bin
RUN apt-get update && apt install -y \
    libaio1 wget bison cmake build-essential g++ libncurses5-dev libtool m4 automake --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives/* && \
    cd /opt && \
    wget --no-check-certificate -O mysql-src.tar.gz http://www.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.45.tar.gz/from/http://cdn.mysql.com/ && \
    tar xzf mysql-src.tar.gz && unlink mysql-src.tar.gz && \
    mv mysql-5.6.45 mysql-src && \
    wget --no-check-certificate -O pinba.tar.gz https://github.com/tony2001/pinba_engine/archive/RELEASE_1_2_0.tar.gz && \
    tar xzf pinba.tar.gz && unlink pinba.tar.gz && \
    cd /opt/mysql-src && mkdir -p /opt/src/mysql-boost && \
    cmake . -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DMYSQL_DATADIR=/opt/mysql/data \
    -DCMAKE_INSTALL_PREFIX=/opt/mysql \
    -DINSTALL_LAYOUT=STANDALONE -DENABLED_PROFILING=ON \
    -DMYSQL_MAINTAINER_MODE=OFF -DWITH_DEBUG=OFF \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DENABLED_LOCAL_INFILE=TRUE -DWITH_ZLIB=bundled && \
    make && make install && \
    cd /opt/pinba_engine-RELEASE_1_2_0 && \
    bash buildconf.sh && \
    ./configure \
    --with-mysql=/opt/mysql-src \
    --with-event=/usr \
    --libdir=/opt/mysql/lib/plugin && \
    make install && \
    cd / && rm -Rf /opt/pinba_engine-RELEASE_1_2_0 && \
    rm -Rf /opt/mysql-src && \
    rm -Rf /opt/src && \
    rm -Rf /opt/mysql/data/* && \
    apt remove wget bison cmake g++ libncurses5-dev libtool m4 automake -y

VOLUME /opt/mysql/data

COPY entrypoint.sh /usr/bin/
COPY run.sh /opt
COPY default_tables.sql /opt

RUN ln -s /usr/bin/entrypoint.sh /entrypoint.sh && chmod +x /usr/bin/entrypoint.sh && \
    ln -s /opt/run.sh /run.sh && chmod +x /opt/run.sh

COPY my.cnf /etc



ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3306/tcp
EXPOSE 30002/udp
CMD ["mysqld"]
