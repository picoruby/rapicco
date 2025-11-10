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
        unless File.exist?('config.yml')
          raise "config.yml not found. Please create it first."
        end
        YAML.load_file('config.yml')
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

          sh "rapicco -p -o #{pdf_path} #{slide_file}"
          puts "PDF created: #{pdf_path}"
        end

        desc "Create gem package"
        task gem: :pdf do
          builder = Rapicco::SlideGemBuilder.new(@config)
          gem_file = builder.build
          puts "Gem created: #{gem_file}"
        end

        desc "Publish gem to RubyGems.org"
        task publish: :gem do
          puts "Publishing gem is currently disabled."
          #gem_file = gem_filename
          #sh "gem push #{gem_file}"
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
