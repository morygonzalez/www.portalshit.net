FROM ruby:2.4.1-alpine

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile.docker /app/Gemfile
COPY Gemfile.lock /app/

ENV BUNDLE_PATH /bundle
ENV BUNDLE_DISABLE_SHARED_GEMS 0

RUN gem install bundler -v 1.15.4
RUN apk add --no-cache bash nodejs mysql-client sqlite mysql-dev sqlite-dev
RUN apk add --no-cache alpine-sdk \
      --virtual .build_deps libxml2-dev libxslt-dev zlib zlib-dev tzdata \
      && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
      && bundle install -j4 --without postgresql \
      && apk del alpine-sdk .build_deps \
      && rm -rf /tmp/* /var/cache/apk/*

COPY . /app
COPY Gemfile.docker /app/Gemfile

CMD /bin/sh