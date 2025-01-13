#!/bin/bash

# $ pip3 install mdformat
MDFORMAT="${HOME}/.local/bin/mdformat"

# $luarocks install --server=https://luarocks.org/dev luaformatter
LUAFORMAT="${HOME}/.luarocks/bin/lua-format"

[[ -x "${MDFORMAT}" ]] && "${MDFORMAT}" --wrap=80 *.md

[[ -x "${LUAFORMAT}" ]] && "${LUAFORMAT}" \
  --in-place \
  --column-limit=80 \
  --indent-width=4 \
  --continuation-indent-width=4 \
  --no-use-tab \
  --align-args \
  --align-parameter \
  --align-table-field \
  --double-quote-to-single-quote \
  --no-keep-simple-function-one-line \
  *.lua

