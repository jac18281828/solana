# solana

TypeScript and Solana Container for Docker and VS Code

Includes
* Rust
* solana 

```
export PATH="/home/jac/.local/share/solana/install/active_release/bin:$PATH"
```

### Architecture
* linux/amd64 
* linux/arm64

Example Dockerfile - for use as builder

```
FROM jac18281828/solana:latest

COPY --chown=solana:solana . .

RUN rustup component add rustfmt
```

Also available from [GitHub GHCR](https://github.com/jac18281828/solana/pkgs/container/solana)
