# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'set'

# Properties storage
class Properties

  def initialize
    @properties = {}
  end

  def set(key, value)
    @properties[key] = value
  end

  def fetch(key)
    @properties[key]
  end

  def respond_to?(method)
    @properties.has_key?(method)
  end

  def roles
    @roles ||= Set.new
  end

  def method_missing(key, value=nil)
    if value
      set(lvalue(key), value)
    else
      fetch(key)
    end
  end

  private

  def lvalue(key)
    key.to_s.chomp('=').to_sym
  end
end
