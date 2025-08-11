FROM ruby:3.2-alpine

# Set working directory inside the container
WORKDIR /app

# Install dependencies for pg gem
RUN apk add --no-cache build-base postgresql-dev

# Copy Gemfile and Gemfile.lock first for caching
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Command to run the Ruby application
CMD ["ruby", "app.rb"]

