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
echo "Testing Linguist language registration in container: ${CONTAINER_NAME}"

docker exec -i "${CONTAINER_NAME}" bash -lc '/opt/gitlab/embedded/bin/ruby -e '\''
require "linguist"
require "tempfile"

language = Linguist::Language.find_by_name("Skript")
abort "Skript Linguist language not found" unless language

extension_languages = Linguist::Language.find_by_extension("example.sk")
abort "Skript .sk extension not found" unless extension_languages.include?(language)

file = Tempfile.new(["example", ".sk"])
begin
  file.write("command /spawn:\n    trigger:\n        send \"&aTeleported!\" to player\n")
  file.close

  detected = Linguist.detect(Linguist::FileBlob.new(file.path))
  abort "Expected Skript, got #{detected&.name || "nil"}" unless detected == language
ensure
  file.unlink
end

puts "Found Linguist language: #{language.name}"
'\'''

echo
echo "Optional Rails boot test:"
docker exec -i "${CONTAINER_NAME}" bash -lc 'gitlab-rails runner '\''require "rouge"; require "rouge/lexers/skript"; puts Rouge::Lexer.find("skript").title'\'''
