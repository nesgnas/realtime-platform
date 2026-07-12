FROM docker.io/hexpm/elixir:1.17.3-erlang-27.1.2-alpine-3.20.3 AS build
RUN apk add --no-cache build-base git
WORKDIR /app
ENV MIX_ENV=prod
RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs ./
COPY config config
RUN mix deps.get --only prod && mix deps.compile
COPY lib lib
COPY priv priv
COPY rel rel
RUN mix compile && mix release

FROM docker.io/library/alpine:3.20 AS app
RUN apk add --no-cache libstdc++ ncurses-libs openssl wget && addgroup -S relay && adduser -S relay -G relay
WORKDIR /app
COPY --from=build --chown=relay:relay /app/_build/prod/rel/relay ./
RUN mkdir -p /app/lib/relay-0.1.0/uploads && chown -R relay:relay /app/lib/relay-0.1.0/uploads && chmod +x /app/bin/server
USER relay
ENV HOME=/app PHX_SERVER=true
EXPOSE 4000
CMD ["/app/bin/server"]
