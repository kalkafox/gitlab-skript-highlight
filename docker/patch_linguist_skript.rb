# frozen_string_literal: true

require "json"
require "rubygems"
require "yaml"

LANGUAGE_NAME = "Skript"
LANGUAGE_ENTRY = {
  "type" => "programming",
  "color" => "#ff5a9e",
  "extensions" => [".sk"],
  "tm_scope" => "none",
  "ace_mode" => "text"
}.freeze

def linguist_path(*parts)
  File.join(Gem::Specification.find_by_name("github-linguist").full_gem_path, "lib", "linguist", *parts)
end

def next_private_language_id(languages)
  used_ids = languages.values.filter_map { |entry| entry["language_id"]&.to_i }
  id = 9_700_000
  id += 1 while used_ids.include?(id)
  id
end

def patched_languages(languages)
  entry = (languages[LANGUAGE_NAME] || {}).merge(LANGUAGE_ENTRY)
  entry["language_id"] ||= next_private_language_id(languages)
  languages.merge(LANGUAGE_NAME => entry)
end

languages_yml = linguist_path("languages.yml")
languages = patched_languages(YAML.load_file(languages_yml))
File.write(languages_yml, YAML.dump(languages))

languages_json = linguist_path("languages.json")
if File.exist?(languages_json)
  languages = patched_languages(JSON.parse(File.read(languages_json)))
  File.write(languages_json, JSON.pretty_generate(languages))
end
