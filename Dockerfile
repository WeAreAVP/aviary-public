FROM ruby:2.6.3

RUN gem install bundler -v 2.1.4

RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential

RUN apt-get install -y default-libmysqlclient-dev

RUN apt-get install -y libxml2-dev libxslt1-dev

RUN apt-get install -y nodejs

RUN apt-get install -y netcat

RUN apt-get install -y p7zip-full

RUN apt-get install -y ffmpeg

RUN apt-get install -y imagemagick

RUN apt-get install -y cron

ENV APP_HOME /aviary

RUN mkdir $APP_HOME

WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/

RUN bundle install

ADD . $APP_HOME

CMD ["docker/startup.sh"]