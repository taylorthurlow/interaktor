class Interaktor::Error::InvalidOrganizerFailureDefinitionError < Interaktor::Error::Base
  def message
    if defined?(interaktor::FailureAttributesModel)
      <<~MSG.gsub(/\s+/, " ").strip
        #{interaktor} organizer declares failure attributes, so it must define
        a `failure_attributes_from` method that builds them from the failed
        interaction of an organized interaktor.
      MSG
    else
      <<~MSG.gsub(/\s+/, " ").strip
        #{interaktor} organizer defines a `failure_attributes_from` method, but
        declares no failure attributes for it to build.
      MSG
    end
  end
end
