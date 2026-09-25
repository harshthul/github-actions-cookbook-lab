# Ch7 "Build and publish a container"
FROM node:25-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY server.js ./
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} PORT=8080
EXPOSE 8080
USER node
HEALTHCHECK --interval=10s --timeout=3s CMD ["wget", "-qO-", "http://127.0.0.1:8080/healthz"]
CMD ["node", "server.js"]
