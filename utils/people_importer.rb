# frozen_string_literal: true

require_relative "./proper_name"
require "csv"

module Utils
  class PeopleImporter
    LEVENSHTEIN_THRESHOLD = 7

    attr_accessor :similarities_with_existing_people

    def initialize(opts = {})
      @similarities_with_existing_people = {}
      @site = opts[:site]
      @existing_people = {}
      @errors = []
    end

    def import!(attributes:, extra: {})
      puts "\n\n===================================="
      puts     "=========== Import Person ==========="
      puts "Processing #{ attributes.values.join(", ") }...\n\n"
      name = resolve_name_ignoring_conjunctions(attributes[:name])
      person = find_or_initialize_person(name)
        # person = merge_duplicates(person)
      save_new(person) if person.new_record?
      puts "====================================="
      person
    end

    def resolve_name_ignoring_conjunctions(name)
      proper_name = Utils::ProperName.new(name)
      automatic_match = find_existing_person(proper_name)&.first

      return name unless automatic_match.present?

      automatic_match.name
    end

    def resolve_name_similarities(name)
      proper_name = Utils::ProperName.new(name)
      automatic_matches = find_existing_person(proper_name)
      return proper_name.name if automatic_matches.exists? || dictionary.has_key?(proper_name.name)

      matches = find_similarities(proper_name)
      return proper_name.name if matches.blank?

      if (name_solution = matches.find { |match| dictionary.has_key?(match.name) })
        puts "Name #{ proper_name.name } resolved as #{ name_solution.name }"
        return name_solution.name
      elsif (values_presence = dictionary.select { |key, values| values.include?(proper_name.name) }).present?
        values_presence.each do |key, names|
          return key if (matches.map(&:name) & names).present?
        end
      else
        key = OpenStruct.new("name" => proper_name.name)

        similarities_with_existing_people[key] = matches unless similarities_with_existing_people.has_key?(key)
        puts "Unresolved existing similarities found for #{proper_name.name}: #{similarities_with_existing_people[key].map{ |match| match.name }.join(", ")}."
      end
    end

    def merge_duplicates(person)
      if dictionary.has_key?(person.name)
        matching_people = dictionary[person.name].map { |name| @site.people.find_by_name(name) }.compact
        if matching_people.present?
          if person.new_record?
            person_attrs = person.attributes.except("id", "created_at", "updated_at", "slug")
            person = matching_people.shift
            person.update(person_attrs)
          end
          matching_people.each do |matching_person|
            merge_persons(person, matching_person)
          end
        end
      end
      save_new(person) if person.new_record?
      person
    end

    def merge_persons(destination, origin)
      return unless origin
      puts "Moving #{ origin.name } data to #{ destination.name }"
      # stuff to move dependent data of origin to destination
      origin.destroy
    end

    def save_new(person)
      if (result = person.save)
        puts "Created person: #{ person.pretty_inspect }"
        add_to_existing_people(person)
      else
        error = { resource_attrs: person.pretty_inspect,
                  errors_msg: person.errors.full_messages.pretty_inspect }
        puts "Something failed trying to load resource: #{ error[:resource_attrs] }"
        puts "Errors summary: #{ error[:errors_msg] }"
        @errors << error
      end
      result
    end

    def add_to_existing_people(person)
      (@existing_people[{ name: person.name, slug: person.slug }] ||= []).append(person)
    end

    def find_existing_person(proper_name)
      cached_result = @existing_people.find do |key, _|
        proper_name.slug_regexp.match?(key[:slug]) || proper_name == key[:name]
      end&.last

      return cached_result if cached_result.present?

      @existing_people[{ name: proper_name.name, slug: proper_name.slug }] = @site.people.where("slug ~* ? OR name = ?", proper_name.slug_regexp_string, proper_name.name).to_a
    end

    def inspect_person(person)
      person.attributes.extract!("id", "name", "slug").pretty_inspect
    end

    def find_or_initialize_person(name)
      proper_name = Utils::ProperName.new(name)
      matching_people = find_existing_person(proper_name)

      if matching_people.present?
        matching_person = matching_people.first
        puts "Found existing person with name #{ matching_person.name } and slug #{ matching_person.slug }"

        if proper_name.extends? Utils::ProperName.new(matching_person.name)
          old_name = matching_person.name
          matching_person.update_attribute(:name, proper_name.name)

          puts "Updated name: #{ old_name } with #{ matching_person.name }"
        end
        matching_person
      else
        puts "Initialized new person with name #{proper_name.name} and slug #{proper_name.slug}"
        @site.people.active.new(name: proper_name.name, slug: proper_name.slug)
      end
    end

    def find_similarities(person)
      order_cond = @site.people.sanitize_sql_for_order(["levenshtein(slug, ?)", person.slug])
      @site.people.where("levenshtein(slug, ?) <= ?", person.slug, LEVENSHTEIN_THRESHOLD).where.not(slug: person.slug).order(order_cond)
    end

    def dictionary
      NAMES_CONFLICT_RESOLUTIONS
    end

    def summarize_attributes(resource, attributes)
      "#{ resource.id.to_s.rjust(10) } | #{ attributes.map { |attr| resource.send(attr).to_s.rjust(40) }.join("|") }"
    end

    def errors_summary
      if (similarities = similarities_with_existing_people).any?
        puts "=================\n Please, resolve the ambiguities of following names before saving in database:\n\n"
        similarities.each do |person, matches|
          puts "> #{ summarize_attributes(person, [:name]) }"
          matches.each do |match|
            puts "< #{ summarize_attributes(match, [:name]) }"
          end
          puts "-------\n"
        end
      end
      if @errors.present?
        puts "Importer has reported the following errors loading people:"
        @errors.each do |error|
          puts "\n\nFor resource with attributes:\n#{ error[:resource_attrs] }"
          puts ", the following errors has been found:\n#{ error[:errors_msg] }"
        end
      end
    end
  end
end
