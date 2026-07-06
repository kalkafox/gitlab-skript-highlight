#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-gitlab}"

echo "Testing Rouge lexer registration in container: ${CONTAINER_NAME}"

docker exec -i "${CONTAINER_NAME}" bash -lc '/opt/gitlab/embedded/bin/ruby -e '\''
require "rouge"
require "rouge/lexers/skript"
lexer = Rouge::Lexer.find("skript")
abort "Skript lexer not found" unless lexer
puts "Found lexer: #{lexer.title}"
code = "command /spawn:\n    trigger:\n        send \"&aTeleported!\" to player\n"
html = Rouge.highlight(code, "skript", "html")
abort "Expected highlighted output" unless html.include?("highlight") || html.include?("<span")
puts html
'\'''

echo
echo "Optional Rails boot test:"
docker exec -i "${CONTAINER_NAME}" bash -lc 'gitlab-rails runner '\''require "rouge"; require "rouge/lexers/skript"; puts Rouge::Lexer.find("skript").title'\'''
