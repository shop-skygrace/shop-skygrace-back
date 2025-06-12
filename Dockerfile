FROM node:22-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
COPY . /app
WORKDIR /app

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

FROM prod-deps AS build
RUN pnpm medusa telemetry --disable
ENV NODE_ENV=production
RUN pnpm run build

FROM node:22-alpine AS production
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
WORKDIR /app/
COPY --from=prod-deps /app/node_modules /app/node_modules
COPY --from=build /app/.medusa/server /app

ENV NODE_ENV=develop
ENV MEDUSA_DISABLE_TELEMETRY=true

RUN pnpm medusa telemetry --disable

EXPOSE 9000

ENTRYPOINT [ "pnpm", "run", "start" ]