module Content
  class ContentView < ActiveRecord::Base
    has_ancestry :orphan_strategy => :rootify

    belongs_to :originator, :polymorphic => true
    has_many :available_content_views, :dependent => :destroy
    has_many :hostgroups, :through => :available_content_views
    has_many :environments, :through => :available_content_views
    delegate :operatingsystems, :to => :available_content_views, :allow_nil => true

    has_many :content_view_hosts, :dependent => :destroy, :uniq => true, :foreign_key => :content_view_id, :class_name => 'Content::ContentViewHost'
    has_many :hosts, :through => :content_view_hosts

    has_many :content_view_repository_clones
    has_many :repository_clones, :through => :content_view_repository_clones, :class_name => 'Content::RepositoryClone'
    has_many :repositories, :through => :repository_clones

    after_save :clone_repos

    validates_presence_of :name

    scoped_search :on => [:name, :created_at], :complete_value => :true
    scoped_search :in => :product, :on => :name, :rename => :product, :complete_value => :true
    scoped_search :in => :operatingsystem, :on => :name, :rename => :os, :complete_value => :true

    attr_accessor :source_repositories

    def to_label
      name || "#{originator.to_label} - #{DateTime.now.strftime("%m/%d/%Y")}".parameterize
    end

    def clone_repos
      return unless @source_repositories
      Repository.where(:id => @source_repositories).each do |repository|
        repository.publish self
      end
    end
  end
end
