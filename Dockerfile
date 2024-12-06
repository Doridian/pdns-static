FROM alpine:3.21.0 AS builder

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

ENV CFLAGS="-O2 -U_FORTIFY_SOURCE -flto -pipe -Wl,-static -static -static-libstdc++ -static-libgcc"
ENV CPPFLAGS="${CFLAGS}"
ENV CXXFLAGS="${CPPFLAGS}"
ENV LDFLAGS=""

RUN adduser -D pdns -h /var/empty -s /sbin/nologin
COPY curl-config /usr/local/bin/curl-config

RUN ./configure \
        --enable-static \
        --enable-static-boost \
        --disable-shared \
        --prefix=/ \
        --runstatedir=/ \
        --sysconfdir=/config \
        --with-libssl \
        --enable-ipcipher \
        --enable-dns-over-tls \
        --with-service-user=pdns \
        --with-service-group=pdns \
        --with-modules="bind lua2 pipe remote" \
        --with-dynmodules="" \
        --with-lua \
        --enable-lto

RUN make -j$(nproc)

RUN mkdir -p /out /out/config /out/var/empty && \
    strip --strip-all -o /out/pdns_server pdns/pdns_server && \
    upx -9 /out/pdns_server

FROM scratch AS default

COPY --from=builder /lib/ld-musl-*.so* /lib/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /sbin/nologin /sbin/nologin
COPY --from=builder /out /

ENTRYPOINT [ "/pdns_server" ]
