FROM ruby:3.4.5-slim

ENV INSTALL_PATH /rails
ENV DOCKERIZE_VERSION v0.7.0
ENV RAILS_MAX_THREADS 5
ENV RUBY_YJIT_ENABLE 1
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# Install dependencies
RUN apt-get update
RUN apt-get install -qq -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    curl \
    git-core \
    gnupg \
    libcurl4-openssl-dev \
    libpq-dev \
    libxrender1 \
    netcat-traditional \
    imagemagick \
    libpq-dev \
    file \
    git \
    shared-mime-info \
    python3
    
RUN rm -rf /usr/local/bundle/gems/bundler-* \
    && rm -rf /usr/local/bundle/specifications/bundler-* \
    && gem install bundler -v '2.7.2' --no-document \
    && bundle config --global disable_platform_warnings true

RUN apt-get update \
    && apt-get install -y wget \
    && wget -O - https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar xzf - -C /usr/local/bin \
    && apt-get autoremove -yqq --purge wget && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash \
    && mkdir -p /etc/apt/keyrings \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y nodejs yarn

# Copy the package.json as well as the yarn.lock and install
# the node modules. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
RUN yarn config set registry https://registry.npmjs.org/
COPY package.json yarn.lock ./
RUN yarn install --network-timeout 100000

# Temporary trick to fasten rebuilds when changing dependencies
COPY docker/rails/Gemfile docker/rails/Gemfile.lock ./
RUN bundle install

# Now copy the real Gemfile as well as the Gemfile.lock and install
# the RubyGems. This is a separate step so the dependencies
# will be cached unless changes to one of those two files
# are made.
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Allow wkhtmltopdf-binary to expand
RUN chmod o+w $(bundle show wkhtmltopdf-binary)/bin

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
