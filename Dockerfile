FROM ruby:3.1.1-alpine3.15

ENV APP_ENV production

ENV USER=msir
ENV UID=10001
ENV GUID=10001
RUN adduser \
	--disabled-password \
	--gecos "" \
	--shell "/sbin/nologin" \
	--uid ${UID} ${USER}

RUN apk update
RUN apk add --no-cache --virtual build-dependencies \
	build-base

USER ${UID}:${GUID}
WORKDIR /app

COPY --chown=${UID}:${GUID} Gemfile Gemfile.lock /app/
RUN bundle install --jobs 8 --retry 3

COPY . /app

CMD bundle exec ruby app.rb
