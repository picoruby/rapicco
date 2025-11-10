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
        PTY.spawn("#{@rapicco_command} #{@slide_file}") do |stdout, stdin, pid|
          stdin.winsize = [@rows, @cols]

          puts "Waiting for Rapicco to start and render..."
          sleep 3

          current_page = capture_current_screen(stdout, timeout: 2.0)
          if current_page
            @pages << current_page
            puts "Captured page 1 (#{current_page.length} bytes)"
          end

          consecutive_skips = 0
          (max_pages - 1).times do |i|
            puts "Sending 'l' for next page..."
            stdin.write('l')
            stdin.flush

            sleep 1

            page = capture_current_screen(stdout, timeout: 2.0)
            unless page
              puts "No output received, stopping"
              break
            end

            # Skip pages that are too small (likely just sprite animations)
            if page.bytesize < 2000
              puts "Skipping small page (#{page.bytesize} bytes, likely sprite animation only)"
              consecutive_skips += 1
              if consecutive_skips >= 3
                puts "Three consecutive skips, assuming no more content pages"
                break
              end
              next
            end

            consecutive_skips = 0

            if page == @pages.last
              puts "Page content identical to previous, stopping"
              break
            end

            @pages << page
            puts "Captured page #{@pages.length} (#{page.length} bytes)"
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

      def capture_current_screen(stdout, timeout: 2.0)
        output = ""

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

        output.empty? ? nil : output
      end
    end
  end
end
