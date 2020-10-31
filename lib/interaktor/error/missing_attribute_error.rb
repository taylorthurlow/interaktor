class Interaktor::Error::MissingAttributeError < Interaktor::Error::AttributeError
  def message
    "Missing attribute(s) in call to #{interaktor}: #{attributes.join(", ")}"
  end
end
