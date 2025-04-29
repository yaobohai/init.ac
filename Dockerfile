FROM ruby:3.3-slim

EXPOSE 4000

WORKDIR /app
COPY . /app

RUN bundle install
CMD ["bundle", "exec", "jekyll", "server"]