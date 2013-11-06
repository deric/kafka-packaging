#!/bin/ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'thor'
require './lib/helpers'


# file: kafka.thor
class Kafka < Thor

  include BuildHelpers

  desc "build", "builds Kafka debian package"
  method_option :version, :type => :string, :aliases => "-v"
  def build
    workdir = 'build'
    cleanup(workdir)
    prepare(workdir)
    checkout
    make_pkg
  end

  private

  def cleanup(workdir)
    msg 'cleaning old package...'
    rmdir(workdir)
  end

  def prepare(workdir)
    mkdir(workdir)
  end

  def checkout

  end

  def make_pkg

  end

end
