class FakeInteraktor
  # @param name [String]
  def self.build_interaktor(name = nil, type: Interaktor, &block)
    name ||= "MyTest#{type}"

    Class.new.include(type).tap do |klass|
      klass.class_eval(&block) if block
      klass.define_singleton_method(:inspect) { name.to_s }
      klass.define_singleton_method(:to_s) { inspect }
    end
  end
end
