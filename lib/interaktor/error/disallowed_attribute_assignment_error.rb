class Interaktor::Error::DisallowedAttributeAssignmentError < Interaktor::Error::AttributeError
  def message
    <<~MESSAGE.strip.tr("\n", "")
      Attempted a disallowed assignment to the '#{attributes.first}'
      attribute which was not included when the #{interaktor} interaktor was
      originally called.
    MESSAGE
  end
end
