#!/usr/bin/env bash
set -euo pipefail

# This is only for quick testing. Prefer the Dockerfile/custom-image path for production,
# because direct edits inside a running container disappear when the container is replaced.

CONTAINER_NAME="${CONTAINER_NAME:-gitlab}"

docker cp docker/skript.rb "${CONTAINER_NAME}:/tmp/skript.rb"
docker cp docker/zz_skript_rouge.rb "${CONTAINER_NAME}:/tmp/zz_skript_rouge.rb"
docker cp docker/patch_linguist_skript.rb "${CONTAINER_NAME}:/tmp/patch_linguist_skript.rb"

docker exec -i "${CONTAINER_NAME}" bash -lc '
set -eux
ROUGE_LEXER_DIR="$(/opt/gitlab/embedded/bin/ruby -e '\''require "rubygems"; print File.join(Gem::Specification.find_by_name("rouge").full_gem_path, "lib/rouge/lexers")'\'')"
cp /tmp/skript.rb "$ROUGE_LEXER_DIR/skript.rb"
cp /tmp/zz_skript_rouge.rb /opt/gitlab/embedded/service/gitlab-rails/config/initializers/zz_skript_rouge.rb
/opt/gitlab/embedded/bin/ruby /tmp/patch_linguist_skript.rb
/opt/gitlab/embedded/bin/ruby -e '\''require "rouge"; require "rouge/lexers/skript"; puts Rouge::Lexer.find("skript").title'\''
/opt/gitlab/embedded/bin/ruby -e '\''require "linguist"; language = Linguist::Language.find_by_name("Skript"); abort "Skript language did not register" unless language; abort "Skript .sk extension did not register" unless Linguist::Language.find_by_extension("example.sk").include?(language); puts language.name'\''
gitlab-ctl restart puma sidekiq
'
