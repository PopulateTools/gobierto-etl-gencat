require_relative "./row_decorator"
require_relative "./people_importer"
require_relative "./resource_importer"
require "csv"

module Utils
  class BaseImporter
    def initialize(opts = {})
      @data = CollectionDecorator.new(CSV.read(opts[:path], headers: true), decorator: Utils::RowDecorator)
      @site = opts[:site]
      @people_importer = PeopleImporter.new(site: @site)
      @department_importer = ResourceImporter.new(site: @site, class_name: "GobiertoPeople::Department")
      @interest_group_importer = ResourceImporter.new(site: @site, class_name: "GobiertoPeople::InterestGroup")
      @errors = []
    end

    def import!
      puts "\n=========================\nSummary\n========================="
      @people_importer.errors_summary
      @department_importer.errors_summary
      @interest_group_importer.errors_summary
      errors_summary
    end

    def errors_summary
      if errors?
        puts "Some rows could't be loaded because associated resources failed to be created"
        @errors.each do |error|
          puts "\n\nFor row:\n#{ error[:resource_attrs] }\n"
          puts ", the following resources failed to be created:"
          error[:not_persisted_resources].each do |resource|
            puts "\n-#{resource}"
          end
        end
      else
        puts "The importer has loaded data with no errors"
      end
    end

    def errors?
      @errors.present?
    end

    def errors
      @errors
    end

    def first_record_with_errors_date
      @errors.map { |e| e[:resource_updated_at] }.compact.min
    end
  end
end
