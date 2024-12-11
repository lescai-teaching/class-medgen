# docker buildx create --platform "linux/amd64,linux/arm64" --name buildermulti --use
docker buildx build \
--progress=plain \
--no-cache \
--label org.opencontainers.image.title=igv-webapp \
--label org.opencontainers.image.description='container running an IGV web app instance on nodejs' \
--label org.opencontainers.image.url=https://github.com/lescai-teaching/igv-webapp \
--label org.opencontainers.image.source=https://github.com/lescai-teaching/igv-webapp --label org.opencontainers.image.version=1.0.0 \
--label org.opencontainers.image.created=2024-12-11T10:00:11.393Z \
--label org.opencontainers.image.licenses=MIT \
--platform linux/amd64 \
--tag ghcr.io/lescai-teaching/igv-webapp:1.0.0 \
--tag ghcr.io/lescai-teaching/igv-webapp:latest \
--push .