#syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine AS build
WORKDIR /app

ARG MMPROXY_REPO=https://github.com/path-network/go-mmproxy.git
ARG MMPROXY_REF=006247ca7ec618d2aff02052bac839ca769991a1
ADD --keep-git-dir=false "$MMPROXY_REPO#$MMPROXY_REF" .

ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=cache,target=/root/.cache \
  CGO_ENABLED=0 GOOS="$TARGETOS" GOARCH="$TARGETARCH" \
  go build -ldflags='-w -s' -trimpath


FROM gcr.io/distroless/static
LABEL org.opencontainers.image.source="https://github.com/clevyr/docker-mmproxy"
COPY --from=build /app/go-mmproxy /
ENTRYPOINT ["/go-mmproxy"]
