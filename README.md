# solana

TypeScript and Solana Container for Docker and VS Code

Includes
* Rust
* solana 

```
export PATH="/home/jac/.local/share/solana/install/active_release/bin:$PATH"
```

Example Dockerfile - for use as builder

```
ARG VERSION=latest
FROM jac18281828/solana:${VERSION} as builder
```

