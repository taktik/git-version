FROM alpine:3.18

RUN apk add --no-cache git bash

COPY docker/entrypoint.sh shell/git-version.sh /

ENTRYPOINT ["/entrypoint.sh"]
