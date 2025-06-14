# Use lightweight Alpine Linux base
FROM alpine:latest

# Install glider and clean up
RUN apk add --no-cache wget tar 

RUN https://install.husarnet.com/tar/husarnet-latest-amd64.tar && \
    nohup .\usr\bin\husarnet-daemon &



#glider
RUN wget https://github.com/nadoo/glider/releases/download/v0.16.4/glider_0.16.4_linux_amd64.tar.gz 
RUN tar -xzf glider_0.16.4_linux_amd64.tar.gz && \
    mv glider_0.16.4_linux_amd64/glider /usr/local/bin/ && \
    rm glider_0.16.4_linux_amd64.tar.gz && \
    apk del wget

# Set credentials (change these values before building!)
ENV PROXY_USER=Prof
ENV PROXY_PASS=WhatisThisPass

# Expose proxy port
EXPOSE 8081/tcp

# Start command with dual-stack listening (IPv4 + IPv6)
CMD ["sh","-c",".\usr\bin\husarnet join fc94:b01d:1803:8dd8:b293:5c7d:7639:932a/HwfD2KFoTHQbSyTrhErzqu render-the-ai"]
CMD ["sh", "-c", "glider -listen \":8099?auth=${PROXY_USER}:${PROXY_PASS}\" -verbose"]
