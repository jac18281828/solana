ARG VERSION=latest
FROM jac18281828/tsdev:${VERSION}

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
        make gcc-10 pkg-config build-essential libudev-dev libclang-dev libssl-dev && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

ARG RUST_HOME=/usr/local/rust
ENV RUSTUP_HOME=${RUST_HOME}
ENV CARGO_HOME=${RUST_HOME}
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y

WORKDIR /build

ENV PATH=/usr/local/rust/bin:${PATH}

# Solana
ARG SOLANA=1.14.7
ADD https://github.com/solana-labs/solana/archive/refs/tags/v${SOLANA}.tar.gz v${SOLANA}.tar.gz
RUN tar -zxvf v${SOLANA}.tar.gz
RUN ./solana-${SOLANA}/scripts/cargo-install-all.sh .
ENV PATH=$/build/bin:$PATH

USER jac
RUN /build/bin/solana-install init ${SOLANA}
RUN sudo rm -rf /build

ENV SOLANA=${SOLANA}
CMD echo "TypeScript Dev ${TYPESCRIPT_VERSION}; Solana ${SOLANA}"

