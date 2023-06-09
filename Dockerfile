ARG ALPINE_IMAGE=alpine
ARG ALPINE_VERSION=edge
ARG ZT_COMMIT=d831fd10d5d1a9acb46f07d9548a96fc73a23d72
ARG ZT_VERSION=1.10.6

FROM ${ALPINE_IMAGE}:${ALPINE_VERSION} AS builder

ARG ZT_COMMIT

COPY patches /patches
COPY scripts /scripts

RUN apk add --update alpine-sdk linux-headers openssl-dev \ 
  && git clone --quiet https://github.com/zerotier/ZeroTierOne.git /src \
  && git -C src reset --quiet --hard ${ZT_COMMIT} \
  && cd /src \
  && git apply /patches/* \
  && make -f make-linux.mk

FROM ${ALPINE_IMAGE}:${ALPINE_VERSION}

ARG ZT_VERSION

LABEL org.opencontainers.image.title="zerotier" \
      org.opencontainers.image.version="${ZT_VERSION}" \
      org.opencontainers.image.description="ZeroTier One as Docker Image" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/zyclonite/zerotier-docker"

COPY --from=builder /src/zerotier-one /usr/sbin/

COPY /scripts/supervisor-zerotier.conf /etc/supervisor/supervisord.conf
COPY /scripts/entrypoint.sh /entrypoint.sh
COPY /scripts/exitpoint.sh /exitpoint.sh

RUN apk add --no-cache --purge --clean-protected libc6-compat libstdc++ curl supervisor \
  && mkdir -p /var/lib/zerotier-one \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli \
  && rm -rf /var/cache/apk/*

EXPOSE 9993/udp

ENTRYPOINT ["/entrypoint.sh"]

# CMD ["-U"]
