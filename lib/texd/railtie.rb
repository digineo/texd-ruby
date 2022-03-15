# frozen_string_literal: true

module Texd
  class Railtie < ::Rails::Railtie
    initializer "initialize texd template handler" do
      Mime::Type.register "text/x-tex", :tex, ["text/plain"], ["tex"]
    end
  end
end
