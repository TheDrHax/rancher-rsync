FROM alpine:latest

MAINTAINER Dmitry Karikh <the.dr.hax@gmail.com>

RUN apk --no-cache add rsync curl bash rsnapshot \
 && mkdir /backup

WORKDIR /backup

COPY run.sh /run.sh

ENTRYPOINT /run.sh
