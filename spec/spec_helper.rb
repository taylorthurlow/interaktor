require "simplecov"
SimpleCov.start do
  enable_coverage :branch

  add_filter "/spec/"
  add_filter "/vendor/"
end

require "interaktor"
require "pry-byebug"

Dir[File.expand_path("support/*.rb", __dir__)].sort.each { |f| require f }
