# Stage 1: Build and install dependencies
FROM ruby:3.1.0

# Set environment variables
ENV LANG C.UTF-8
ENV BUNDLER_VERSION=2.3.3
ENV APP_HOME /aviary
# Set user and group IDs as build arguments
ARG USER_ID=${USER_ID:-1000}
ARG GROUP_ID=${GROUP_ID:-1000}


# Create a non-root user and group with specified IDs
RUN groupadd -g $USER_ID appgroup && \
    useradd -u $GROUP_ID -g appgroup -s /bin/bash -m appuser

# Set bundler jobs to the number of available CPU cores
RUN bundle config set jobs "$(nproc)"

# Install system dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    libxml2-dev libxslt1-dev \
    nodejs \
    netcat \
    p7zip-full \
    ffmpeg \
    imagemagick \
    cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

RUN chown -R root:root $APP_HOME

# Set the PATH environment variable
ENV PATH $APP_HOME/bin:$PATH

# Install bundler
RUN gem install bundler -v $BUNDLER_VERSION

COPY Gemfile Gemfile.lock ./

RUN bundle check || bundle install

COPY . ./

CMD ["./bin/docker/prepare-to-start-rails", "rails", "server", "-p", "3000", "-b", "0.0.0.0"]
