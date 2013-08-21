module Content
  class ContentViewFactory
    # create a content view of a single product
    def self.create_product_content_view(product_id)
      originator = Product.find_by_id(product_id)
      ContentView.new(:source_repositories=>originator.repositories, :originator_name=>originator.name)
    end

    # create a content view of an operating system
    def self.create_os_content_view(operatingsystem_id)
      originator = Operatingsystem.find_by_id(operatingsystem_id)
      ContentView.new(:source_repositories=>originator.repositories, :originator_name=>originator.to_label)
    end

    # create a composite content view of a hostgroup (the hostgroup may have a list of products) and a parent
    # content view. The parent content view is one of the hostgroup parent content views.
    # A hostgroup may have number of content views representing different versions of that hostgroup content.
    def self.create_composite_content_view(hostgroup_id, parent_id)
      originator = Hostgroup.find_by_id(hostgroup_id)
      repositories = Repository.where(:product_id => originator.product_ids)
      ContentView.new(:source_repositories=>repositories, :originator_name=>originator.name, :parent_id=>parent_id)
    end
  end
end
