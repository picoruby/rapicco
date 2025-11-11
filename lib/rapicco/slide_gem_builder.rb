require 'fileutils'
require 'rubygems/package'
require_relative 'constants'

module Rapicco
  class SlideGemBuilder
    def self.validate_config(config)
      errors = []

      # Required fields
      errors << "config.yaml: 'id' is required" if config['id'].nil? || config['id'].empty?
      errors << "config.yaml: 'base_name' is required" if config['base_name'].nil? || config['base_name'].empty?
      errors << "config.yaml: 'version' is required" if config['version'].nil? || config['version'].empty?
      errors << "config.yaml: 'description' is required" if config['description'].nil? || config['description'].empty?
      errors << "config.yaml: 'presentation_date' is required" if config['presentation_date'].nil? || config['presentation_date'].empty?

      # Licenses
      if config['licenses'].nil? || config['licenses'].empty?
        errors << "config.yaml: 'licenses' must have at least one license"
      end

      # Author fields
      if config['author'].nil?
        errors << "config.yaml: 'author' section is required"
      else
        errors << "config.yaml: 'author.name' is required" if config['author']['name'].nil? || config['author']['name'].empty?
        errors << "config.yaml: 'author.rubygems_user' is required" if config['author']['rubygems_user'].nil? || config['author']['rubygems_user'].empty?
      end

      unless errors.empty?
        raise <<~ERROR
          Configuration validation failed:

          #{errors.map { |e| "  - #{e}" }.join("\n")}

          Please edit config.yaml and fill in all required fields.
        ERROR
      end
    end

    # raise error if README.md is missing or malformed
    # checklist:
    #   - README.md exists
    #   - README.md has a title (first line starts with '# ')
    #     - The title is not identical to Rapicco::PDF_DEFAULT_TITLE
    def self.validate_readme
      unless File.file?('README.md')
        raise "README.md is missing. Please provide a README.md file."
      end
      File.open('README.md', 'r') do |file|
        lines = file.readlines.map(&:chomp)
        if lines.empty?
          raise "README.md is empty. Please provide a valid README.md file."
        end
        title_line = lines.find { |line| line.start_with?('# ') }
        if title_line.nil?
          raise "README.md is missing a title. The first line should start with '# '."
        end
        title = title_line.sub('# ', '').strip
        if title.empty?
          raise "README.md has an empty title. Please provide a valid title."
        end
        if title == Rapicco::PDF_DEFAULT_TITLE
          raise "README.md title is the default placeholder. Please provide a meaningful title."
        end
      end
    end

    def initialize(config)
      @config = config
    end

    def build
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

    def build_gemspec
      config = @config
      slide_file = find_slide_file
      pdf_file = "pdf/#{config['id']}-#{config['base_name']}.pdf"

      Gem::Specification.new do |spec|
        spec.required_ruby_version = Rapicco::REQUIRED_RUBY_VERSION

        spec.name = "rabbit-slide-#{config['author']['rubygems_user']}-#{config['id']}"
        spec.version = config['version']
        spec.authors = [config['author']['name']]
        spec.email = [config['author']['email']]

        spec.summary = "Rapicco slide: #{config['id']}"
        spec.description = "#{config['description']}"
        spec.homepage = "https://slide.rabbit-shocker.org/authors/#{config['author']['rubygems_user']}/#{config['id']}/"
        spec.licenses = config['licenses']

        spec.metadata = {
          "rapicco.slide.id" => config['id'],
          "rapicco.slide.base_name" => config['base_name'],
          "rapicco.slide.tags" => config['tags'].join(',')
        }

        spec.files = [
          slide_file,
          pdf_file,
          'config.yaml',
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

  end
end
