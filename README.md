# synapse

`ghcr.io/shaman-rostov/synapse:<version>`: the official `matrixdotorg/synapse:v<version>` pinned by digest, with
Debian's fixed packages applied, rebuilt weekly. A drop-in replacement for the official image (same `/data` layout,
user handling, entrypoint and healthcheck) for the Matrix homeserver on the oracle host.

Upstream copies its runtime libraries (libpq, OpenSSL, libxml2, …) in as distroless-style records under
`/var/lib/dpkg/status.d`, which `apt-get upgrade` does not see, so a fix such as libpq 17.12 only arrives with the
next Synapse release. The build reinstalls those packages through apt at their current versions, drops the records,
and upgrades the rest of the system. `gosu` (the entrypoint's privilege drop) is rebuilt from source with a current Go
toolchain instead of Debian's build on Go 1.24.4; `GOSU_VERSION` is bumped by hand.

Dependabot bumps the pinned base (Synapse minor releases); a major version is a deliberate change. CI starts a
throwaway SQLite homeserver and checks `/health` before publishing.

Switching: replace `matrixdotorg/synapse:v1.164.2` with `ghcr.io/shaman-rostov/synapse:1.164.2`.
