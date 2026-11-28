# The official Synapse image with Debian's fixed packages applied at build time. Upstream copies its runtime libraries
# in as distroless-style records (/var/lib/dpkg/status.d), which apt cannot upgrade, so they are reinstalled through apt
# at their current versions and the records dropped; then the rest of the system is upgraded. gosu (start.py's
# privilege drop; Debian ships 1.17 built with Go 1.24.4) is replaced by one built with a current Go toolchain.
ARG GOSU_VERSION=1.20

# cross-compiled on the build platform (no emulation)
FROM --platform=$BUILDPLATFORM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS gosu
ARG GOSU_VERSION TARGETOS TARGETARCH
WORKDIR /src
RUN go mod init build && go get github.com/tianon/gosu@$GOSU_VERSION \
 && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags=-s -o /out/gosu github.com/tianon/gosu

FROM matrixdotorg/synapse:v1.164.2@sha256:f0df87cff259872637b4b5e5174b9977e5e3046dd421505407803b5e45c5f842
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $(ls /var/lib/dpkg/status.d | grep -vx gosu); \
    rm -rf /var/lib/dpkg/status.d; \
    apt-get upgrade -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
COPY --from=gosu /out/gosu /usr/sbin/gosu
