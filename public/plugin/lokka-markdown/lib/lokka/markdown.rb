require 'kramdown'

module Lokka
  module Helpers
    def markdown(str=nil)
      Kramdown::Document.new(str).to_html
    end
  end
end
