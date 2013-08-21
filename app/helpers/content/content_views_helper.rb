module Content
  module ContentViewsHelper

    def repositories(view)
      if view.new_record?
        view.source_repositories
      else
        view.repository_clones
      end
    end

  end
end