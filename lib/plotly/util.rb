class Object
  def convert_to(clazz)
    if is_a?(Hash)
      clazz.new(self)
    elsif !is_a?(clazz)
      raise # @todo raise type error
    else
      self
    end
  end
end
