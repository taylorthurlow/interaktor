class Interaktor::Error::SuccessInHookError < Interaktor::Error::Base
  def message
    <<~MSG.gsub(/\s+/, " ").strip
      #{interaktor} interaktor called `success!` in a hook. Only the `call`
      method of an interaktor can call `success!`.
    MSG
  end
end
