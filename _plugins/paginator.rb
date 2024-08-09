module Paginator

  class Generator < Jekyll::Generator
    priority :low
    def generate(site)

      # paginate all works
      per_page = Jekyll.configuration({})['works_per_page']
      last_page = site.data['works'].size / per_page + 1
      site.data['works'].sort_by! { |work| work['clavis']}

      for page in 1..last_page
        
        site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "page/#{page}", "index.html").tap do |file|

          first_in_page = (page - 1) * per_page
  
          file.data['layout'] = 'list'
          file.data['title'] = 'Clavis'
          file.data['works'] = site.data['works'].slice(first_in_page, per_page)
          file.data['pagination'] = paginate(page, last_page)

          if page == 1 then site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "/", "index.html").tap {|index| index.data.merge!(file.data)} end

        end

      end

      # paginate keywords
      site.data['keywords'].each do |keyword|
        site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "keywords/#{keyword.downcase}", "index.html").tap do |file|

          file.data['layout'] = 'list'
          file.data['keyword'] = keyword
          file.data['title'] = "Keyword: #{file.data['keyword'].gsub(/((?<=[a-z])[A-Z])/, ' \1')}"

        end
      end

    end
  end

end

def paginate(page, last_page)
  pagination = [1, last_page]
          
  if (page - 2) > 1 then pagination.push(page - 2) else pagination.push(page + 3) end
  if (page - 1) > 1 then pagination.push(page - 1) else pagination.push(page + 4) end
  
  if page == 1 then pagination.push(page + 5) end
  unless page == 1 or page == last_page then pagination.push(page) end
  if page == last_page then pagination.push(page - 5) end

  if (page + 1) < last_page then pagination.push(page + 1) else pagination.push(page - 4) end
  if (page + 2) < last_page then pagination.push(page + 2) else pagination.push(page - 3) end

  return pagination.sort
end