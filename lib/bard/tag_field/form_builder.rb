require_relative "field"

module Bard
  module TagField
    module FormBuilder
      def bard_tag_field method, choices = nil, options = {}, html_options = {}, &block
        # Handle different method signatures to match Rails select helper
        case choices
        when Hash
          # bard_tag_field(:method, { class: "form-control" })
          html_options = options
          options = choices
          choices = nil
        when Array
          # bard_tag_field(:method, choices_array, { class: "form-control" })
          html_options = options if options.is_a?(Hash)
        when NilClass
          # bard_tag_field(:method)
          html_options = options
          options = {}
        end

        # Merge options and html_options for Rails compatibility
        merged_options = objectify_options(options.merge(html_options))

        # Pass choices to the Field class
        merged_options[:choices] = choices if choices

        Field.new(@object_name, method, @template, merged_options).render(&block)
      end
    end
  end
end
