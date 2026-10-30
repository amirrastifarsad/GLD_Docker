# ---------- Stage 1: extract proxy_agent from the zip ----------
FROM alpine:3.20 AS extractor
RUN apk add --no-cache unzip
WORKDIR /src
COPY proxy_agent_embed.zip .
RUN mkdir -p /out \
 && unzip -j proxy_agent_embed.zip -d /out \
 && chmod +x /out/proxy_agent \
 && test -x /out/proxy_agent

# ---------- Stage 2: runtime (prebuilt supervisor) ----------
FROM alpine:3.20


COPY --from=extractor /out/proxy_agent /usr/local/bin/proxy_agent
COPY supervisor                       /usr/local/bin/supervisor
RUN chmod +x /usr/local/bin/supervisor

EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://127.0.0.1:10000/status >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/supervisor"]
