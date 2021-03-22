class FakeInteraktor
  # @param name [String]
  def self.build_interaktor(name = nil, type: Interaktor, &block)
    name ||= "MyTest#{type}"

    result = Class.new.include(type)

    result.class_eval(&block) if block
    result.define_singleton_method(:inspect) { name.to_s }
    result.define_singleton_method(:to_s) { inspect }

    result
  end
end
