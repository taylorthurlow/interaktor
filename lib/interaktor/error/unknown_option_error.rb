class Interaktor::Error::UnknownOptionError < Interaktor::Error::OptionError
  def message
    "Unknown option(s) in #{interaktor} interaktor: #{options.keys.join(", ")}"
  end
end
