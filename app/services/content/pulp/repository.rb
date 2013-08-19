class Content::Pulp::Repository
  PULP_SELECT_FIELDS = ['name', 'epoch', 'version', 'release', 'arch', 'checksumtype', 'checksum']

  attr_reader :pulp_id,  :content_type, :relative_path, :name, :description
  delegate :logger, :to => :Rails

  class << self

    def create(options = {})
      new(options).create
    end

    def delete(pulp_id)
      new(:pulp_id => pulp_id).delete
    end

    def sync(pulp_id)
      new(:pulp_id => pulp_id).sync
    end

  end

  def initialize options = {}
    options.each do |k, v|
      instance_variable_set("@#{k}", v) if respond_to?("#{k}".to_sym)
    end

    raise('must define pulp id') unless pulp_id

    # initiate pulp connection
    Content::Pulp::Configuration.new
  end

  def create_with_distributor
    create_repository [pulp_distributor]
  end

  def create
    create_repository
  end

  def display_name
    details['display_name']
  end

  def checksum_type
    details['checksum_type']
  end

  def description
    @description || details['description']
  end

  def counters
    details['content_unit_counts']
  end

  def feed
    @feed || importer['config']['feed_url']
  end

  def last_sync
    importer['last_sync']
  end

  def last_publish
    distributor['last_publish']
  end

  def auto_publish
    @auto_publish.nil? ? distributor['auto_publish'] : @auto_publish
  end

  def protected
    @protected.nil? ? distributor['protected'] : @protected
  end

  def reload!
    @details = nil
  end

  def sync_status
    status = Runcible::Extensions::Repository.sync_status(pulp_id)
    Content::Pulp::RepositorySyncStatus.new(status.first) unless status.empty?
  end

  def sync_history
    history = Runcible::Extensions::Repository.sync_history(pulp_id)
    (history || []).map do |sync|
      Content::Pulp::RepositorySyncHistory.new(sync)
    end
  end

  def delete
    Runcible::Resources::Repository.delete(pulp_id)
  rescue RestClient::ResourceNotFound => e
    true #not found is not a failure for delete
  end

  def sync
    Runcible::Resources::Repository.sync(pulp_id)
  end

  def publish
    Runcible::Extensions::Repository.publish_all(pulp_id)
  end

  def cancel_running_sync!
    return if sync_status.blank? || sync_status.not_synced?
    Runcible::Resources::Task.cancel(sync_status.task_id)
  rescue RestClient::ResourceNotFound
    # task already done, nothing to do here
  end

  # once we keep a list pulp servers, this should be done in create/destroy
  def create_event_notifier
    url      = Rails.application.routes.url_helpers.
                 events_api_repositories_url(:only_path => false, :host => Setting[:foreman_url])
    type     = '*'
    resource = Runcible::Resources::EventNotifier
    notifs   = resource.list

    #only create a notifier if one doesn't exist with the correct url
    exists   = notifs.select { |n| n['event_types'] == [type] && n['notifier_config']['url'] == url }
    resource.create(resource::NotifierTypes::REST_API, { :url => url }, [type]) if exists.empty?
    true
  end

  private

  def create_repository pulp_distributors = []
    defaults
    Runcible::Extensions::Repository.create_with_importer_and_distributors(pulp_id,
                                                                           pulp_importer,
                                                                           pulp_distributors,
                                                                           { :display_name => relative_path || name,
                                                                             :description  => description })
  rescue RestClient::BadRequest => e
    raise parse_error(e)
  end

  def pulp_importer
    options = {
      :feed_url => feed
    }

    case content_type
      when Content::Repository::YUM_TYPE, Content::Repository::KICKSTART_TYPE
        Runcible::Extensions::YumImporter.new(options)
      when Content::Repository::FILE_TYPE
        Runcible::Extensions::IsoImporter.new(options)
      else
        raise "Unexpected repo type %s" % content_type
    end
  end

  def pulp_distributor
    case content_type
      when Content::Repository::YUM_TYPE, Content::Repository::KICKSTART_TYPE
        Runcible::Extensions::YumDistributor.new(relative_path, protected, true,
                                                 { :protected    => protected, :id => pulp_id,
                                                   :auto_publish => auto_publish })
      when Content::Repository::FILE_TYPE
        dist              = Runcible::Extensions::IsoDistributor.new(true, true)
        dist.auto_publish = true
        dist
      else
        raise "Unexpected repo type %s" % content_type
    end
  end

  def defaults
    @protected = true if @protected.nil?
  end

  def importer
    details['importers'].empty? ? {} : details['importers'].first
  end

  def distributor
    details['distributors'].empty? ? {} : details['distributors'].first
  end

  def details
    @details ||= Runcible::Resources::Repository.retrieve(pulp_id, { :details => true })
  rescue RestClient::ResourceNotFound => e
    logger.warn "Repo not found: #{parse_error(e)}"
    {:state => 'not found'}
  end

  def state
    return 'published'       if last_publish.present?
    return sync_status.state if sync_status.present?
    return details[:state]   if details[:state]
  end

  def parse_error exception
    JSON.parse(exception.response)['error_message']
  end
end
