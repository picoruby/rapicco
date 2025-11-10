require 'shellwords'

module Rapicco
  class Presenter
    def initialize(slide_file, options = {})
      @slide_file = slide_file
      @rapicco_command = options[:rapicco_command] || detect_picoruby_command(options)
    end

    def run
      # Disable terminal echo during presentation
      system("stty -echo -icanon")

      begin
        system("#{@rapicco_command} #{Shellwords.shellescape(@slide_file)}")
      ensure
        # Restore terminal settings
        system("stty echo icanon")
        # Show cursor (CSI ? 25 h)
        print "\e[?25h"
        # Exit alternate screen buffer (CSI ? 1049 l)
        print "\e[?1049l"
        $stdout.flush
      end
    end

    private

    def detect_picoruby_command(options)
      unless ENV['PICORUBY_PATH']
        raise <<~ERROR
          PICORUBY_PATH environment variable is not set.

          Please set it to the path of your picoruby executable:
            export PICORUBY_PATH=/path/to/picoruby

          Or use the --rapicco-command option:
            rapicco --rapicco-command "/path/to/picoruby -e ..." <slide.md>

          To install PicoRuby, see: https://github.com/picoruby/picoruby
        ERROR
      end

      unless File.executable?(ENV['PICORUBY_PATH'])
        raise "PICORUBY_PATH is set to '#{ENV['PICORUBY_PATH']}' but it is not executable"
      end

      picoruby = ENV['PICORUBY_PATH']
      "#{picoruby} -e \"require 'rapicco'; Rapicco.new(ARGV[0]).run\""
    end
  end
end
