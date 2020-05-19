FROM golang:1.14 as build

ARG VERSION
ARG GIT_COMMIT
ARG PLATFORM="x86_64"
ARG GOOS=linux

RUN mkdir /oscar
WORKDIR /oscar

COPY go.mod .
COPY go.sum .
COPY main.go .
COPY pkg pkg

RUN GOOS=${GOOS} CGO_ENABLED=0 go build --ldflags "-s -w \
-X \"github.com/grycap/oscar/pkg/version.Version=${VERSION}\" \
-X \"github.com/grycap/oscar/pkg/version.GitCommit=${GIT_COMMIT}\" \
-X \"github.com/grycap/oscar/pkg/version.Platform=${PLATFORM}\"" \
-a -installsuffix cgo -o oscar .


FROM alpine:3.11

LABEL org.label-schema.license="Apache 2.0" \
    org.label-schema.vcs-url="https://github.com/grycap/oscar" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.name="grycap/oscar" \
    org.label-schema.vendor="grycap" \
    org.label-schema.docker.schema-version="1.0"

RUN addgroup -S app \
    && adduser -S -g app app \
    && apk add --no-cache ca-certificates

WORKDIR /home/app

EXPOSE 8080

COPY --from=build /oscar/oscar .

RUN chown -R app:app ./

USER app

CMD ["./oscar"]