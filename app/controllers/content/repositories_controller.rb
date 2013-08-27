module Content
  class RepositoriesController < ::ApplicationController
    include Foreman::Controller::AutoCompleteSearch
    before_filter :find_by_name, :only => %w{show edit update destroy sync}

    def index
      @repositories = Repository.search_for(params[:search], :order => params[:order]).
        paginate(:page => params[:page]).includes(:product, :operatingsystem)
    end

    def new
      case params[:type]
        when "operatingsystem"
          @repository = Repository::OperatingSystem.new()
        when "product"
          @repository = Repository::Product.new()
        else
          not_found
      end
    end

    def create
      type = params[:content_repository].delete(:type)
      @repository = case type
                      when "Content::Repository::Product"
                        Repository::Product.new(params[:content_repository])
                      when "Content::Repository::OperatingSystem"
                        Repository::OperatingSystem.new(params[:content_repository])
      end
      if @repository.save
        process_success
      else
        process_error
      end
    end

    def edit
    end

    def update
      params[:content_repository].delete(:type)
      if @repository.update_attributes(params[:content_repository])
        process_success
      else
        process_error
      end
    end

    def show
    end

    def destroy
      if @repository.destroy
        process_success
      else
        process_error
      end
    end

    def sync
      @repository.sync
      process_success(:success_msg => _("Successfully started sync for %s") % @repository.to_label)
    rescue => e
      process_error(:error_msg => _("Failed to start sync for %s") % @repository.to_label)
    end
  end
end