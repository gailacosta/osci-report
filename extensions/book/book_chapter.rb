require_relative "xml_parse"
require "slugify"

module Book
  class Chapter < Middleman::Sitemap::Resource
    include XMLParse

    # @return [Book::BookExtension] reference to the parent BookExtension instance
    # (necessary for comparison between chapters)
    attr_reader :book

    # Pass in a reference to the parent Book extension for later use
    def initialize(store, path, source, book)
      super(store, path, source)
      @book = book
    end

    # The title of the chapter, set in frontmatter
    # @return [String]
    def title
      data.title
    end

    # The author of the chapter, set in frontmatter
    # If no author is set, the value set globally in the book.yml file is used instead
    # @return [String]
    def author
      data.author || @book.author
    end

    # The chapter's order in the sequence
    # @return [Fixnum]
    def rank
      data.sort_order
    end

    # The body of the chapter, in HTML (no layout). This is for
    # alternate presentation formats like RSS, may also be useful
    # in EPUB generation.
    # @return [String]
    def body
      render layout: false
    end

    # Returns the next chapter object, or false if this is the last chapter
    # @return [Book::Chapter]
    def next_chapter
      @book.chapters.select { |p| p.rank > rank }.min_by(&:rank)
    end

    # Returns the previous chapter object, or false if this is the first chapter
    # @return [Book::Chapter]
    def prev_chapter
      @book.chapters.select { |p| p.rank < rank }.max_by(&:rank)
    end

    # Render chapter with epub layout
    # @return [String]
    def epub_text
      render layout: "epub_chapter"
    end

    # Pass in a string
    # Return a Nokogiri nodeset that has been processed
    def parse_chapter_text
      fragment = Nokogiri::HTML::DocumentFragment.parse(epub_text)
      # TODO: format links to work locally
      fragment.css("a").each { |node| node.replace(node.text) }
      fragment
    end

    def generate_navpoint(play_order)
      <<-EOM
      <navPoint id="#{title.slugify}" playOrder="#{play_order}">
        <navLabel>
          <text>#{title}</text>
          <content src="#{title.slugify}.html" />
        </navLabel>
      </navPoint>
      EOM
    end

    # Writes the content of this chapter to a new HTML file formatted for epub
    def write_epub_html
      #TODO: Move info about output paths to parent Book object somehow
      output_path = "dist/epub/OEBPS/"
      template = get_template("chapter.html")
      filename = output_path + title.slugify + ".html"

      File.open(filename, "w") do |f|
        doctitle         = template.at_css("title")
        doctitle.content = title
        fragment         = parse_chapter_text
        fragment.parent  = template.at_css("body")
        f.puts template
      end
    end
  end
end

