# frozen_string_literal: true

# Load the Skript Rouge lexer during GitLab Rails boot.
# The Dockerfile places the lexer inside the bundled Rouge gem's lexer path.
begin
  require "rouge/lexers/skript"
rescue LoadError => e
  Rails.logger.warn("Failed to load Skript Rouge lexer: #{e.message}") if defined?(Rails)
end
