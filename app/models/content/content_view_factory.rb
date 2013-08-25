module Content
  class ContentViewFactory
    include ActiveModel::Conversion
    extend  ActiveModel::Naming

    attr_accessor :type, :id, :parent_cv, :product_cvs
    # create a content view of a single product
    def self.create_product_content_view(product_id)
      originator = Product.find_by_id(product_id)
      ContentView.new(:source_repositories => originator.repositories, :originator_name => originator.name)
    end

    # create a content view of an operating system
    def self.create_os_content_view(operatingsystem_id)
      originator = Operatingsystem.find_by_id(operatingsystem_id)
      ContentView.new(:source_repositories => originator.repositories, :originator_name => originator.to_label)
    end

    # create a composite content view of a hostgroup (the hostgroup may have a list of products) and a parent
    # content view. The parent content view is one of the hostgroup parent content views.
    # A hostgroup may have number of content views representing different versions of that hostgroup content.
    def self.create_composite_content_view(options = {})
      factory = new(options)
      hostgroup   = Hostgroup.find_by_id(factory.id)
      ContentView.new(:source_repositories => factory.product_cvs, :originator_name => hostgroup.name, :parent_id => factory.parent_cv)
    end

    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def persisted?
      false
    end
  end
end
