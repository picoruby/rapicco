require 'cairo'

module Rapicco
  module PDF
    class Renderer
      BLOCK_CHARS = {
        "\u2588" => :full,
        "\u2580" => :upper,
        "\u2584" => :lower,
        " " => :empty
      }

      def initialize(char_width: 10, char_height: 20)
        @char_width = char_width
        @char_height = char_height
      end

      def render(pages, output_path, parser_cols: 80, parser_rows: 24)
        width = parser_cols * @char_width
        height = parser_rows * @char_height

        Cairo::PDFSurface.new(output_path, width, height) do |surface|
          pages.each do |page_data|
            context = Cairo::Context.new(surface)
            render_page(page_data, context)
            context.show_page
          end
        end
      end

      private

      def render_page(screen, context)
        context.set_source_rgb(0, 0, 0)
        context.paint

        screen.each_with_index do |line, y|
          line.each_with_index do |cell, x|
            render_cell(cell, x, y, context)
          end
        end
      end

      def render_cell(cell, x, y, context)
        px = x * @char_width
        py = y * @char_height

        if cell[:bg]
          context.set_source_rgb(*cell[:bg])
          context.rectangle(px, py, @char_width, @char_height)
          context.fill
        end

        char_type = BLOCK_CHARS[cell[:char]]
        return unless char_type && cell[:fg]

        context.set_source_rgb(*cell[:fg])

        case char_type
        when :full
          context.rectangle(px, py, @char_width, @char_height)
          context.fill
        when :upper
          context.rectangle(px, py, @char_width, @char_height / 2.0)
          context.fill
        when :lower
          context.rectangle(px, py + @char_height / 2.0, @char_width, @char_height / 2.0)
          context.fill
        when :empty
        end
      end
    end
  end
end
