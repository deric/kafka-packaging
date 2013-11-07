
class Configuration

  class << self
    def env
      @env ||= new
    end
  end

  def set(key, value)
    config[key] = value
  end

  def delete(key)
    config.delete(key)
  end

  def fetch(key, default=nil, &block)
    value = fetch_for(key, default, &block)
    if value.respond_to?(:call)
      set(key, value.call)
    else
      value
    end
  end

  def timestamp
    @timestamp ||= Time.now.utc
  end

  private

  def config
    @config ||= Hash.new
  end

  def fetch_for(key, default, &block)
    if block_given?
      config.fetch(key, &block)
    else
      config.fetch(key, default)
    end
  end

end

