FROM ruby:3.3-slim

WORKDIR /app
COPY . /app

EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "server"]