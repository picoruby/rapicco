require 'pty'
require 'io/console'
require 'timeout'

module Rapicco
  module PDF
    class PageCapturer
      def initialize(rapicco_command, slide_file, cols: 80, rows: 24)
        @rapicco_command = rapicco_command
        @slide_file = slide_file
        @cols = cols
        @rows = rows
        @pages = []
      end

      attr_reader :pages

      def capture_all_pages(max_pages: 100)
        expected_pages = count_slides(@slide_file)
        puts "Detected #{expected_pages} slides in presentation"

        PTY.spawn("#{@rapicco_command} #{@slide_file}") do |stdout, stdin, pid|
          stdin.winsize = [@rows, @cols]

          puts "Waiting for Rapicco to start and render..."
          sleep 3

          current_page = capture_current_screen(stdout, timeout: 2.0)
          if current_page
            @pages << current_page
            puts "Captured page 1/#{expected_pages} (#{current_page.length} bytes)"
          end

          (expected_pages - 1).times do |i|
            puts "Sending 'l' for next page..."
            stdin.write('l')
            stdin.flush

            sleep 1

            page = capture_current_screen(stdout, timeout: 2.0)
            unless page
              puts "No output received, stopping"
              break
            end

            @pages << page
            puts "Captured page #{@pages.length}/#{expected_pages} (#{page.length} bytes)"
          end

          stdin.write("\x03")
        rescue Errno::EIO => e
          puts "PTY error: #{e.message}"
        ensure
          Process.kill('TERM', pid) rescue nil
          Process.wait(pid) rescue nil
        end

        @pages
      end

      private

      def count_slides(slide_file)
        return 1 unless File.exist?(slide_file)

        content = File.read(slide_file, encoding: 'UTF-8')
        slide_count = content.lines.count { |line| line =~ /\A# / }

        [slide_count, 1].max
      end

      def capture_current_screen(stdout, timeout: 2.0)
        output = String.new(encoding: Encoding::BINARY)

        begin
          Timeout.timeout(timeout) do
            loop do
              output << stdout.read_nonblock(10000)
            end
          end
        rescue Timeout::Error
        rescue IO::WaitReadable
        rescue EOFError, Errno::EIO
          return nil
        end

        return nil if output.empty?
        output.force_encoding(Encoding::UTF_8)

        # Extract only the last frame to avoid animation artifacts
        # Split by cursor home sequences which indicate a new frame
        frames = output.split(/(?=\e\[H|\e\[1;1H)/)

        frames.length > 1 ? frames.last : output
      end
    end
  end
end
