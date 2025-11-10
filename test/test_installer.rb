require_relative 'test_helper'
require 'rapicco/installer'
require 'tmpdir'
require 'fileutils'

class TestInstaller < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @test_dir = File.join(@tmpdir, 'test-presentation')
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def test_install_creates_directory
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    assert File.directory?(@test_dir)
  end

  def test_install_creates_gemfile
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    gemfile_path = File.join(@test_dir, 'Gemfile')
    assert File.exist?(gemfile_path)
    content = File.read(gemfile_path)
    assert_match(/gem 'rapicco'/, content)
  end

  def test_install_creates_rakefile
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    rakefile_path = File.join(@test_dir, 'Rakefile')
    assert File.exist?(rakefile_path)
    content = File.read(rakefile_path)
    assert_match(/require 'rapicco\/task\/slide'/, content)
  end

  def test_install_creates_slide_md
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    slide_path = File.join(@test_dir, 'slide.md')
    assert File.exist?(slide_path)
  end

  def test_install_creates_config_yml
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    config_path = File.join(@test_dir, 'config.yml')
    assert File.exist?(config_path)
  end

  def test_install_creates_pdf_directory
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    pdf_dir = File.join(@test_dir, 'pdf')
    assert File.directory?(pdf_dir)
  end

  def test_install_creates_gitignore
    installer = Rapicco::Installer.new(@test_dir)
    installer.install
    gitignore_path = File.join(@test_dir, '.gitignore')
    assert File.exist?(gitignore_path)
    content = File.read(gitignore_path)
    assert_match(/pdf\//, content)
  end

  def test_install_in_current_directory
    Dir.chdir(@tmpdir) do
      installer = Rapicco::Installer.new('.')
      installer.install
      assert File.exist?('Gemfile')
      assert File.exist?('Rakefile')
      assert File.exist?('slide.md')
    end
  end

  def test_install_raises_error_if_directory_exists
    FileUtils.mkdir_p(@test_dir)
    installer = Rapicco::Installer.new(@test_dir)
    assert_raise(RuntimeError) do
      installer.install
    end
  end
end
