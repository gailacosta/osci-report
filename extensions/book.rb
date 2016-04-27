require_relative "book/helpers.rb"
require_relative "book/book_chapter.rb"
require_relative "book/epub.rb"

module Book
  class BookExtension < Middleman::Extension
    self.defined_helpers = [Book::Helpers]
    option :pdf_output_path, "dist/book.pdf", "Where to write generated PDF"
    option :prince_cli_flags, "--no-artificial-fonts", "Command-line flags for Prince PDF utility"
    option :epub_output_path, "dist/epub/", "Where to write generated epub file"
    expose_to_template :chapters, :title, :author

    attr_reader :chapters, :info, :pdf_output_path, :epub_output_path

    def initialize(app, options_hash = {}, &block)
      super
      @info     = @app.data.book
      @chapters = []

      # PDF Generation via Prince CLI
      app.after_build do |builder|
        book = app.extensions[:book]
        book.generate_pdf if environment? :pdf
        Epub.new(book.chapters, book.metadata, app.sitemap) if environment? :epub
      end
    end

    # Manipulator method
    # @return [Array<Middleman::Sitemap::Resource>] an array of resource objects
    def manipulate_resource_list(resources)
      generate_chapters!(resources)
      resources
    end

    # This method should read author info from the book.yml data file and
    # return a properly-formated FirstName Lastname author string.
    # @return [String]
    def author
      info.author_as_it_appears
    end

    # This method should read title info from the book.yml data file and
    # return a properly-formated string with the book's title
    # @return [String]
    def title
      info.title.main
    end

    # Return a hash with important book metadata
    # Pass this object to the EPUB instance for metadata population
    # TODO: Add more real data here
    def metadata
      {
        :title     => title,
        :author    => author,
        :publisher => "Book Publisher",
        :date      => "Book Date",
        :book_id   => "BOOK ID"
      }
    end

    # Calls the Prince CLI utility with args based on extension options
    # @return +nil+
    def generate_pdf
      pagelist = generate_pagelist
      output   = options.pdf_output_path
      flags    = options.prince_cli_flags
      puts `prince #{pagelist} -o #{output} #{flags}`
    end

    # Generate a list of files to pass to the Prince CLI
    # @return [String]
    def generate_pagelist
      arg_string  = ""
      baseurl     = @app.config.build_dir + "/"
      chapters.each { |c| arg_string += baseurl + c.destination_path + " " }
      arg_string
    end

    private
    # This method is meant to be called inside the manipulate_resource_list method
    # It modifies the resource list and returns nothing
    # By swapping out certain resource objects with a custom Chapter class that inherits
    # from Middleman::Sitemap::Resource, we can add custom methods for chapter-specific features
    # @return +nil+
    def generate_chapters!(resources)
      contents = resources.find_all { |p| p.data.sort_order }
      contents.each do |p|
        source, path, metadata = p.source_file, p.destination_path, p.metadata
        chapter = Book::Chapter.new(@app.sitemap, path, source, self)

        # Make sure to explicitly add metadata or else things will break
        chapter.add_metadata(metadata)

        resources.delete p
        resources.push chapter
        @chapters.push chapter
      end

      # Keep chapters from duplicating themselves endlessly on each livereload
      # TODO: find out what causes this behavior and remove this workaround
      @chapters.uniq! { |p| p.data.sort_order }
      @chapters.sort_by! { |p| p.data.sort_order }
    end
  end

  ::Middleman::Extensions.register(:book, BookExtension)
end
