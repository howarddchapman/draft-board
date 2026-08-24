FROM elixir:1.20-alpine AS build

RUN apk add --no-cache build-base git

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY . .
RUN mix compile

FROM elixir:1.20-alpine

RUN apk add --no-cache build-base

WORKDIR /app

ENV MIX_ENV=prod

COPY --from=build /app ./
COPY --from=build /root/.mix ./root/.mix

RUN mix local.hex --force && mix local.rebar --force

EXPOSE 8080

CMD ["sh", "-c", "mix ecto.migrate && mix run --no-halt"]