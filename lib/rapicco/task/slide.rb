require 'rake'
require 'rake/tasklib'
require 'yaml'
require 'fileutils'
require_relative '../slide_gem_builder'

module Rapicco
  module Task
    class Slide < Rake::TaskLib
      def initialize
        @config = load_config
        define_tasks
      end

      private

      def load_config
        unless File.exist?('config.yaml')
          raise "config.yaml not found. Please create it first."
        end
        YAML.load_file('config.yaml')
      end

      def define_tasks
        desc "Run presentation"
        task :run do
          slide_file = find_slide_file
          sh "rapicco #{slide_file}"
        end

        desc "Generate PDF"
        task :pdf do
          slide_file = find_slide_file
          pdf_dir = 'pdf'
          FileUtils.mkdir_p(pdf_dir)

          pdf_name = "#{@config['id']}-#{@config['base_name']}.pdf"
          pdf_path = File.join(pdf_dir, pdf_name)

          # Check if PDF is up to date
          if File.exist?(pdf_path)
            pdf_mtime = File.mtime(pdf_path)
            slide_mtime = File.mtime(slide_file)
            config_mtime = File.mtime('config.yaml')

            if slide_mtime < pdf_mtime && config_mtime < pdf_mtime
              puts "PDF is up to date: #{pdf_path}"
              next
            end
          end

          cols = @config.dig('pdf', 'cols') || 350
          rows = @config.dig('pdf', 'rows') || 196

          sh "rapicco -p -o #{pdf_path} #{slide_file} --cols #{cols} --rows #{rows}"
          puts "PDF created: #{pdf_path}"
        end

        task :validate_config do
          Rapicco::SlideGemBuilder.validate_config(@config)
        end

        task :validate_readme do
          Rapicco::SlideGemBuilder.validate_readme
        end

        desc "Create gem package"
        task gem: [:validate_config, :validate_readme, :pdf] do
          builder = Rapicco::SlideGemBuilder.new(@config)
          gem_file = builder.build
          puts "Gem created: #{gem_file}"
        end

        desc "Publish gem to RubyGems.org"
        task publish: :gem do
          gem_file = gem_filename
          sh "gem push #{gem_file}"
        end
      end

      def find_slide_file
        # Look for .md files, prefer slide.md if it exists
        if File.exist?('slide.md')
          'slide.md'
        else
          md_files = Dir.glob('*.md').reject { |f| f == 'README.md' }
          if md_files.empty?
            raise "No slide file found. Please create a .md file."
          end
          md_files.first
        end
      end

      def gem_filename
        author_name = @config['author']['rubygems_user'].gsub(/[^a-z0-9\-_]/i, '-')
        "pkg/rabbit-slide-#{author_name}-#{@config['id']}-#{@config['version']}.gem"
      end
    end
  end
end

Rapicco::Task::Slide.new
