# The official Synapse image with Debian's fixed packages applied at build time. Upstream copies its runtime libraries
# in as distroless-style records (/var/lib/dpkg/status.d), which apt cannot upgrade, so they are reinstalled through apt
# at their current versions and the records dropped; then the rest of the system is upgraded.
FROM matrixdotorg/synapse:v1.164.2@sha256:f0df87cff259872637b4b5e5174b9977e5e3046dd421505407803b5e45c5f842
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $(ls /var/lib/dpkg/status.d); \
    rm -rf /var/lib/dpkg/status.d; \
    apt-get upgrade -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
