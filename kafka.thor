#!/bin/ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'thor'
require './lib/helpers'


# Thor task for building Kafka package
class Kafka < Thor

  include BuildHelpers

  desc "build", "builds Kafka debian package"
  method_option :maintainer, :type => :string, :aliases => "-m"
  method_option :vendor, :type => :string
  method_option :version, :type => :string, :aliases => "-v", :required => true
  method_option :release, :type => :string, :aliases => "-r", :required => true
  method_option :url, :type => :string, :default => ''
  method_option :git, :type => :string, :default => 'https://git-wip-us.apache.org/repos/asf/kafka.git'
  method_option :branch, :type => :string, :default => '0.8'

  def build
    variables(options)
    cleanup(@workdir)
    prepare
    if @url == nil || @url.empty?
      clone(options[:git])
    else
      checkout(@url)
    end
    copy_config
    make_pkg
    finish
  end

  private

  def variables(opts)
    @src_dir = File.expand_path('./src', File.dirname(__FILE__))
    @workdir = File.expand_path('./build', File.dirname(__FILE__))
    @confdir = File.expand_path('./conf', File.dirname(__FILE__))
    @pwd = File.dirname(__FILE__)
    @url = opts[:url]
    if opts.key?('vendor')
      vendor = opts[:vendor]
    else
      vendor = local_user
    end

    if opts.key?('maintainer')
      maintainer = opts[:maintainer]
    else
      maintainer = local_user
    end
    @branch = opts[:branch]
    @deb = {
      name: 'kafka',
      version: opts[:version],
      description: 'Apache Kafka is a distributed publish-subscribe messaging system.',
      url: 'https://kafka.apache.org/',
      arch: 'all',
      vendor: vendor,
      category: 'misc',
      license: 'Apache Software License 2.0',
      maintainer: maintainer,
      user: 'kafka',
      group: 'kafka',
      release: opts[:release],
    }
  end

  def cleanup(workdir)
    msg 'cleaning old package...'
    unless Dir.glob('kafka*.deb').empty?
      exec 'rm kafka*.deb'
    end
    rmdir(workdir)
  end

  def prepare()
    mkdir(@workdir)
    mkdir(@src_dir)
  end

  def checkout(url)
    msg 'downloading %s' % url
    tar_file = url.split('/').last
    msg "file: %s" % tar_file
    unless File.exists?(tar_file)
      exec "wget #{url}"
    end
    `tar xzf #{tar_file} -C #{@src_dir}`
    @src_dir << '/' << tar_file[0...tar_file.rindex('.')]
    puts "src dir: #{@src_dir}"
  end

  def clone(url)
    clone_cmd = 'git clone %s' % url
    repo_dir = "#{@pwd}/kafka"
    if File.directory?(repo_dir)
      cd repo_dir
      exec "cd #{repo_dir} && git pull"
    else
      msg 'cloning repo %s' % url
      exec "#{clone_cmd}"
      cd repo_dir
    end
    curr_branch = `git rev-parse --abbrev-ref HEAD`.strip!
    msg "current branch '%s', req '%s'" % [ curr_branch, @branch ]
    if curr_branch != @branch
      exec "git checkout -b #{@branch} remotes/origin/#{@branch}"
    end
  end

  # Copy configuration files to package root
  def copy_config
    with_deb_dir do
      mkdir [ 'etc/init.d', 'etc/kafka', 'usr/lib', 'var/log/kafka',
        'etc/security/limits.d', 'etc/default', 'etc/logrotate.d' ]
    end
    cp_conf "default", "etc/default/kafka"
    cp_conf "init.debian", "etc/init.d/kafka"
    cp_conf "kafka-nofiles.conf", "etc/security/limits.d/kafka-nofiles.conf"
    cp_conf 'log4j.properties',  'etc/kafka'
    cp_conf 'logrotate', 'etc/logrotate.d/kafka'

    cp_src 'config/server.properties', 'etc/kafka'
    cp_src 'config/consumer.properties', 'etc/kafka'
    cp_src 'config/producer.properties', 'etc/kafka'
    cp_src 'config/zookeeper.properties', 'etc/kafka'
  end

  # Compile kafka and build deb package
  def make_pkg
    with_src_dir do
      msg "Updating Kafka"
      exec './sbt update'
      msg "Building Kafka"
      exec './sbt package'
      exec './sbt assembly-package-dependency'
    end
    cptree @src_dir, "#{@workdir}/usr/lib/kafka"

    build_pkg
  end

  def build_pkg
    c = @deb
    pkg="#{@pwd}/#{c[:name]}_#{c[:version]}~#{c[:release]}_#{c[:arch]}.deb"
    cmd = %Q(fpm \
-t deb \
-p "#{pkg}" \
-s dir \
-n #{c[:name]}  \
-v "#{c[:version]}-#{c[:release]}"  \
--description "#{c[:description]}" \
--url="#{c[:url]}" \
-a "#{c[:arch]}" \
--category "#{c[:category]}" \
--vendor "#{c[:vendor]}" \
--license "#{c[:license]}" \
-m "#{c[:maintainer]}"  \
--prefix=/ \
-d "default-jre" \
--before-install "#{@confdir}/preinst" \
--after-install "#{@confdir}/postinst" \
--config-files "/etc/init.d/kafka" \
--config-files "/etc/default/kafka" \
--config-files "/etc/kafka/server.properties"  \
--config-files "/etc/kafka/producer.properties" \
--config-files "/etc/kafka/zookeeper.properties" \
--config-files "/etc/kafka/consumer.properties" \
--config-files "/etc/kafka/log4j.properties" \
--config-files "/etc/security/limits.d/kafka-nofiles.conf" \
--config-files "/etc/logrotate.d/kafka" \
--verbose)
    puts cmd
    # dot at the end will add all files in build/ dir
    with_deb_dir do
      system("#{cmd} .")
    end
  end

  # From config/ directory to package root
  def cp_conf(src, dst)
    cp "#{@confdir}/#{src}", "#{@workdir}/#{dst}"
  end

  # From src/{tar}/ directory to package root
  def cp_src(src, dst)
    cp "#{@src_dir}/#{src}", "#{@workdir}/#{dst}"
  end

  def finish
    rmdir(@src_dir)
  end

  def with_deb_dir
    Dir.chdir @workdir do
      yield
    end
  end

  def with_src_dir
    Dir.chdir @src_dir do
      yield
    end
  end

end

