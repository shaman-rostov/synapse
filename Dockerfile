# The official Synapse image with Debian's fixed packages applied at build time. Upstream copies its runtime libraries
# in as distroless-style records (/var/lib/dpkg/status.d), which apt cannot upgrade, so they are reinstalled through apt
# at their current versions and the records dropped; then the rest of the system is upgraded. gosu (start.py's
# privilege drop; Debian ships 1.17 built with Go 1.24.4) is replaced by one built with a current Go toolchain.
ARG GOSU_VERSION=1.20

# cross-compiled on the build platform (no emulation)
FROM --platform=$BUILDPLATFORM golang:1.27.4-alpine@sha256:0a5f7fe796599ff487605987432e7619ae45beeb2fba4c2ce0b907879932aebf AS gosu
ARG GOSU_VERSION TARGETOS TARGETARCH
WORKDIR /src
RUN go mod init build && go get github.com/tianon/gosu@$GOSU_VERSION \
 && CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags=-s -o /out/gosu github.com/tianon/gosu

FROM matrixdotorg/synapse:v1.165.0@sha256:673b4223c81a7634fd07d832b939a58f97081cfdaae7cdd2d1664cdcf7611b62
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $(ls /var/lib/dpkg/status.d | grep -vx gosu); \
    rm -rf /var/lib/dpkg/status.d; \
    apt-get upgrade -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
COPY --from=gosu /out/gosu /usr/sbin/gosu
