FROM debian:latest
USER root
WORKDIR /app
COPY ./zig-out/bin/rinha /app/rinha
RUN chmod +x /app/rinha
ENTRYPOINT ["/app/rinha"]
