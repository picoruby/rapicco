module Rapicco
  module PDF
    class AnsiParser
      ANSI_CSI_PATTERN = /\e\[([0-9;]*)([A-Za-z])/
      ANSI_RESET = /\e\[0m/

      BLOCK_CHARS = {
        "\u2588" => :full,
        "\u2580" => :upper,
        "\u2584" => :lower,
        " " => :empty
      }

      COLOR_256_TO_RGB = {}

      def initialize(cols: 80, rows: 24)
        @cols = cols
        @rows = rows
        @screen = Array.new(rows) { Array.new(cols) { { char: ' ', fg: nil, bg: nil } } }
        @cursor_x = 0
        @cursor_y = 0
        @current_fg = nil
        @current_bg = nil
        setup_color_palette
      end

      attr_reader :screen, :cols, :rows

      def parse(text)
        reset_screen
        text = text.force_encoding('UTF-8') unless text.encoding == Encoding::UTF_8
        chars = text.chars
        i = 0
        while i < chars.length
          if chars[i] == "\e"
            i = parse_escape_sequence_from_chars(chars, i)
          else
            write_char(chars[i])
            i += 1
          end
        end
        self
      end

      def reset_screen
        @screen = Array.new(@rows) { Array.new(@cols) { { char: ' ', fg: nil, bg: nil } } }
        @cursor_x = 0
        @cursor_y = 0
        @current_fg = nil
        @current_bg = nil
      end

      private

      def parse_escape_sequence_from_chars(chars, start)
        if start + 1 < chars.length && chars[start + 1] == '['
          # Build string from chars for regex matching
          remaining = chars[start..-1].join
          if match = remaining.match(ANSI_CSI_PATTERN)
            params = match[1].split(';').map(&:to_i)
            command = match[2]
            handle_csi_command(command, params)
            return start + match[0].length
          end
        end
        start + 1
      end

      def handle_csi_command(command, params)
        case command
        when 'H', 'f'
          row = params[0] || 1
          col = params[1] || 1
          @cursor_y = [row - 1, 0].max
          @cursor_x = [col - 1, 0].max
        when 'A'
          @cursor_y = [@cursor_y - (params[0] || 1), 0].max
        when 'B'
          @cursor_y = [@cursor_y + (params[0] || 1), @rows - 1].min
        when 'C'
          @cursor_x = [@cursor_x + (params[0] || 1), @cols - 1].min
        when 'D'
          @cursor_x = [@cursor_x - (params[0] || 1), 0].max
        when 'E'
          @cursor_y = [@cursor_y + (params[0] || 1), @rows - 1].min
          @cursor_x = 0
        when 'F'
          @cursor_y = [@cursor_y - (params[0] || 1), 0].max
          @cursor_x = 0
        when 'J'
          clear_screen(params[0] || 0)
        when 'K'
          clear_line(params[0] || 0)
        when 'm'
          handle_sgr(params.empty? ? [0] : params)
        end
      end

      def handle_sgr(params)
        i = 0
        while i < params.length
          case params[i]
          when 0
            @current_fg = nil
            @current_bg = nil
          when 31
            @current_fg = [1.0, 0.0, 0.0]
          when 32
            @current_fg = [0.0, 1.0, 0.0]
          when 33
            @current_fg = [1.0, 1.0, 0.0]
          when 34
            @current_fg = [0.0, 0.0, 1.0]
          when 35
            @current_fg = [1.0, 0.0, 1.0]
          when 36
            @current_fg = [0.0, 1.0, 1.0]
          when 37
            @current_fg = [1.0, 1.0, 1.0]
          when 38
            if params[i + 1] == 5 && params[i + 2]
              @current_fg = color_256_to_rgb(params[i + 2])
              i += 2
            end
          when 48
            if params[i + 1] == 5 && params[i + 2]
              @current_bg = color_256_to_rgb(params[i + 2])
              i += 2
            end
          end
          i += 1
        end
      end

      def clear_screen(mode)
        case mode
        when 0
          (@cursor_y...@rows).each do |y|
            start_x = y == @cursor_y ? @cursor_x : 0
            (start_x...@cols).each do |x|
              @screen[y][x] = { char: ' ', fg: nil, bg: nil }
            end
          end
        when 1
          (0..@cursor_y).each do |y|
            end_x = y == @cursor_y ? @cursor_x : @cols - 1
            (0..end_x).each do |x|
              @screen[y][x] = { char: ' ', fg: nil, bg: nil }
            end
          end
        when 2
          @screen = Array.new(@rows) { Array.new(@cols) { { char: ' ', fg: nil, bg: nil } } }
        end
      end

      def clear_line(mode)
        case mode
        when 0
          (@cursor_x...@cols).each do |x|
            @screen[@cursor_y][x] = { char: ' ', fg: nil, bg: nil }
          end
        when 1
          (0..@cursor_x).each do |x|
            @screen[@cursor_y][x] = { char: ' ', fg: nil, bg: nil }
          end
        when 2
          (0...@cols).each do |x|
            @screen[@cursor_y][x] = { char: ' ', fg: nil, bg: nil }
          end
        end
      end

      def write_char(char)
        return if @cursor_y >= @rows
        if char == "\n"
          @cursor_y += 1
          @cursor_x = 0
        elsif char == "\r"
          @cursor_x = 0
        elsif char.ord >= 32
          if @cursor_x < @cols
            @screen[@cursor_y][@cursor_x] = {
              char: char,
              fg: @current_fg,
              bg: @current_bg
            }
            @cursor_x += 1
          end
        end
      end

      def setup_color_palette
        (0..255).each do |i|
          COLOR_256_TO_RGB[i] = xterm_256_to_rgb(i)
        end
      end

      def color_256_to_rgb(index)
        COLOR_256_TO_RGB[index] || [1.0, 1.0, 1.0]
      end

      def xterm_256_to_rgb(index)
        if index < 16
          basic_colors = [
            [0.0, 0.0, 0.0], [0.5, 0.0, 0.0], [0.0, 0.5, 0.0], [0.5, 0.5, 0.0],
            [0.0, 0.0, 0.5], [0.5, 0.0, 0.5], [0.0, 0.5, 0.5], [0.75, 0.75, 0.75],
            [0.5, 0.5, 0.5], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [1.0, 1.0, 0.0],
            [0.0, 0.0, 1.0], [1.0, 0.0, 1.0], [0.0, 1.0, 1.0], [1.0, 1.0, 1.0]
          ]
          basic_colors[index]
        elsif index < 232
          i = index - 16
          r = (i / 36) * 51
          g = ((i % 36) / 6) * 51
          b = (i % 6) * 51
          [r / 255.0, g / 255.0, b / 255.0]
        else
          gray = 8 + (index - 232) * 10
          [gray / 255.0, gray / 255.0, gray / 255.0]
        end
      end
    end
  end
end
