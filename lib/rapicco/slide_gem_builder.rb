require 'fileutils'
require 'rubygems/package'

module Rapicco
  class SlideGemBuilder
    def initialize(config)
      @config = config
    end

    def build
      validate_config

      FileUtils.mkdir_p('pkg')

      spec = build_gemspec
      gem_file = File.join('pkg', "#{spec.full_name}.gem")

      if File.exist?(gem_file)
        FileUtils.rm(gem_file)
      end

      Gem::Package.build(spec)
      FileUtils.mv("#{spec.full_name}.gem", gem_file)

      gem_file
    end

    private

    def validate_config
      errors = []

      # Required fields
      errors << "config.yml: 'id' is required" if @config['id'].nil? || @config['id'].empty?
      errors << "config.yml: 'base_name' is required" if @config['base_name'].nil? || @config['base_name'].empty?
      errors << "config.yml: 'version' is required" if @config['version'].nil? || @config['version'].empty?

      # Licenses
      if @config['licenses'].nil? || @config['licenses'].empty?
        errors << "config.yml: 'licenses' must have at least one license"
      end

      # Author fields
      if @config['author'].nil?
        errors << "config.yml: 'author' section is required"
      else
        errors << "config.yml: 'author.name' is required" if @config['author']['name'].nil? || @config['author']['name'].empty?
        errors << "config.yml: 'author.email' is required" if @config['author']['email'].nil? || @config['author']['email'].empty?
        errors << "config.yml: 'author.rubygems_user' is required" if @config['author']['rubygems_user'].nil? || @config['author']['rubygems_user'].empty?
      end

      unless errors.empty?
        raise <<~ERROR
          Configuration validation failed:

          #{errors.map { |e| "  - #{e}" }.join("\n")}

          Please edit config.yml and fill in all required fields.
        ERROR
      end
    end

    def build_gemspec
      config = @config
      slide_file = find_slide_file
      pdf_file = "pdf/#{config['id']}-#{config['base_name']}.pdf"

      Gem::Specification.new do |spec|
        spec.name = "rabbit-slide-#{config['author']['rubygems_user']}-#{config['id']}"
        spec.version = config['version']
        spec.authors = [config['author']['name']]
        spec.email = [config['author']['email']]

        spec.summary = "Rapicco slide: #{config['id']}"
        spec.description = read_description
        spec.homepage = "https://slide.rabbit-shocker.org/authors/#{config['author']['rubygems_user']}/#{config['id']}/"
        spec.license = config['licenses'].first

        spec.metadata = {
          "rapicco.slide.id" => config['id'],
          "rapicco.slide.base_name" => config['base_name'],
          "rapicco.slide.tags" => config['tags'].join(',')
        }

        spec.files = [
          slide_file,
          pdf_file,
          'config.yml',
          'Rakefile',
          'README.md'
        ].select { |f| File.exist?(f) }

        # Slide gems don't have Ruby code to require, but RubyGems requires at least one path
        spec.require_paths = ["."]
      end
    end

    def find_slide_file
      if File.exist?('slide.md')
        'slide.md'
      else
        Dir.glob('*.md').reject { |f| f == 'README.md' }.first
      end
    end

    def read_description
      return @config['id'] unless File.exist?('README.md')

      readme = File.read('README.md')
      # Extract first paragraph after title
      lines = readme.lines
      description_lines = []
      found_title = false

      lines.each do |line|
        if line.start_with?('#')
          found_title = true
          next
        end

        next if line.strip.empty? && !found_title

        if found_title
          break if line.strip.empty? && !description_lines.empty?
          description_lines << line.strip
        end
      end

      description_lines.join(' ').strip[0..200]
    end
  end
end
