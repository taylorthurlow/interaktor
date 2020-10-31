class Interaktor::Error::UnknownAttributeError < Interaktor::Error::AttributeError
  def message
    "Unknown attribute(s) in call to #{interaktor}: #{attributes.join(", ")}"
  end
end
