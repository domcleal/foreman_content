module Content
  class RepositoryClone < ActiveRecord::Base
    include Content::Orchestration::Pulp::Clone

    belongs_to :repository
    has_many :content_view_repository_clones
    has_many :content_views, :through => :content_view_repository_clones
    attr_accessible :description, :last_published, :name, :pulp_id, :relative_path, :status, :content_views

    validate :relative_path, :repository_id, :presence => true

    delegate :content_type, :architecture, :unprotected, :gpg_key, :product, :to => :repository
  end
end
