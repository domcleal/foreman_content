class Content::Pulp::EventHandler
  attr_reader :type, :status
  delegate :name, :to => :repo
  delegate :logger, :to => :Rails

  def initialize(pulp_id, params)
    @type, @status = parse_type
    @params        = params
    log
    update_state
  end

  private
  attr_reader :params

  def repo
    @repo ||= case type
              when 'sync'
                Content::Repository.where(:pulp_id => pulp_id).first
              when 'promote'
                Content::RepositoryClone.where(:pulp_id => pulp_id).first
              end
  end

  def log
    logger.info "Repository #{name} #{type} #{status}"
  end

  def parse_type
    # converts repo.sync.start to ['sync','start']
    params['event_type'].gsub(/^repo\./, '').split('.')
  end

  def update_state
    #nothing to do if we didnt finish a task
    return unless status == 'finish'

    case type
    when 'sync'
      repo.update_attribute(:last_sync, last_sync) if success?
    when 'promote'
      repo.update_attribute(:last_published, last_published) if success?

    end
  end

  def success?
    result == 'success'
  end

  def result
    params['payload']['result']
  end

  def last_sync
    Time.parse(params['payload']['last_sync'])
  end

  def last_published
    Time.parse(params['payload']['completed'])
  end

end
