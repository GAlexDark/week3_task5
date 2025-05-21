ARG BASE_IMAGE
ARG GO_TAG
ARG VERSION
ARG APP_REPO

FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE}:${GO_TAG} AS builder
WORKDIR /src
COPY src .
COPY Makefile .
COPY .env .
RUN make go_build

FROM scratch
WORKDIR /
COPY --from=builder /src/app .
ENTRYPOINT [ "/app" ]
