#!/usr/bin/env bash
cd "$(dirname "$0")"
PORT=${PORT:-4729} exec node server.js