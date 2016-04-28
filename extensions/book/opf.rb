require "fileutils"
require "nokogiri"
require "time"
require "slugify"

module Book
  class OPF
    include XMLParse

    def initialize(metadata)
      @metadata = metadata
      @modified = Time.now
      @template = get_template("content.opf")
      @output_path = "dist/epub/OEBPS/"
      @filename = @output_path + "content.opf"
      @manifest = ""
      @spine = ""
    end

    def build
      add_metadata
      add_toc_ncx
      add_chapters
      add_assets
      write_file
    end

    def add_toc_ncx
      @manifest << generate_item_tag("toc.ncx", "ncx")
    end

    def add_chapters
      Dir.chdir(@output_path) do
        chapters = Dir.glob("*.html")
        chapters.each do |chapter|
          # Chapter id should include slugified name up to .html extension
          chapter_id = chapter[0..-6].slugify
          @manifest << generate_item_tag(chapter, chapter_id)
          @spine    << generate_itemref_tag(chapter_id)
        end
      end
    end

    def add_assets
      Dir.chdir(@output_path) do
        # Recursively get folder contents but exclude chapters (handled above)
        assets = Dir.glob("**/*").reject { |f| File.fnmatch("*.html", f) }
        asset_index = 1
        assets.each do |asset|
          next if Dir.exist? asset
          next if asset == "toc.ncx"
          asset_id = "asset#{asset_index}"
          @manifest << generate_item_tag(asset, asset_id)
          asset_index += 1
        end
      end
    end

    def add_metadata
      @template.at_css("dc|title").content         = @metadata[:title]
      @template.at_css("dc|creator").content       = @metadata[:author]
      @template.at_css("dc|publisher").content     = @metadata[:publisher]
      @template.at_css("dc|date").content          = @metadata[:date]
      @template.at_css("dc|identifier").content    = @metadata[:book_id]
      @template.at_css("meta[property='dcterms:modified']").content = @modified.utc.iso8601
    end

    def write_file
      File.open(@filename, "w") do |f|
        manifest = Nokogiri::XML::DocumentFragment.parse(@manifest)
        spine = Nokogiri::XML::DocumentFragment.parse(@spine)
        manifest.parent = @template.at_css("manifest")
        spine.parent = @template.at_css("spine")
        f.puts @template
      end
    end
  end
end
