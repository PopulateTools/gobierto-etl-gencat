# frozen_string_literal: true

require "pathname"
require "fileutils"

module Utils
  class LocalStorage
    attr_writer :content
    attr_reader :file_name, :base_path, :file_path, :file_pathname

    def initialize(content: nil, path: "output")
      @file_name = path.split("/").last
      @base_path = "/tmp/gencat/#{ path.gsub(/#{ @file_name }$/, "").gsub(/\.+/, ".") }"
      @file_pathname = Pathname.new(file_path)
      @content = content
    end

    def save
      FileUtils.mkdir_p(base_path) unless File.exist?(base_path)
      File.open(file_path, "wb+") do |f|
        f.write(@content)
      end
    end

    def exist?
      file_pathname.exist?
    end

    def content
      @content || previous_content
    end

    def previous_content
      if exist?
        if file_pathname.file?
          File.open(file_path, "r") { |f| f.read }
        elsif file_pathname.directory?
          file_pathname.children.map(&:to_path).join("\n")
        end
      end
    end

    def file_path
      File.join(base_path, file_name)
    end

    def delete
      if file_pathname.file?
        file_pathname.delete
      elsif file_pathname.directory?
        file_pathname.rmtree
      end
    end

    protected

    def file_pathname
      Pathname.new(file_path)
    end
  end
end
