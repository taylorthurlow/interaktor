class FakeInteraktor
  # @param name [String]
  def self.build_interaktor(name = nil, type: Interaktor, &block)
    singular_name = type.to_s.gsub("::", "")
    name ||= "MyTest#{singular_name}"

    # Attempt to delete the constant we're about to try to create, which might
    # be the case due to previous tests creating an interaktor with the same
    # class name.
    begin
      Object.send(:remove_const, name.to_sym)
    rescue NameError
    end

    Class.new.include(type).tap do |klass|
      klass.define_singleton_method(:name) { name.to_s }
      klass.define_singleton_method(:inspect) { name.to_s }
      klass.define_singleton_method(:to_s) { inspect }
      klass.class_eval(&block) if block
      Object.const_set(name, klass)
    end
  end
end
