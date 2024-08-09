require 'nokogiri'

module TEI

  class Generator < Jekyll::Generator
    priority :highest
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
          work["description"] = doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:profileDesc/xmlns:abstract/xmlns:p').to_s

          work["titles"] = []
          # TITLES
          doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title[@xml:id]/@xml:id').each do |id|
            title = doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title[@xml:id="'+id+'" or @corresp="#'+id+'"]').map do |title|
              if title.xpath('@xml:lang').any? && title.xpath('@type').to_s == "normalized"
                { "#{title.xpath('@xml:lang').to_s}-latn" => title.xpath('./text()').to_s }
              elsif title.xpath('@xml:lang').any?
                { title.xpath('@xml:lang').to_s => title.xpath('./text()').to_s }
              else
                { nil => title.xpath('./text()').to_s }
              end
            end
            work["titles"].push(title.reduce({}, :merge))
          end

          unless work["titles"].any?
            work["titles"] = doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:fileDesc/xmlns:titleStmt/xmlns:title').map{ |title| { nil => title.xpath('./text()').to_s } }
          end
          work["searchable_titles"] = work["titles"].flat_map(&:values).join(' ')

          # REVISION HISTORY
          work["revisions"] = doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:revisionDesc/xmlns:change').map do |revision|
            {
              "person" => site.data['contributors'][revision.xpath('@who').to_s],
              "date" => revision.xpath('@when').to_s,
              "change" => revision.xpath('text()').to_s
            }
          end

          # FORMER IDS
          work["formerly"] = doc.xpath('xmlns:TEI/xmlns:text//xmlns:listRelation/xmlns:relation[@name="betmas:formerlyAlsoListedAs"]').map{|relation| relation.xpath('@passive').to_s.gsub(/LIT(\d{4}).+/, '\1')}

          # KEYWORDS
          work["keywords"] = doc.xpath('xmlns:TEI/xmlns:teiHeader/xmlns:profileDesc/xmlns:textClass/xmlns:keywords/xmlns:term/@key').map(&:to_s)
          site.data['keywords'] = site.data['keywords'].concat(work["keywords"]).uniq.sort

          # CONTRIBUTORS
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

          # create redirects for former works
          work["formerly"].each do |former|

            site.pages << Jekyll::PageWithoutAFile.new(site, site.source, "works/#{former}", "index.html").tap do |file|
  
              file.data['layout'] = 'redirect'
              file.data['redirect'] = work['url']
    
            end

          end
  
          # add to sitewide data
          site.data['works'] = site.data['works'].push(work)
  
        end

      end

    end
  end

end