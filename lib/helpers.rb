# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
require 'colorize'

module BuildHelpers

  def msg(message)
    puts "#{message}".yellow
  end

  def err(error)
    puts "[ERROR] %s".red % error
  end

  def rmdir(path)
    return if path.nil?
    if path.respond_to? :each
      path.each do |p|
        FileUtils.rmdir p
      end
    else
      FileUtils.rmdir path
    end
  end

  def mkdir(path)
    return if path.nil?
    if path.respond_to? :each
      path.each do |p|
        FileUtils.mkdir_p p
      end
    else
      FileUtils.mkdir_p path
    end
  end

  def architecture
    case lsb_release_tag
    when /ubuntu|debian/
      return `dpkg-architecture -qDEB_BUILD_ARCH`
    else
      err "Not sure how to determine arch for: #{lsb_release_tag}"
    end
  end

  def lsb_release_tag
    @lsb_release_tag ||= `lsb_release --id --release | cut -d: -f2 | tr A-Z a-z | xargs | tr ' ' '/'`
  end

  def find_gem_bin
    `gem env | sed -n '/^ *- EXECUTABLE DIRECTORY: */ { s/// ; p }'`
  end
end