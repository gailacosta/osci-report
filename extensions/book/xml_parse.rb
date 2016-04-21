require "nokogiri"
require "fileutils"

module Book
  # XMLParse module
  # Nokogiri parsing and processing scripts should live here
  module XMLParse
    # Load a template into Nokogiri for parsing
    def get_template(file)
      path = template_path + file
      File.open(path) { |f| Nokogiri::XML(f) }
    end

    # Pass in a string
    # Return a Nokogiri nodeset that has been processed
    def parse_chapter_text(text)
      fragment = Nokogiri::HTML::DocumentFragment.parse(text)
      # TODO: format links to work locally
      links = fragment.css("a")
      links.each do |link|
        # TODO: fix this later
        link["href"] = "#"
      end
      fragment
    end
  end
end
