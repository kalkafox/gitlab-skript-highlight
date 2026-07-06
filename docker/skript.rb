# frozen_string_literal: true

module Rouge
  module Lexers
    class Skript < RegexLexer
      title "Skript"
      desc "Skript Minecraft server scripting language"
      tag "skript"
      aliases "sk"
      filenames "*.sk"
      mimetypes "text/x-skript"

      def self.detect?(text)
        text =~ /^\s*(on\s+\w+|command\s+\/|function\s+\w+\(|options:|variables:|trigger:)\b/i
      end

      state :root do
        rule %r/#.*?$/, Comment::Single
        rule %r/\s+/, Text::Whitespace

        rule %r/"/, Str::Double, :dq
        rule %r/'/, Str::Single, :sq

        # Minecraft legacy colors, section-sign colors, and common MiniMessage-ish tags.
        rule %r/(?<!\w)(&[0-9a-fk-orA-FK-OR]|§[0-9a-fk-orA-FK-OR]|<\/?[a-z_]+>|<#[0-9a-fA-F]{6}>)/, Str::Escape

        # Skript variables:
        # {foo}, {_local}, {data::%uuid of player%}
        rule %r/\{[_A-Za-z0-9:.\-% ]+\}/, Name::Variable

        # command /spawn:
        rule %r/\b(command)(\s+)(\/[A-Za-z0-9:_-]+)/i do
          groups Keyword::Declaration, Text::Whitespace, Name::Function
        end

        # function doThing(player: player):
        rule %r/\b(function)(\s+)([A-Za-z_][\w]*)/i do
          groups Keyword::Declaration, Text::Whitespace, Name::Function
        end

        # Section headers.
        rule %r/^\s*(trigger|options|variables|aliases):\s*$/i, Keyword::Namespace
        rule %r/^\s*(on\s+(?:join|quit|death|respawn|chat|damage|load|unload|click|right click|left click|break|place|command|inventory click|script load|script unload).*):\s*$/i, Keyword::Namespace

        # Control flow / structure.
        rule %r/\b(if|else if|else|loop|while|return|stop|continue|cancel|wait|chance of|try|catch)\b/i, Keyword

        # Common effects.
        rule %r/\b(set|add|remove|delete|clear|reset|send|broadcast|message|teleport|give|take|drop|kill|damage|heal|play|execute|make|open|close|kick|ban|unban|spawn)\b/i, Name::Builtin

        # Common Skript expressions.
        rule %r/\b(player|uuid|victim|attacker|event-[a-z-]+|event|world|location|block|entity|item|arg-\d+|argument-\d+|loop-[a-z-]+)\b/i, Name::Builtin

        rule %r/\b(true|false|yes|no|none|null)\b/i, Keyword::Constant

        # Operators / condition words.
        rule %r/\b(and|or|not|is|isn't|is not|contains|doesn't contain|does not contain|where|in|of|from|to|with|without|as|by)\b/i, Operator::Word
        rule %r/[=+\-*\/%<>!]=?|:/, Operator

        rule %r/\b\d+(?:\.\d+)?\b/, Num
        rule %r/[,\(\)\[\]]/, Punctuation

        rule %r/[A-Za-z_][\w-]*/, Text
        rule %r/./, Text
      end

      state :dq do
        rule %r/\\[\\"]/, Str::Escape
        rule %r/%[^%\n]+%/, Str::Interpol
        rule %r/(?<!\w)(&[0-9a-fk-orA-FK-OR]|§[0-9a-fk-orA-FK-OR]|<\/?[a-z_]+>|<#[0-9a-fA-F]{6}>)/, Str::Escape
        rule %r/"/, Str::Double, :pop!
        rule %r/[^\\%"&§<]+/, Str::Double
        rule %r/./, Str::Double
      end

      state :sq do
        rule %r/\\[\\']/, Str::Escape
        rule %r/%[^%\n]+%/, Str::Interpol
        rule %r/(?<!\w)(&[0-9a-fk-orA-FK-OR]|§[0-9a-fk-orA-FK-OR]|<\/?[a-z_]+>|<#[0-9a-fA-F]{6}>)/, Str::Escape
        rule %r/'/, Str::Single, :pop!
        rule %r/[^\\%'&§<]+/, Str::Single
        rule %r/./, Str::Single
      end
    end
  end
end
