FROM ruby:3

RUN apt-get update -qq && apt-get install -y build-essential libsqlite3-dev vim
ENV EDITOR vim

RUN mkdir /app
WORKDIR /app

RUN gem update --system

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle update --bundler 
RUN bundle install

CMD bash