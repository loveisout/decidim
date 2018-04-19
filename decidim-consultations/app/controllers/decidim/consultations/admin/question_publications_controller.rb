# frozen_string_literal: true

module Decidim
  module Consultations
    module Admin
      # Controller that allows managing question publications.
      class QuestionPublicationsController < Decidim::Admin::ApplicationController
        include QuestionAdmin

        def create
          authorize! :publish, current_question

          PublishQuestion.call(current_question) do
            on(:ok) do
              flash[:notice] = I18n.t("question_publications.create.success", scope: "decidim.admin")
            end

            on(:invalid) do
              flash[:alert] = I18n.t("question_publications.create.error", scope: "decidim.admin")
            end

            redirect_back(fallback_location: consultation_questions_path(current_consultation))
          end
        end

        def destroy
          authorize! :publish, current_question

          UnpublishConsultation.call(current_question) do
            on(:ok) do
              flash[:notice] = I18n.t("question_publications.destroy.success", scope: "decidim.admin")
            end

            on(:invalid) do
              flash[:alert] = I18n.t("question_publications.destroy.error", scope: "decidim.admin")
            end

            redirect_back(fallback_location: consultation_questions_path(current_consultation))
          end
        end

        def current_participatory_space_manifest_name
          :consultations
        end
      end
    end
  end
end
