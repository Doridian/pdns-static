FROM alpine:3.20.3 AS builder

RUN apk --no-cache add \
    build-base \
    boost-dev \
    curl \
    git \
    wget \
    openssl-dev \
    protobuf-dev \
    sqlite-dev \
    curl-dev \
    yaml-cpp-dev \
    luajit-dev \
    libc++-static \
    ncurses-static \
    curl-static \
    clang-static \
    llvm-static \
    glib-static \
    boost-static \
    openssl-libs-static \
    c-ares-static \
    nghttp2-static \
    libidn2-static \
    libpsl-static \
    zstd-static \
    zlib-static \
    brotli-static \
    libunistring-static \
    upx \
    ca-certificates

ARG PDNS_VERSION=4.9.2
ENV PDNS_VERSION=${PDNS_VERSION}
RUN wget "https://downloads.powerdns.com/releases/pdns-${PDNS_VERSION}.tar.bz2" -O "/tmp/pdns-${PDNS_VERSION}.tar.bz2" && \
    tar -xvf "/tmp/pdns-${PDNS_VERSION}.tar.bz2" -C /tmp
WORKDIR /tmp/pdns-${PDNS_VERSION}

ENV CFLAGS="-O2 -U_FORTIFY_SOURCE -flto -pipe -static -static-libstdc++ -static-libgcc"
ENV CPPFLAGS="${CFLAGS}"
ENV CXXFLAGS="${CPPFLAGS}"
ENV LDFLAGS=""
ENV LUA_LIBS="/usr/lib/libluajit-5.1.a"

RUN sed 's~\sLIBCURL=.*$~ LIBCURL="/usr/lib/libcurl.a /usr/lib/libcares.a /usr/lib/libnghttp2.a /usr/lib/libidn2.a /usr/lib/libpsl.a /usr/lib/libssl.a /usr/lib/libcrypto.a /lib/libz.a /usr/lib/libzstd.a /usr/lib/libbrotlidec.a /usr/lib/libbrotlicommon.a /usr/lib/libunistring.a"~' -i configure && \
    sed 's~\sBOOST_PROGRAM_OPTIONS_LIBS=.*$~ BOOST_PROGRAM_OPTIONS_LIBS=/usr/lib/libboost_program_options.a~' -i configure && \
    sed 's~\sLIBCRYPTO_LIBS=.*$~ LIBCRYPTO_LIBS="/usr/lib/libcrypto.a"~g' -i configure && \
    sed 's~\sLIBSSL_LIBS=.*$~ LIBSSL_LIBS="/usr/lib/libssl.a"~g' -i configure

RUN ./configure \
        --enable-static \
        --enable-static-boost \
        --disable-shared \
        --prefix=/ \ 
        --runstatedir=/ \
        --sysconfdir=/config \
        --with-service-user=pdns \
        --with-service-group=pdns \
        --with-modules="bind lua2" \
        --with-dynmodules="" \
        --with-lua

RUN make -j$(nproc)

RUN mkdir -p /out /out/config

RUN strip --strip-all -o /out/pdns_server pdns/pdns_server && \
    strip --strip-all -o /out/pdns_control pdns/pdns_control && \
    strip --strip-all -o /out/pdnsutil pdns/pdnsutil && \
    upx -9 /out/pdns_server && \
    upx -9 /out/pdns_control && \
    upx -9 /out/pdnsutil

FROM scratch AS default

COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /out /

ENTRYPOINT [ "/pdns_server" ]
