# frozen_string_literal: true

module Decidim
  # A class to search for recent activity performed in a Decidim Organization.
  class ActivitySearch < Searchlight::Search
    # Needed by Searchlight, this is the base query that will be used to
    # append other criteria to the search.
    def base_query
      query = ActionLog
              .where(visibility: %w(public-only all))
              .where(organization: options.fetch(:organization))

      query = query.where(user: options[:user]) if options[:user]

      query = filter_follows(query)

      query
    end

    # Overwrites the default Searchlight run method since we want to return
    # activities in an specific order but we need to set it at the end of the chain.
    def run
      super.order(created_at: :desc)
    end

    # Adds a constrain to filter by resource type(s).
    def search_resource_type
      if resource_types.include?(resource_type)
        scope_for(resource_type)
      else
        all_resources_scope
      end
    end

    # All the resource types that are eligible to be included as an activity.
    def resource_types
      @resource_types ||= %w(
        Decidim::Accountability::Result
        Decidim::Blogs::Post
        Decidim::Comments::Comment
        Decidim::Consultations::Question
        Decidim::Debates::Debate
        Decidim::Meetings::Meeting
        Decidim::Proposals::Proposal
        Decidim::Surveys::Survey
        Decidim::Assembly
        Decidim::Consultation
        Decidim::Initiative
        Decidim::ParticipatoryProcess
      ).select do |klass|
        klass.safe_constantize.present?
      end
    end

    private

    def publicable_resource_types
      @publicable_resource_types ||= resource_types.select { |klass| klass.constantize.column_names.include?("published_at") }
    end

    def scope_for(resource_type)
      action = if publicable_resource_types.include?(resource_type)
                 "publish"
               else
                 "create"
               end

      query.where(resource_type: resource_type, action: action)
    end

    def all_resources_scope
      query
        .where(
          "(action = ? AND resource_type IN (?)) OR (action = ? AND resource_type IN (?))",
          "publish",
          publicable_resource_types,
          "create",
          (resource_types - publicable_resource_types)
        )
    end

    def filter_follows(query)
      follows = options[:follows]
      return query if follows.blank?

      conditions = follows.group_by(&:decidim_followable_type).map do |type, grouped_follows|
        Decidim::ActionLog.arel_table[:resource_type].eq(type).and(
          Decidim::ActionLog.arel_table[:resource_id].in(grouped_follows.map(&:decidim_followable_id))
        )
      end

      conditions += followed_users_conditions(follows)
      conditions += followed_spaces_conditions(follows)

      chained_conditions = conditions.inject do |previous_condition, condition|
        next condition unless previous_condition
        previous_condition.or(condition)
      end

      query.where(chained_conditions)
    end

    def followed_users_conditions(follows)
      followed_users = follows.where(decidim_followable_type: "Decidim::UserBaseEntity")
      return [] if followed_users.empty?

      [Decidim::ActionLog.arel_table[:decidim_user_id].in(followed_users.map(&:decidim_followable_id))]
    end

    def followed_spaces_conditions(follows)
      followed_spaces = follows.where(decidim_followable_type: participatory_space_classes)
      return [] if followed_spaces.empty?

      followed_spaces.group_by(&:decidim_followable_type).map do |type, grouped_follows|
        Decidim::ActionLog.arel_table[:participatory_space_type].eq(type).and(
          Decidim::ActionLog.arel_table[:participatory_space_id].in(grouped_follows.map(&:decidim_followable_id))
        )
      end
    end

    def participatory_space_classes
      Decidim.participatory_space_manifests.map(&:model_class_name)
    end
  end
end
