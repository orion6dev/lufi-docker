FROM debian:12-slim

ARG LUFI_VERSION=0.07.3
ARG GID=1000
ARG UID=1000


USER root

RUN apt update \
	&& apt install -y \
    wget \
    unzip \
    cron \
    sudo \
	build-essential \
	libssl-dev \
    zlib1g-dev \
	libio-socket-ssl-perl \
 	libmariadbd-dev \
	libmariadb-dev-compat \
	libmojo-pg-perl \
	liblwp-protocol-https-perl \
	&& apt-get clean -y \
    && rm -rf /var/lib/{apt,dpkg,cache,log,tmp}/*

RUN addgroup --gid "$GID" nonroot
RUN adduser --uid "$UID" --gid "$GID" --disabled-password --gecos "" nonroot
RUN echo 'nonroot ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# copie des cron
COPY --chmod=644 lufi-cron /etc/cron.d/lufi-cron

RUN cpan Carton

WORKDIR /home/nonroot/lufi


RUN wget https://framagit.org/fiat-tux/hat-softwares/lufi/-/archive/${LUFI_VERSION}/lufi-${LUFI_VERSION}.zip \
    && unzip lufi-${LUFI_VERSION}.zip -d /tmp \
    && mv /tmp/lufi-${LUFI_VERSION}/* /home/nonroot/lufi \
    && rm -rf /tmp/* \ 
    && rm -rf /home/nonroot/lufi/lufi-${LUFI_VERSION}.zip


# Apply patch to catch notifs errors (https://framagit.org/fiat-tux/hat-softwares/lufi/-/commit/55a0dbfeebe85bd7d8aef79b84e36d8b710221ca)
COPY --chown=nonroot:nonroot catch_notifs_error.diff .
RUN patch -p1 <catch_notifs_error.diff && rm -f catch_notifs_error.diff

COPY --chown=nonroot:nonroot lufi.conf .
RUN mkdir -p themes/megalis/
COPY themes/megalis themes/megalis/
COPY --chmod=760 --chown=nonroot:nonroot docker-entrypoint.sh /home/nonroot/lufi/docker-entrypoint.sh

RUN carton install --deployment --without=test  \
    && rm -rf local/cache/* local/man/*
RUN chown -R nonroot:nonroot .

EXPOSE 8081
USER nonroot

RUN mkdir /home/nonroot/lufi/files

ENTRYPOINT ["/home/nonroot/lufi/docker-entrypoint.sh"]
