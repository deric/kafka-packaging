# -*- mode: ruby -*-
# vi: set ft=ruby :

require './properties'

class Dsl

  def with(properties)
    properties.each { |key, value| add_property(key, value) }
    self
  end

  def properties
    @properties ||= Properties.new
  end

end