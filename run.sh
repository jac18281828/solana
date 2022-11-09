#!/usr/bin/env bash

VERSION=$(git rev-parse HEAD | cut -c 1-10)
PROJECT=jac18281828/$(basename ${PWD})

docker build . -t ${PROJECT}:${VERSION} && \
	docker run -e FALSE=false --rm -i -t ${PROJECT}:${VERSION}
