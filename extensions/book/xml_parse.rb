require "nokogiri"
require "fileutils"
require "pathname"

module Book
  # XMLParse module
  # Nokogiri parsing and processing scripts should live here
  module XMLParse
    # Load a template into Nokogiri for parsing
    def get_template(file)
      # TODO: move info about template paths into parent book object somehow
      path = "extensions/book/templates/" + file
      File.open(path) { |f| Nokogiri::XML(f) }
    end

    def generate_item_tag(filename, id)
      path = Pathname.new(filename)
      media_type = ""

      case path.extname
      when ".html"
        media_type = "application/xhtml+xml"
      when ".css"
        media_type = "text/css"
      when ".jpg"
        media_type = "image/jpeg"
      when ".png"
        media_type = "image/png"
      when ".svg"
        media_type = "image/svg"
      end

      <<-EOM
        <item id="#{id}" href="#{filename}" media-type="#{media_type}"/>
      EOM
    end

    def generate_itemref_tag(id)
      <<-EOM
        <itemref idref="#{id}" />
      EOM
    end
  end
end
