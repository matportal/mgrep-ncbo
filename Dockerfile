# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS build

ARG MGREP_SOURCE_REPO=https://github.com/daimh/mgrep.git
ARG MGREP_SOURCE_REF=c6f3991a1b3f09435102ed2be6172d3a6c85342c

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      git \
      autoconf \
      automake \
      make \
      g++ \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/mgrep-src
RUN git clone --depth 1 "${MGREP_SOURCE_REPO}" . && \
    git checkout "${MGREP_SOURCE_REF}" && \
    # Upstream main() dispatch passes argc/argv unshifted into subcommands,
    # which breaks option parsing for match/extend/index.
    sed -i \
      -e 's/return MainMatch(argc, argv);/return MainMatch(argc - 1, argv + 1);/' \
      -e 's/return MainExtend(argc, argv);/return MainExtend(argc - 1, argv + 1);/' \
      -e 's/return MainIndex(argc, argv);/return MainIndex(argc - 1, argv + 1);/' \
      -e 's/if (optind + 1 != argc)/if (optind != argc)/g' \
      -e 's/char opt = getopt_long/int opt = getopt_long/g' \
      src/main.cc && \
    autoreconf -fi && \
    ./configure && \
    make -j"$(nproc)" && \
    strip src/mgrep

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      libstdc++6 && \
    rm -rf /var/lib/apt/lists/*

# Match the historical image layout used by OntoPortal (compose expects these paths).
ENV PATH="/opt/mgrep:${PATH}"

COPY --from=build /tmp/mgrep-src/src/mgrep /opt/mgrep/mgrep.bin
COPY mgrep-wrapper.sh /opt/mgrep/mgrep
COPY resources/CaseFolding.txt /srv/mgrep/CaseFolding.txt
COPY resources/word_divider.txt /srv/mgrep/word_divider.txt
COPY resources/dictionary.txt /srv/mgrep/dictionary.txt

RUN chmod +x /opt/mgrep/mgrep /opt/mgrep/mgrep.bin

EXPOSE 55555

ENTRYPOINT ["mgrep"]

# Default daemon command; deployments often override this to point at a shared dictionary.
CMD ["--port", "55555", "-f", "/srv/mgrep/dictionary.txt", "-w", "/srv/mgrep/word_divider.txt", "-c", "/srv/mgrep/CaseFolding.txt"]
