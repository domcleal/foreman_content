module Content
  class Repository < ActiveRecord::Base
    include Content::Orchestration::Pulp::Sync
    include Foreman::STI

    YUM_TYPE       = 'yum'
    KICKSTART_TYPE = 'kickstart'
    FILE_TYPE      = 'iso'
    TYPES          = [YUM_TYPE, KICKSTART_TYPE, FILE_TYPE]

    belongs_to :product, :class_name => 'Content::Product'
    belongs_to :operatingsystem
    belongs_to :gpg_key
    belongs_to :architecture
    has_many :repository_clones

    before_destroy EnsureNotUsedBy.new(:repository_clones)

    validates_presence_of :type # can't create this object, only child

    validates :name, :presence => true
    validates_uniqueness_of :name, :scope => [:operatingsystem_id, :product_id]
    validates_inclusion_of :content_type,
                           :in          => TYPES,
                           :allow_blank => false,
                           :message     => (_("Please select content type from one of the following: %s") % TYPES.join(', '))

    scoped_search :on => [:name, :enabled], :complete_value => :true
    scoped_search :in => :architecture, :on => :name, :rename => :architecture, :complete_value => :true
    scoped_search :in => :operatingsystem, :on => :name, :rename => :os, :complete_value => :true
    scoped_search :in => :product, :on => :name, :rename => :product, :complete_value => :true

    scope :kickstart, where(:content_type => KICKSTART_TYPE)
    scope :yum, where(:content_type => YUM_TYPE)

    def content_types
      TYPES
    end

    # The label is used as a repository label in a yum repo file.
    def to_label
      "#{entity_name}-#{name}".parameterize
    end

    #inhariters are expected to override this method
    def entity_name
      ''
    end

    def publish content_view
      repository_clones.create!(
        :content_views => [content_view],
        :name => self.name + "_clone",
        :relative_path => "content_views/#{to_label}/#{Foreman.uuid}"
      )
    end

  end
end
