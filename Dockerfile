FROM debian:stable-slim AS go-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential coreutils \
    openssl libssl-dev pkg-config \
    ca-certificates apt-transport-https \
    python3 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

## Go Lang
ARG GO_VERSION=1.23.2
ADD https://go.dev/dl/go${GO_VERSION}.linux-$TARGETARCH.tar.gz /go/go${GO_VERSION}.linux-$TARGETARCH.tar.gz
RUN echo 'SHA256 of this go source package...'
RUN cat /go/go${GO_VERSION}.linux-$TARGETARCH.tar.gz | sha256sum 
RUN tar -C /usr/local -xzf /go/go${GO_VERSION}.linux-$TARGETARCH.tar.gz

WORKDIR /yamlfmt
ENV GOBIN=/usr/local/go/bin
ENV PATH=$PATH:${GOBIN}
RUN go install github.com/google/yamlfmt/cmd/yamlfmt@latest
RUN ls -lR /usr/local/go/bin/yamlfmt && strip /usr/local/go/bin/yamlfmt && ls -lR /usr/local/go/bin/yamlfmt
RUN yamlfmt --version

FROM debian:stable-slim AS builder
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

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y

WORKDIR /build
RUN chown -R ${USER}:${USER} /build

ENV PATH=${PATH}:/home/solana/.cargo/bin
RUN echo ${PATH} && cargo --version

# Solana
ARG SOLANA=1.18.25
ADD --chown=${USER}:${USER} https://github.com/solana-labs/solana/archive/refs/tags/v${SOLANA}.tar.gz v${SOLANA}.tar.gz
RUN tar -zxvf v${SOLANA}.tar.gz
RUN ./solana-${SOLANA}/scripts/cargo-install-all.sh /home/solana/.local/share/solana/install/releases/${SOLANA}
ENV PATH=$/build/bin:$PATH

USER solana
#RUN /build/bin/solana-install init ${SOLANA}
#RUN sudo rm -rf /build

ENV SOLANA=${SOLANA}
CMD echo "Solana in /home/solana/.local/share/solana/install/releases/${SOLANA}"

FROM jac18281828/tsdev:latest

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt update && \
  apt install -y -q --no-install-recommends \
    ca-certificates apt-transport-https \
    sudo ripgrep procps build-essential \
    python3 python3-pip clang \
    git valgrind curl protobuf-compiler \
    pkg-config openssl libssl-dev && \
  apt clean && \
  rm -rf /var/lib/apt/lists/*

RUN echo "building platform $(uname -m)"

RUN useradd --create-home -s /bin/bash solana
RUN usermod -a -G sudo solana
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV USER=solana
ARG SOLANA=1.18.25
COPY --chown=${USER}:${USER} --from=go-builder /usr/local/go/bin/yamlfmt /usr/local/go/bin/yamlfmt
COPY --chown=${USER}:${USER} --from=builder /home/solana/.cargo /home/solana/.cargo
COPY --chown=${USER}:${USER} --from=builder /home/solana/.rustup /home/solana/.rustup
COPY --chown=${USER}:${USER} --from=builder /home/solana/.local/share/solana/install/releases/${SOLANA} /home/solana/.local/share/solana/install/releases/${SOLANA}
ENV PATH=${PATH}:/home/solana/.cargo/bin:/usr/local/go/bin:/home/solana/.local/share/solana/install/releases/${SOLANA}

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
