require 'fileutils'
require 'yaml'
require_relative 'constants'

module Rapicco
  class Installer
    def initialize(dir_name, options = {})
      @dir_name = dir_name
      @options = options
    end

    def install
      if @dir_name == '.'
        # Install in current directory
        target_dir = Dir.pwd
        dir_display = 'current directory'
      else
        # Create new directory
        if File.exist?(@dir_name)
          raise "Directory '#{@dir_name}' already exists"
        end
        FileUtils.mkdir_p(@dir_name)
        target_dir = @dir_name
        dir_display = "'#{@dir_name}'"
      end

      FileUtils.mkdir_p(File.join(target_dir, 'pdf'))

      create_gemfile(target_dir)
      create_rakefile(target_dir)
      create_slide(target_dir)
      create_config(target_dir)
      create_readme(target_dir)
      create_gitignore(target_dir)

      puts "Created slide template in #{dir_display}"
      puts ""
      puts "Next steps:"
      unless @dir_name == '.'
        puts "  cd #{@dir_name}"
      end
      puts "  bundle install"
      puts "  bundle exec rake run    # Run presentation"
      puts "  bundle exec rake pdf    # Generate PDF"
      puts "  bundle exec rake gem    # Create gem package"
    end

    private

    def create_gemfile(target_dir)
      content = <<~GEMFILE
        source 'https://rubygems.org'

        gem 'rapicco'
      GEMFILE

      File.write(File.join(target_dir, 'Gemfile'), content)
    end

    def create_rakefile(target_dir)
      content = <<~RAKEFILE
        require 'rapicco/task/slide'
      RAKEFILE

      File.write(File.join(target_dir, 'Rakefile'), content)
    end

    def create_slide(target_dir)
      content = <<~SLIDE
        ---
        duration: 300
        sprite: hasumikin
        title_font: shinonome_go16
        font: shinonome_go12
        bold_color: red
        align: center
        line_margin: 3
        code_indent: 2
        ---

        # #{Rapicco::PDF_DEFAULT_TITLE}
        {align=center, scale=2}

        #{Rapicco::PDF_DEFAULT_DESCRIPTION}

        # Introduction

        - Point 1
        - Point 2
        - Point 3

        # Conclusion

        Thank you!
      SLIDE

      File.write(File.join(target_dir, 'slide.md'), content)
    end

    def create_config(target_dir)
      config = {
        'id' => nil,
        'base_name' => nil,
        'description' => nil,
        'presentation_date' => nil,
        'tags' => [],
        'version' => nil,
        'licenses' => [],
        'author' => {
          'name' => nil,
          'email' => nil,
          'rubygems_user' => nil
        },
        'pdf' => {
          'cols' => 350,
          'rows' => 196
        }
      }

      File.write(File.join(target_dir, 'config.yaml'), YAML.dump(config))
    end

    def create_readme(target_dir)
      content = <<~README
        # Slide Title

        Your slide description here.

        ## Authors

        Your Name

        ## License
      README

      File.write(File.join(target_dir, 'README.md'), content)
    end

    def create_gitignore(target_dir)
      content = <<~GITIGNORE
        pdf/
        pkg/
        .DS_Store
      GITIGNORE

      File.write(File.join(target_dir, '.gitignore'), content)
    end
  end
end
