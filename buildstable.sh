#!/bin/bash
# Wrapper for backwards compatibility - delegates to build.sh --stable
exec "$(dirname "$0")/build.sh" --stable
