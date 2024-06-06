FROM node:16 as builder

WORKDIR /web
COPY ./VERSION .
COPY ./web .

# 构建 default 主题
WORKDIR /web/default
RUN npm install
RUN mkdir -p ../build/default && DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat /web/VERSION) npm run build && mv build ../build/default

# 构建 berry 主题
WORKDIR /web/berry
RUN npm install
RUN mkdir -p ../build/berry && DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat /web/VERSION) npm run build && mv build ../build/berry

# 构建 air 主题
WORKDIR /web/air
RUN npm install
RUN mkdir -p ../build/air && DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat /web/VERSION) npm run build && mv build ../build/air

FROM golang AS builder2

ENV GO111MODULE=on \
    CGO_ENABLED=1 \
    GOOS=linux

WORKDIR /build
ADD go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=builder /web/build ./web/build
RUN go build -ldflags "-s -w -X 'github.com/songquanpeng/one-api/common.Version=$(cat /build/VERSION)' -extldflags '-static'" -o one-api

FROM alpine

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && update-ca-certificates 2>/dev/null || true

COPY --from=builder2 /build/one-api /
EXPOSE 3000
WORKDIR /data
ENTRYPOINT ["/one-api"]
