module Content
  module ContentViewsHelper

    def repositories_owner(view)
      if view.new_record?
        view.product || view.operatingsystem
      else
        view
      end
    end

  end
end