# Stage 1: Build yamlfmt
FROM golang:1 AS go-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

# Install yamlfmt
WORKDIR /yamlfmt
RUN go install github.com/google/yamlfmt/cmd/yamlfmt@latest && \
    strip $(which yamlfmt) && \
    yamlfmt --version

FROM rust:1-slim AS builder
ARG TARGETARCH
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential \
    linux-headers-${TARGETARCH} libc6-dev \ 
    openssl libssl-dev pkg-config llvm libclang-dev \
    protobuf-compiler libudev-dev \
    ca-certificates apt-transport-https \
    python3 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash solana
RUN usermod -a -G sudo solana
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV USER=solana
USER solana

WORKDIR /build
RUN chown -R ${USER}:${USER} /build

ENV PATH=${PATH}:/home/solana/.cargo/bin
RUN echo ${PATH} && cargo --version

# Solana
ARG SOLANA=1.18.25
ADD --chown=${USER}:${USER} https://github.com/solana-labs/solana/archive/refs/tags/v${SOLANA}.tar.gz v${SOLANA}.tar.gz
RUN tar -zxvf v${SOLANA}.tar.gz
RUN ./solana-${SOLANA}/scripts/cargo-install-all.sh /home/solana/.local/share/solana/install/releases/${SOLANA}
RUN for file in /home/solana/.local/share/solana/install/releases/${SOLANA}/bin/*; do strip ${file}; done
ENV PATH=$/build/bin:$PATH

ENV SOLANA=${SOLANA}
CMD echo "Solana in /home/solana/.local/share/solana/install/releases/${SOLANA}"

FROM jac18281828/tsdev:latest

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
    ca-certificates apt-transport-https \
    sudo ripgrep procps \
    python3 python3-pip \
    git curl protobuf-compiler \
    pkg-config openssl libssl-dev && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN echo "building platform $(uname -m)"

RUN useradd --create-home -s /bin/bash solana
RUN usermod -a -G sudo solana
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV USER=solana
ARG SOLANA=1.18.25
COPY --chown=${USER}:${USER} --from=go-builder /go/bin/yamlfmt /go/bin/yamlfmt
COPY --chown=${USER}:${USER} --from=builder /usr/local/cargo /usr/local/cargo
COPY --chown=${USER}:${USER} --from=builder /home/solana/.local/share/solana/install/releases/${SOLANA} /home/solana/.local/share/solana/install/releases/${SOLANA}
ENV PATH=${PATH}:/usr/local/cargo/bin:/go/bin:/home/solana/.local/share/solana/install/releases/${SOLANA}

ENV USER=solana
USER solana

LABEL \
    org.label-schema.name="solana" \
    org.label-schema.description="Solana Development Container" \
    org.label-schema.url="https://github.com/jac18281828/solana" \
    org.label-schema.vcs-url="git@github.com:jac18281828/solana.git" \
    org.label-schema.vendor="jac18281828" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0" \
    org.opencontainers.image.description="Solana Development Container for Visual Studio Code"
