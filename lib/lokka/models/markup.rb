# frozen_string_literal: true

module Markup
  class << self
    attr_accessor :engine_list

    def use_engine(name, text)
      return if text.nil?

      @engine_list.each do |engine|
        return engine[2].call(text).html_safe if engine[0] == name
      end
      text.html_safe
    end
  end

  @engine_list = [
    ['html', 'HTML', ->(text) { text }],
    ['kramdown', 'Markdown (Kramdown)',
     ->(text) do
       Kramdown::Document.new(text,
                              coderay_line_numbers: nil,
                              coderay_css: :class).to_html
     end],
    ['redcloth', 'Textile (Redcloth)',
     ->(text) { RedCloth.new(text).to_html }],
    ['redcarpet', 'Markdown (redcarpet)',
     ->(text) do
       Redcarpet::Markdown.new(
         Redcarpet::Render::HTML.new(with_toc_data: true),
         no_intra_emphasis: true,
         fenced_code_blocks: true,
         autolink: true,
         tables: true,
         superscript: true,
         space_after_headers: true,
         footnotes: true,
         strikethrough: true
       ).render(text)
     end]
  ]
end
