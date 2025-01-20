FROM golang:1.23.5 AS build-vkv

# renovate: datasource=github-releases depName=FalcoSuessgott/vkv
ARG VKV_VERSION=v0.8.4
RUN CGO_ENABLED=0 go install github.com/FalcoSuessgott/vkv@${VKV_VERSION}

FROM golang:1.23.5 AS build-restic

# renovate: datasource=github-releases depName=restic/restic
ARG RESTIC_VERSION=v0.17.3
RUN apt update && \
    apt -y install git && \
    git clone https://github.com/restic/restic /restic && \
    git -C /restic checkout ${RESTIC_VERSION}

WORKDIR /restic
RUN CGO_ENABLED=0 go run helpers/build-release-binaries/main.go -p linux/amd64 --skip-compress

FROM alpine:3.21.2

COPY --from=build-vkv /go/bin/vkv /usr/bin/vkv
COPY --from=build-restic /output/restic_linux_amd64 /usr/bin/restic

RUN apk add --no-cache bash curl jq

COPY backup-vault /usr/bin/

ENTRYPOINT ["/usr/bin/vkv"]
