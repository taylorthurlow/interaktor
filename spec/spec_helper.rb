require "simplecov"
SimpleCov.start do
  enable_coverage :branch

  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/lib/interaktor/error"
end

Bundler.require(:default, :test)
require "interaktor"

Dir[File.expand_path("support/*.rb", __dir__)].sort.each { |f| require f }
