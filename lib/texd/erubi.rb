# frozen_string_literal: true

require "erubi"
require "action_view"

module Texd
  class Erubi < ActionView::Template::Handlers::ERB::Erubi
    # This overrides ActionView::Template::Handlers::ERB::Erubi#evalute
    # with the following changes:
    #
    # 1. Texd helpers are included into the compiler context.
    # 2. It uses a plain String instead of ActionView::OutputBuffer.new
    #    as output buffer. This skips HTML escaping.
    def evaluate(action_view_erb_handler_context)
      src  = @src
      view = Class.new(ActionView::Base) {
        include action_view_erb_handler_context._routes.url_helpers
        include Texd.helpers # (1)

        # rubocop:disable Style/DocumentDynamicEvalDefinition, Style/EvalWithLocation, Layout/LineLength
        class_eval("define_method(:_template) { |local_assigns, output_buffer| #{src} }", defined?(@filename) ? @filename : "(texd-erubi)", 0)
        # rubocop:enable Style/DocumentDynamicEvalDefinition, Style/EvalWithLocation, Layout/LineLength
      }.empty
      view._run(:_template, nil, {}, "") # (2)
    end
  end
end
