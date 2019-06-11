FROM ruby:2.6.3-slim

MAINTAINER Yann Hourdel "yann@hourdel.fr"

RUN apt-get update \
  && apt-get install -qq -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    curl \
    git-core \
    gnupg \
    libcurl4-openssl-dev \
    libpq-dev \
    netcat

ENV INSTALL_PATH /rails
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# Copy the Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the main application.
COPY . .

# Expose port 3000 to the Docker host, so we can access it
# from the outside.
EXPOSE 3000

# An entrypoint to run migrations and so on
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["bundle exec rails server -p 3000 -b 0.0.0.0"]
