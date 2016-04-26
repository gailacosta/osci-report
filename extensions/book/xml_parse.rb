require "nokogiri"
require "fileutils"

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
  end
end
