module RubyGemsBundlerInstaller
  # Iterate through executables and generate wrapper for each one,
  # extract of rubygems code
  def self.bundler_generate_bin(inst)
    return if inst.spec.executables.nil? or inst.spec.executables.empty?
    bindir = inst.bin_dir ? inst.bin_dir : Gem.bindir(inst.gem_home)
    inst.spec.executables.each do |filename|
      filename.untaint
      bin_script_path = File.join bindir, inst.formatted_program_filename(filename)
      FileUtils.rm_f bin_script_path
      File.open bin_script_path, 'wb', 0755 do |file|
        file.print bundler_app_script_text(inst, filename)
      end
      inst.say bin_script_path if Gem.configuration.really_verbose
    end
  end

  # Return the text for an application file.
  def self.bundler_app_script_text(inst, bin_file_name)
    <<-TEXT
#{inst.shebang bin_file_name}
#
# This file was generated by RubyGems extended wrapper.
#
# The application '#{inst.spec.name}' is installed as part of a gem, and
# this file is here to facilitate running it.
#

require 'rubygems'

use_bundler = (ENV['USE_BUNDLER']||'').downcase

try_bundler = %w{try check possibly}.include? use_bundler
force_bundler = %w{force require yes true on}.include? use_bundler
version = "#{Gem::Requirement.default}"

if try_bundler || force_bundler
  begin
    require 'bundler/setup'
  rescue LoadError
    raise '\n\nPlease install bundler first.\n\n' if force_bundler
    try_bundler = false
  end
end

unless try_bundler
  if ARGV.first =~ /^_(.*)_$/ and Gem::Version.correct? $1 then
    version = $1
    ARGV.shift
  end
  gem '#{inst.spec.name}', version
end

load Gem.bin_path('#{inst.spec.name}', '#{bin_file_name}', version)
TEXT
  end

end

module Gem
  post_install do |inst|
    RubyGemsBundlerInstaller.bundler_generate_bin(inst)
  end
end