module Plotly
  module Castable
    def to_h
      instance_variables.map do |attribute|
        k = attribute.to_s.delete('@').to_sym
        v = instance_variable_get(attribute)

        v = v.to_h if in_plotly_module?(v.class)

        [k, v]
      end.to_h
    end

    private

    def in_plotly_module?(klazz)
      klazz.to_s.split('::').first == 'Plotly'
    end
  end
end
