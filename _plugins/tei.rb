require 'nokogiri'

module TEI

  class Generator < Jekyll::Generator
    def generate(site)

      xml_dir = site.dest.to_s.gsub(/_site/, 'xml/works')

      Dir.each_child(xml_dir) do |subdir|
        next unless File.directory?("#{xml_dir}/#{subdir}")

        Dir.foreach("#{xml_dir}/#{subdir}") do |filename|
          next if filename == '.' or filename == '..' or File.extname(filename) != '.xml'
  
          doc = Nokogiri::XML(File.open("#{xml_dir}/#{subdir}/#{filename}"))
  
          work = {}
          work["clavis"] = doc.xpath('xmlns:TEI/@xml:id').to_s.gsub(/LIT(\d{4}).+/, '\1')
          work["betmas"] = doc.xpath('xmlns:TEI/@xml:id').to_s
          work["url"] = "works/#{work['clavis']}/"

          work["titles"] = []
  
          #doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title[@xml:id]').each do |title|
          doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title').each do |title|
  
            work["titles"].push(title.xpath('./text()').to_s)
  
          end

          work["keywords"] = doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:profileDesc/xmlns:textClass/xmlns:keywords/xmlns:term/@key').map(&:to_s)
          site.data['keywords'] = site.data['keywords'].concat(work["keywords"]).uniq.sort
          work["keywords"] = work["keywords"].map{|keyword| keyword.gsub(/((?<=[a-z])[A-Z])/, ' \1')}

          work["contributors"] = []
          doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:editor').each do |editor|
            role = editor.xpath('@role').to_s
            if role == "" then role = "editor" end
            key = editor.xpath('@key').to_s
            work["contributors"].push({
              "role" => role.gsub(/((?<=[a-z])[A-Z])/, ' \1').downcase,
              "name" => site.data['contributors'][key]
            })
          end
          doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:revisionDesc/xmlns:change').each do |contributor|
            key = contributor.xpath('@who').to_s
            work["contributors"].push({
              "role" => "contributor",
              "name" => site.data['contributors'][key]
            })
          end
          work["contributors"].uniq!{ |person| person["name"] }
  
          # create page for work
          site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "works/#{work['clavis']}", "index.html").tap do |file|
  
            file.data['layout'] = 'work'
            file.data['title'] = "CAe #{work["clavis"]}"
            file.data.merge!(work)
  
          end
  
          # add to sitewide data
          site.data['works'] = site.data['works'].push(work)
  
        end

      end

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

      site.data['keywords'].each do |keyword|
        site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "keywords/#{keyword.downcase}", "index.html").tap do |file|

          file.data['layout'] = 'list'
          file.data['keyword'] = keyword.gsub(/((?<=[a-z])[A-Z])/, ' \1')
          file.data['title'] = "Keyword: #{file.data['keyword']}"

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