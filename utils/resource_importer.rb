# frozen_string_literal: true

module Utils
  class ResourceImporter
    def initialize(opts = {})
      @site = opts[:site]
      @class_name = opts[:class_name]
      @relation = opts[:relation] || @class_name.constantize
      @errors = []
      @cached_resources = {}
    end

    def title_msg
      @title_msg ||= "=== Import #{ @class_name.titleize } ==="
    end

    def line_msg
      @line_msg ||= "=" * title_msg.length
    end

    def import!(attributes: , extra: {})
      puts "\n\n#{ line_msg }"
      puts title_msg
      puts "Processing #{ attributes.values.join(", ") }...\n\n"
      resource = find_or_create_resource(attributes, extra)
      puts line_msg
      resource
    end

    def save_new(resource)
      if (result = resource.save)
        puts "Created resource: #{ resource.pretty_inspect }"
      else
        error = { resource_attrs: resource.pretty_inspect,
                  errors_msg: resource.errors.full_messages.pretty_inspect }
        puts "Something failed trying to load resource: #{ error[:resource_attrs] }"
        puts "Errors summary: #{ error[:errors_msg] }"
        @errors << error
      end
      result
    end

    def errors_summary(silent_if_ok: true)
      if @errors.present?
        puts "The importer has reported the following errors loading resources of #{ @class_name }:"
        @errors.each do |error|
          puts "\n\nFor resource with attributes:\n#{ error[:resource_attrs] }"
          puts ", the following errors has been found:\n#{ error[:errors_msg] }"
        end
      else
        puts "The importer has loaded data with no errors" unless silent_if_ok
      end
    end

    def find_or_create_resource(attributes, extra)
      attributes.merge!(site: @site) if @relation.reflect_on_association(:site).present?
      cached_resource = find_cached_resource(attributes)
      resource = cached_resource.presence || @relation.find_or_initialize_by(attributes)

      if resource.persisted?
        puts "Found existing resource:"
        puts resource.pretty_inspect

        extra.select! { |attribute, value| value != resource[attribute] }
        if extra.any?
          puts "Some attributes will be updated:"
          extra.each do |attribute, value|
            puts "#{ attribute }: From #{ resource[attribute] } to #{ value }"
          end
          resource.update!(extra)
        end
      else
        resource.assign_attributes(extra)
        save_new resource
        add_to_cached_resources(resource, attributes)
      end
      resource
    end

    def add_to_cached_resources(resource, attributes)
      @cached_resources[attributes] = resource
    end

    def find_cached_resource(attributes)
      @cached_resources[attributes]
    end
  end
end
