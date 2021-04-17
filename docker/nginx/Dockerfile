FROM nginx:1.18-alpine
LABEL maintainer="hanadev <hanadev@gaogao.asia>"
SHELL ["/bin/ash", "-oeux", "pipefail", "-c"]

ENV TZ=UTC

RUN apk update && \
  apk add --update --no-cache --virtual=.build-dependencies g++

ENV PHP_HOST=127.0.0.1

# RUN apt-get update && apt install -y \
#   zlib1g-dev \
#   libssl-dev \
#   libreadline-dev \
#   libsqlite3-dev \
#   libbz2-dev \
#   libncurses5-dev \
#   libgdbm-dev \
#   liblzma-dev \
#   tk-dev zlibc \
#   libffi-dev \
#   zip \
#   unzip \
#   && apt-get clean \
#   && curl https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz | tar zx -C /usr/local/src/ \
#   && cd /usr/local/src/Python-3.7.5 \
#   && ./configure \
#   && make && make install \
#   && ln -s /usr/local/bin/python3 /usr/local/bin/python

# RUN curl https://s3.ap-southeast-1.amazonaws.com/amazon-ssm-ap-southeast-1/latest/debian_amd64/amazon-ssm-agent.deb -o /tmp/amazon-ssm-agent.deb \
#   && dpkg -i /tmp/amazon-ssm-agent.deb \
#   && cp /etc/amazon/ssm/seelog.xml.template /etc/amazon/ssm/seelog.xml

# nginx config file
COPY ./docker/nginx/default.conf.template /etc/nginx/conf.d/default.conf.template

COPY ./backend /var/www/app

WORKDIR /var/www/app

EXPOSE 80

CMD /bin/sh -c 'sed "s/\${PHP_HOST}/${PHP_HOST}/" /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g "daemon off;"'


