FROM ruby:3.3-alpine

RUN apk update && apk add --update --no-cache \
  build-base \
  git \
  libxml2 \
  libxslt \
  libxml2-dev \
  libxslt-dev \
  libc-dev \
  libgcrypt-dev \
  bash \
  curl

WORKDIR /lib
RUN gem install bundler

COPY . .
RUN bundle install
