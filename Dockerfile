# ---------- Stage 1: extract the binary from the zip ----------
FROM alpine:3.20 AS extractor

RUN apk add --no-cache unzip

WORKDIR /src
COPY proxy_agent_embed.zip /src/proxy_agent_embed.zip

RUN mkdir -p /out \
 && unzip -j /src/proxy_agent_embed.zip -d /out \
 && chmod +x /out/proxy_agent \
 && test -x /out/proxy_agent

# ---------- Stage 2: minimal runtime image ----------
FROM alpine:3.20

# A truly static binary needs no libc packages.
# BusyBox already provides: sh, sleep, timeout.
COPY --from=extractor /out/proxy_agent       /usr/local/bin/proxy_agent
COPY entrypoint.sh                            /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

STOPSIGNAL SIGTERM
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
