# frozen_string_literal: true

module Utils
  class ProperName
    CONJUNCTIONS = ["i", "e"]

    attr_accessor :name, :components

    def initialize(name)
      @name = name.to_s.strip.gsub(/\s+/, " ")
      @components = @name.downcase.split(" ")
    end

    def extends?(other_name)
      other_name.slug_regexp.match?(slug) &&
        (components_without_conjunctions - other_name.components_without_conjunctions).join.length > (other_name.components_without_conjunctions - components_without_conjunctions).join.length
    end

    def components_without_conjunctions
      @components - CONJUNCTIONS
    end

    def slug_regexp_string
      parameterized_components = components.dup
      parameterized_components.map! do |component|
        if CONJUNCTIONS.include?(component)
          "(-#{ component }|)"
        elsif
          suffix = component.last == "." ? "[^-]*" : ""
          component.parameterize + suffix
        end
      end

      (0..components_without_conjunctions.length-3).each do |index|
        if parameterized_components[index].length >1 && parameterized_components[index].last != "*"
          parameterized_components[index] = abbrev_expr(parameterized_components[index])
        end
      end

      "^#{ parameterized_components.join("-").gsub(/-\(-/, "(-") }$"
    end

    def slug_regexp
      Regexp.new(slug_regexp_string, true)
    end

    def abbrev_expr(string)
      string.parameterize.insert(1,"(").concat("|)")
    end

    def slug
      components_without_conjunctions.join(" ").parameterize
    end
  end
end
