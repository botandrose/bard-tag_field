module Bard
  module TagField
    class Field < ActionView::Helpers::Tags::TextField
      def render &block
        add_default_name_and_id(@options)

        # Remove choices from HTML options before rendering
        choices = @options.delete(:choices)

        # Store choices for render_object_values method
        @choices = choices

        # Generate unique datalist ID if we have choices and no block
        datalist_id = nil
        if choices&.any? && !block
          datalist_id = "#{@options[:id]}_datalist"
          @options[:list] = datalist_id
        end

        result = @template_object.content_tag("input-tag", @options) do
          next block.call(@options) if block
          render_object_values
        end

        # Add datalist after input-tag if we have choices and no block
        if choices&.any? && !block
          result += render_datalist(datalist_id, choices)
        end

        result
      end

      private

      def render_datalist(datalist_id, choices)
        @template_object.content_tag("datalist", id: datalist_id) do
          choices.map do |choice|
            case choice
            when Array
              # Handle nested arrays [display, value]
              display_text, submit_value = choice.first(2)
              @template_object.content_tag("option", display_text, value: submit_value)
            else
              # Handle simple strings
              @template_object.content_tag("option", choice, value: choice)
            end
          end.join("\n").html_safe
        end
      end

      def render_object_values
        choice_map = build_choice_map(@choices)

        Array(@object.try(@method_name)).map do |tag|
          # Use label from choices if available, otherwise use tag as both value and label
          label = choice_map[tag] || tag
          @template_object.content_tag("tag-option", label, value: tag)
        end.join("\n").html_safe
      end

      def build_choice_map(choices)
        return {} unless choices.is_a?(Array)

        choice_map = {}
        choices.each do |choice|
          case choice
          when Array
            # Handle nested arrays [display, value]
            display_text, submit_value = choice.first(2)
            choice_map[submit_value] = display_text
          else
            # Handle simple strings - value and label are the same
            choice_map[choice] = choice
          end
        end
        choice_map
      end
    end
  end
end
