module Content::Orchestration::Pulp::Sync
  extend ActiveSupport::Concern
  include Content::Orchestration::Pulp

  included do
    after_validation :queue_pulp
    before_destroy :queue_pulp_destroy unless Rails.env.test?
  end

  def last_sync
    read_attribute(:last_sync) || repo.last_sync
  end

  private

  def queue_pulp
    return unless pulp? and errors.empty?
    new_record? ? queue_pulp_create : queue_pulp_update
  end

  def queue_pulp_create
    logger.debug "Scheduling new Pulp Repository"
    queue.create(:name   => _("Create Pulp Repository for %s") % self, :priority => 10,
                 :action => [self, :set_pulp_repo])
    queue.create(:name   => _("Sync Pulp Repository %s") % self, :priority => 20,
                 :action => [self, :set_sync_pulp_repo])
  end

  def queue_pulp_update
    # TODO: handle repo updates.
  end

  def queue_pulp_destroy
    return unless pulp? and errors.empty?
    logger.debug _("Scheduling removal of Pulp Repository %s") % name
    queue.create(:name   => _("Delete Pulp repository for %s") % name, :priority => 50,
                 :action => [self, :del_pulp_repo])
  end

  def set_pulp_repo
    repo.create
  end

  def del_pulp_repo
    repo.delete
  end

  def set_sync_pulp_repo
    repo.sync
  end

  def del_sync_pulp_repo
    repo.cancel_running_sync!
  end

  def repo_options
    {
      :pulp_id       => pulp_repo_id,
      :name          => to_label,
      :description   => description,
      :feed          => feed,
      :content_type  => content_type,
      :protected     => unprotected,
    }
  end

  def repo
    @repo ||= Content::Pulp::Repository.new(repo_options)
  end
end
