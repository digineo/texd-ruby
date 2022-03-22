# frozen_string_literal: true

module Texd
  module Helpers
    ESCAPE_RE = /([{}_$&%#])|([\\^~|<>])/.freeze
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
      # proper hyphenation
      [/(\w)-(\w)/, '\1"=\2'],
    ].freeze

    # Escapes the given text, making it safe for use in TeX documents.
    def escape(text, line_break = "\\\\\\", typographic: true)
      text = +text.to_s # text might be nil or a frozen string
      text.tap do |str|
        str.gsub!(ESCAPE_RE) do |m|
          if Regexp.last_match(1)
            "\\#{m}"
          else
            "\\text#{ESC_MAP[m]}{}"
          end
        end

        if typographic
          TYPOGRAPHIC_REPLACEMENTS.each do |re, replacement|
            str.gsub!(re, replacement)
          end
        end

        str.gsub!(/\r?\n/, line_break)
      end.freeze
    end
  end
end
