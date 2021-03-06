# frozen-string_literal: true

module Decidim
  module Meetings
    class CloseMeetingEvent < Decidim::Events::SimpleEvent
      def resource_text
        translated_attribute(resource.description)
      end
    end
  end
end
