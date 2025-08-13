# Dockerfile.dev
FROM ruby:3.4.2-slim
WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl watchman libjemalloc2 libyaml-dev libvips sqlite3 build-essential libpq-dev git && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN gem install bundler

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x ./bin/*

EXPOSE 80

# Start Server
CMD ["./bin/rails","server","-b", "0.0.0.0"]
