FROM node:14.2-alpine as node
FROM nginx:1.18-alpine
LABEL maintainer="ucan-lab <yes@u-can.pro>"
SHELL ["/bin/ash", "-oeux", "pipefail", "-c"]

ENV TZ=UTC

RUN apk update && \
  apk add --update --no-cache --virtual=.build-dependencies g++

ENV PHP_HOST=127.0.0.1

# node command
COPY --from=node /usr/local/bin /usr/local/bin
# npm command
COPY --from=node /usr/local/lib /usr/local/lib
# yarn command
COPY --from=node /opt /opt
# nginx config file
COPY ./docker/nginx/default.conf /etc/nginx/conf.d/default.conf.template
COPY ./docker/nginx/gzip.conf /etc/nginx/conf.d/gzip.conf


COPY ./backend /work/backend

WORKDIR /work/backend

EXPOSE 80

CMD /bin/sh -c 'sed "s/\${PHP_HOST}/${PHP_HOST}/" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"'



