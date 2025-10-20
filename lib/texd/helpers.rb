# frozen_string_literal: true

module Texd
  module Helpers
    ESCAPE_RE = /([{}_$&%#])|([\\^~|<>])/
    ESC_MAP   = {
      "\\" => "backslash",
      "^"  => "asciicircum",
      "~"  => "asciitilde",
      "|"  => "bar",
      "<"  => "less",
      ">"  => "greater",
    }.freeze

    TYPOGRAPHIC_REPLACEMENTS = [
      # nested quotes
      [/(^|\W)"'\b/, '\1\\glqq{}\\glq{}'],
      [/\b'"(\W|$)/, '\\grq{}\\grqq{}\1'],
      # double quotes
      [/(^|\W)"\b/, '\1\\glqq{}'],
      [/\b"(\W|$)/, '\\grqq{}\1'],
      # single quotes
      [/(^|\W)'\b/, '\1\\glq{}'],
      [/\b'(\W|$)/, '\\grq{}\1'],
    ].freeze

    HYPHENATION_REPLACEMENTS = [
      # proper hyphenation
      [/(\w)-(\w)/, '\1"=\2'],
    ].freeze

    # Escapes the given text, making it safe for use in TeX documents.
    def escape(text, line_break = "\\\\\\", typographic: true, hyphenation: typographic)
      return "" if text.blank?

      text.to_s.dup.tap do |str|
        str.gsub!(ESCAPE_RE) do |m|
          if Regexp.last_match(1)
            "\\#{m}"
          else
            "\\text#{ESC_MAP[m]}{}"
          end
        end

        {
          TYPOGRAPHIC_REPLACEMENTS => typographic,
          HYPHENATION_REPLACEMENTS => hyphenation,
        }.each do |replacements, active|
          next unless active

          replacements.each do |re, replacement|
            str.gsub!(re, replacement)
          end
        end

        str.gsub!(/\r?\n/, line_break)
      end.freeze
    end
  end
end
