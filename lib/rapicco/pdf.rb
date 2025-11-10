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
        picoruby_paths = [
          "/home/hasumi/work/R2P2/lib/picoruby/bin/picoruby",
          "bin/picoruby"
        ]

        picoruby = picoruby_paths.find { |path| File.executable?(path) }
        unless picoruby
          raise "picoruby executable not found. Please install PicoRuby or specify --rapicco-command"
        end

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

