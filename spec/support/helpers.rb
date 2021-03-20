class FakeInteractor
  # @param name [String]
  def self.build_interaktor(name, &block)
    result = Class.new.include(Interaktor)

    result.class_eval(&block) if block
    result.define_singleton_method(:inspect) { name.to_s }
    result.define_singleton_method(:to_s) { inspect }

    result
  end

  # @param name [String]
  def self.build_organizer(name = "MyTestOrganizer", &block)
    result = Class.new.include(Interaktor::Organizer)

    result.class_eval(&block) if block
    result.define_singleton_method(:inspect) { name.to_s }
    result.define_singleton_method(:to_s) { inspect }

    result
  end
end
