module Jekyll::NewFilters

  def uncamelize(input)
    
    input.gsub(/((?<=[a-z])[A-Z])/, ' \1')

  end

end

Liquid::Template.register_filter(Jekyll::NewFilters)