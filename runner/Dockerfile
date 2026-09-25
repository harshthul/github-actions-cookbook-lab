# Ch4 self-hosted runner in a container (ephemeral: one job, then it exits and is replaced).
FROM ubuntu:26.04

ARG RUNNER_VERSION=2.337.0
ARG TARGETARCH=amd64
ENV DEBIAN_FRONTEND=noninteractive

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq tar unzip sudo nodejs npm \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash runner

WORKDIR /home/runner/actions-runner
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo arm64 || echo x64) \
    && curl -fsSL -o runner.tgz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf runner.tgz && rm runner.tgz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /home/runner

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh
USER runner
ENTRYPOINT ["/home/runner/entrypoint.sh"]
