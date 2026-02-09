# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Match the historical image layout used by OntoPortal (compose expects these paths).
ENV PATH="/opt/mgrep:${PATH}"

COPY mgrep /opt/mgrep/mgrep
COPY resources/CaseFolding.txt /srv/mgrep/CaseFolding.txt
COPY resources/word_divider.txt /srv/mgrep/word_divider.txt
COPY resources/dictionary.txt /srv/mgrep/dictionary.txt

EXPOSE 55555

# Default daemon command; deployments often override this to point at a shared dictionary.
CMD ["mgrep", "--port=55555", "-f", "/srv/mgrep/dictionary.txt", "-w", "/srv/mgrep/word_divider.txt", "-c", "/srv/mgrep/CaseFolding.txt"]

