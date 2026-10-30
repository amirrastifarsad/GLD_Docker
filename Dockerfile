# ---------- Stage 1: extract the binary ----------
FROM alpine:3.20 AS extractor
RUN apk add --no-cache unzip
WORKDIR /src
COPY proxy_agent_embed.zip .
RUN mkdir -p /out \
 && unzip -j proxy_agent_embed.zip -d /out \
 && chmod +x /out/proxy_agent \
 && test -x /out/proxy_agent

# ---------- Stage 2: runtime ----------
FROM alpine:3.20

ENV PORT=8080 \
    RESTART_INTERVAL=900 \
    KILL_AFTER=10

RUN mkdir -p /state /www/cgi-bin

COPY --from=extractor /out/proxy_agent /usr/local/bin/proxy_agent
COPY entrypoint.sh                    /usr/local/bin/entrypoint.sh
COPY cgi-bin/status                   /www/cgi-bin/status
RUN chmod +x /usr/local/bin/entrypoint.sh /www/cgi-bin/status

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- "http://127.0.0.1:${PORT}/cgi-bin/status" >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
