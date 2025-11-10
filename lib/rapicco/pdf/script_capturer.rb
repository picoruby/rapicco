require 'tempfile'
require 'pty'
require 'expect'

module Rapicco
  module PDF
    class ScriptCapturer
      def initialize(rapicco_command, slide_file, cols: 80, rows: 24)
        @rapicco_command = rapicco_command
        @slide_file = slide_file
        @cols = cols
        @rows = rows
        @pages = []
      end

      attr_reader :pages

      def capture_all_pages(max_pages: 100)
        ENV['COLUMNS'] = @cols.to_s
        ENV['LINES'] = @rows.to_s

        full_command = "#{@rapicco_command} #{@slide_file}"
        PTY.spawn(full_command) do |r, w, pid|
          w.winsize = [@rows, @cols]

          puts "Waiting for initial render..."
          sleep 3

          first_page = read_all_available(r)
          if first_page && !first_page.empty?
            @pages << first_page
            puts "Captured page 1 (#{first_page.length} bytes)"
          end

          (max_pages - 1).times do
            puts "Sending 'l' key..."
            w.print 'l'
            w.flush

            sleep 2

            page_data = read_all_available(r)
            if !page_data || page_data.empty?
              puts "No new data, stopping"
              break
            end

            combined = @pages.last + page_data
            if combined == @pages.last
              puts "No changes detected, stopping"
              break
            end

            @pages << combined
            puts "Captured page #{@pages.length} (total #{combined.length} bytes)"
          end

          w.print "\x03"
        rescue Errno::EIO, PTY::ChildExited
          puts "Process ended"
        end

        @pages
      end

      private

      def read_all_available(io, timeout: 1.0)
        result = ""
        deadline = Time.now + timeout

        loop do
          remaining = deadline - Time.now
          break if remaining <= 0

          ready = IO.select([io], nil, nil, [0.1, remaining].min)
          break unless ready

          begin
            chunk = io.read_nonblock(4096)
            result << chunk
          rescue IO::WaitReadable
            break
          rescue EOFError, Errno::EIO
            break
          end
        end

        result
      end
    end
  end
end
