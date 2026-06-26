FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl ca-certificates sudo && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash tester && \
    echo "tester ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/tester && \
    chmod 0440 /etc/sudoers.d/tester

USER tester
WORKDIR /home/tester/pacto-dev-env

COPY --chown=tester:tester setup-ubuntu-lts.sh .
COPY --chown=tester:tester README.md .
COPY --chown=tester:tester docker ./docker

CMD ["bash", "./setup-ubuntu-lts.sh"]
