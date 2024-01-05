# Use a specific version of Debian as the base image
FROM debian:buster-slim

# Define the desired Ruby version as an environment variable for easy modification
ENV RUBY_VERSION=3.2.2

# Install necessary tools and dependencies for Ruby, Google Chrome, and ChromeDriver
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    wget \
    curl \
    unzip \
    build-essential \
    autoconf \
    bison \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    libdb-dev \
    libglib2.0-0 \
    git \
 && rm -rf /var/lib/apt/lists/* \
 && git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
 && cd ~/.rbenv && src/configure && make -C src \
 && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
 && /root/.rbenv/bin/rbenv install $RUBY_VERSION \
 && /root/.rbenv/bin/rbenv global $RUBY_VERSION \
 && /root/.rbenv/bin/rbenv rehash

# Set up PATH environment variable to include rbenv and shims
ENV PATH /root/.rbenv/bin:/root/.rbenv/shims:$PATH

# Update RubyGems and install Bundler
RUN gem update --system \
    && gem install bundler

# Directly download and install Google Chrome and Chrome Driver
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && dpkg -i google-chrome-stable_current_amd64.deb || apt-get install -f -y \
    && rm google-chrome-stable_current_amd64.deb \
 && CHROMEDRIVER_VERSION=$(curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE) \
 && wget -q --continue -P /tmp "http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip" \
 && unzip /tmp/chromedriver_linux64.zip -d /usr/local/bin/ \
 && rm /tmp/chromedriver_linux64.zip \
 && chmod ugo+rx /usr/local/bin/chromedriver

# Set up the working directory
WORKDIR /usr/src/app

# Copying Gemfile first to leverage Docker cache
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle install

# Copy the project files into the container
COPY . .

# The default command to run when starting the container
CMD ["ruby", "app/solve_captcha.rb"]
