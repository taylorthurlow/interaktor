class Interaktor::Error::MissingExplicitSuccessError < Interaktor::Error::AttributeError
  def message
    "#{interaktor} interaktor execution finished successfully but requires one or more success parameters to have been provided: #{attributes.join(", ")}"
  end
end
