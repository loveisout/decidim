# frozen-string_literal: true

module Decidim::Amendable
  class EmendationPromotedEvent < Decidim::Amendable::AmendmentBaseEvent
    i18n_attributes :amendable_path, :amendable_type, :amendable_title, :emendation_path, :emendation_author_nickname, :emendation_author_path

    def amendment_resource
      @amendment_resource ||= resource.amendment
    end

    def amendable_resource
      @amendable_resource ||= resource.amendable
    end

    def emendation_resource
      resource
    end
  end
end
