FROM docker.io/gentoo/stage3 AS builder

COPY make.conf /etc/portage/make.conf
RUN sed "s~__NPROC__~$(nproc)~g"  -i /etc/portage/make.conf

RUN emerge --sync && \
    emerge --update \
            --newuse \
            --deep \
            --exclude=app-portage/portage-utils \
            net-dns/pdns

COPY make-pdns.conf /etc/portage/make.conf

FROM scratch AS default

#COPY --from=builder /usr/bin/pdns_control /usr/bin/pdns_control
COPY --from=builder /usr/sbin/pdns_server /usr/sbin/pdns_server
#COPY --from=builder /usr/bin/pdnsutil /usr/bin/pdnsutil
COPY --from=builder /usr/lib64/powerdns /usr/lib64/powerdns
