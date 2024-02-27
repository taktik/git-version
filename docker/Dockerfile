FROM alpine:3.18

RUN apk add --no-cache git bash

COPY docker/entrypoint.sh /usr/local/bin/git-version
COPY shell/git-version.sh /usr/local/lib/

ENTRYPOINT ["git-version"]
