FROM elixir:1.20-alpine

RUN apk add --no-cache build-base git

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only prod

COPY . .

RUN mix compile

ENV PHX_SERVER=true
ENV MIX_ENV=prod

CMD ["mix", "run", "--no-halt"]