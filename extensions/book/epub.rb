require "fileutils"
require "nokogiri"

module Book
  class Epub
    include XMLParse
    attr_reader :chapters, :template_path, :output_path, :metadata

    # Pass in an array of chapter objects on initialization
    # Also expects  a hash of metadata and the sitemap to be passed in
    def initialize(chapters, metadata, sitemap)
      @chapters      = chapters
      @output_path   = "dist/epub/OEBPS/"
      @template_path = "extensions/book/templates/"
      @metadata      = metadata

      epub_build_script(metadata, sitemap)
    end

    # Run this process to build the complete epub file
    def epub_build_script(metadata, sitemap)
      build_epub_dir
      copy_images(sitemap)
      copy_css
      build_chapters
      build_opf(metadata)
    end

    # Ensure a clean workspace
    def clean_directory(dirname)
      valid_start_chars = /[A-z]/
      valid_start_chars.freeze
      return false unless dirname.chr.match(valid_start_chars)

      FileUtils.rm_rf(dirname) if Dir.exist?(dirname)
      Dir.mkdir(dirname)
    end

    # Build out the EPUB directory structure for later zipping
    def build_epub_dir
      Dir.chdir("dist") do
        clean_directory("epub")
        Dir.chdir("epub") do
          ["META-INF", "OEBPS"].each { |dir| clean_directory(dir) }
          Dir.chdir("OEBPS") do
            ["assets", "assets/images"].each { |dir| clean_directory(dir) }
          end
        end
      end
    end

    # Use Middleman's sitemap to get a set of image resources
    # Then copy them to the appropriate location
    def copy_images(sitemap)
      resources = sitemap.resources
      images = resources.select { |r| r.path.match("assets/images/*") }
      images.reject! { |r| r.path.chr == "." }

      Dir.chdir(output_path + "assets/images") do
        images.each do |i|
          File.open(i.file_descriptor.relative_path.basename, "w") do |f|
            f.puts i.render
          end
        end
      end
    end

    # Copy the template CSS file into the epub assets folder
    def copy_css
      # copy fonts if custom fonts are being used
      css_template = template_path + "epub.css"
      css_output_path = output_path + "assets/epub.css"
      FileUtils.cp(css_template, css_output_path)
    end

    # Construct each epub chapter
    def build_chapters
      chapters.each(&:write_epub_html)
    end

    def generate_cover
      # Should a cover image be specified in config somehow?
      # If so, copy that image as cover.jpg to dist/epub/OEBPS/assets/images
      # Then load the XHTML cover template and add appropriate metadata
      # Write that file to dist/epub/OEBPS/cover.xhtml
    end

    def build_toc
      # Load TOC NCX file into nokogiri
      # Populate the metadata
      # Clean out the <navMap>
      # Add the first navpoint for the cover file
      # Loop through the chapters and build <navPoint> fragments, append to <navMap>
      # Write the file to dist/epub/OEBPS/toc.ncx
    end

    # Expects a hash of book metadata to be passed in
    def build_opf(metadata)
      output_path = "dist/epub/OEBPS/"
      filename    = output_path + "content.opf"
      template    = get_template("content.opf")
      manifest    = ""

      # TODO: write this method as a recursive process to be more concise
      Dir.chdir(output_path) do
        chapter_files = Dir.glob("*.html")
        chapter_files.each do |chapter|
          manifest << generate_item_tag(chapter)
        end

        assets = Dir.glob("assets/*")
        # This method needs to recursively go inside of subdirectories
        assets.each do |asset|
          if Dir.exist? asset
            subfolder_contents = Dir.glob("#{asset}/*")
            subfolder_contents.each { |item| manifest << generate_item_tag(item) }
          else
            manifest << generate_item_tag(asset)
          end
        end
      end

      puts manifest

      # Build the manifest (if this method is called last, just read contents of the OEBPS dir)
      # Build the spine

      File.open(filename, "w") do |f|
        template.at_css("dc|title").content      = metadata[:title]
        template.at_css("dc|creator").content    = metadata[:author]
        template.at_css("dc|publisher").content  = metadata[:publisher]
        template.at_css("dc|date").content       = metadata[:date]
        template.at_css("dc|identifier").content = metadata[:book_id]

        f.puts template
      end
    end
  end
end