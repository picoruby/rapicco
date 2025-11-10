require_relative 'pdf/ansi_parser'
require_relative 'pdf/page_capturer'
require_relative 'pdf/renderer'

module Rapicco
  module PDF
    class Converter
      def initialize(slide_file, output_pdf, options = {})
        @slide_file = slide_file
        @output_pdf = output_pdf
        @cols = options[:cols] || 500
        @rows = options[:rows] || 140
        @char_width = options[:char_width] || 5
        @char_height = options[:char_height] || 10
        @rapicco_command = options[:rapicco_command] || detect_picoruby_command
      end

      private

      def detect_picoruby_command
        unless ENV['PICORUBY_PATH']
          raise <<~ERROR
            PICORUBY_PATH environment variable is not set.

            Please set it to the path of your picoruby executable:
              export PICORUBY_PATH=/path/to/picoruby

            Or use the --rapicco-command option:
              rapicco --rapicco-command "/path/to/picoruby -e ..." <slide.md> <output.pdf>

            To install PicoRuby, see: https://github.com/picoruby/picoruby
          ERROR
        end

        unless File.executable?(ENV['PICORUBY_PATH'])
          raise "PICORUBY_PATH is set to '#{ENV['PICORUBY_PATH']}' but it is not executable"
        end

        picoruby = ENV['PICORUBY_PATH']
        "#{picoruby} -e \"require 'rapicco'; Rapicco.new(ARGV[0], cols: #{@cols}, rows: #{@rows}).run\""
      end

      public

      def convert
        puts "Capturing pages from Rapicco presentation via PTY..."
        capturer = PageCapturer.new(@rapicco_command, @slide_file, cols: @cols, rows: @rows)
        raw_pages = capturer.capture_all_pages

        if raw_pages.empty?
          raise "No pages captured. Check if Rapicco is working correctly."
        end

        puts "Captured #{raw_pages.length} raw pages"

        puts "Parsing ANSI escape sequences..."
        parsed_pages = raw_pages.map do |raw_page|
          parser = AnsiParser.new(cols: @cols, rows: @rows)
          parser.parse(raw_page)
          parser.screen
        end

        puts "Rendering PDF..."
        renderer = Renderer.new(char_width: @char_width, char_height: @char_height)
        renderer.render(parsed_pages, @output_pdf, parser_cols: @cols, parser_rows: @rows)

        puts "PDF created: #{@output_pdf}"
      end
    end
  end
end

