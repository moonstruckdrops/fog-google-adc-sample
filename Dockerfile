FROM ruby:3.0.1-slim-buster

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
            build-essential \
            git \
            curl \
            unzip \
            bash \
            vim \
            libpq-dev \
            apt-transport-https \
            ca-certificates \
            gnupg
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove && \
    apt-get clean

RUN mkdir /app
WORKDIR /app

COPY Gemfile .
COPY Gemfile.lock .
COPY .ruby-version .
COPY config.ru .
COPY docker-entrypoint.sh .

RUN gem install bundler \
  && bundle config set without 'development test' \
  && bundle install --jobs="$(nproc)" --gemfile=./Gemfile \
  && rm /usr/local/bundle/cache/*.gem

RUN chmod +x docker-entrypoint.sh
EXPOSE 8080
CMD ["bash", "docker-entrypoint.sh"]
