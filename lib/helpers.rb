# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
require 'colorize'
require 'open3'

module BuildHelpers

  def msg(message)
    puts "#{message}".yellow
  end

  def err(error)
    puts "[ERROR] %s".red % error
  end

  # In a ruby script we can't just change current path
  def cd(path)
    Dir.chdir(path)
  end

  def exec(cmd)
    begin
      msg "exec: '#{cmd}'"
      stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
      out = stdout.gets(nil)
      exit_code = wait_thr.value

      unless exit_code.success?
        err "command '#{cmd}' failed. exiting."
        err out
        err stderr.gets
        exit
      end
    rescue Exception => e
      err e.message
      err stderr.gets
      exit 1
    end
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
    msg "creating path: '%s'" % path.to_s
    return if path.nil?
    if path.respond_to? :each
      path.each do |p|
        FileUtils.mkdir_p p
      end
    else
      FileUtils.mkdir_p path
    end
  end

  def dir_exists?(directory)
    File.directory?(directory)
  end

  def cp(src, dst)
    msg "copying %s" % src
    exec "cp #{src} #{dst}"
  end

  def cptree(src, dst)
    msg "copying %s" % src
    FileUtils.copy_entry src, dst
  end

  def pwd
    `pwd`
  end

  def architecture
    case linux
    when /ubuntu|debian/
      return `dpkg-architecture -qDEB_BUILD_ARCH`
    else
      err "Not sure how to determine arch for: #{lsb_release_tag}"
    end
  end

  def linux
    @lsb_release_tag ||= `lsb_release --id --release | cut -d: -f2 | tr A-Z a-z | xargs | tr ' ' '/'`
  end

  def gem_bin
    `gem env | sed -n '/^ *- EXECUTABLE DIRECTORY: */ { s/// ; p }'`
  end

  def local_user
    `whoami`.strip
  end
end
