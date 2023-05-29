ARG ALPINE_IMAGE=alpine
ARG ALPINE_VERSION=edge
ARG ZT_COMMIT=955143234b1600f3df934ccc2c23c9bd139e9af6
ARG ZT_VERSION=1.10.6

FROM ${ALPINE_IMAGE}:${ALPINE_VERSION} as builder

ARG ZT_COMMIT

COPY patches /patches
COPY scripts /scripts

RUN apk add --update alpine-sdk linux-headers openssl-dev \
  && git clone --quiet https://github.com/selfeky/zerotier-docker /src \
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
      org.opencontainers.image.source="https://github.com/selfeky/zerotier-docker"

COPY --from=builder /src/zerotier-one /scripts/entrypoint.sh /usr/sbin/

RUN apk add --no-cache --purge --clean-protected libc6-compat libstdc++ \
  && mkdir -p /var/lib/zerotier-one \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-idtool \
  && ln -s /usr/sbin/zerotier-one /usr/sbin/zerotier-cli \
  && rm -rf /var/cache/apk/*

EXPOSE 9993/udp

ENTRYPOINT ["entrypoint.sh"]

CMD ["-U"]
