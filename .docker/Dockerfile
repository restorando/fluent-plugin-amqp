FROM ruby:2.6-slim-buster

# arguments defined in docker-compose.yml
ARG user
ARG uid

RUN apt update
RUN apt install -y git rake build-essential
RUN gem install mocha fluent-plugin-amqp2

RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir /code
RUN chown -R $user:$user /code

CMD ["irb"]