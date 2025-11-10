class Interaktor::Error::MissingExplicitSuccessError < Interaktor::Error::Base
  def message
    <<~MSG.gsub(/\s+/, " ")
      #{interaktor} interaktor execution finished successfully, but the
      interaktor definition includes a `success` attribute definition, and as a
      result the interaktor must call the `success!` method with the appropriate
      attributes.
    MSG
  end
end
