class Permit < ActiveRecord::Base
  belongs_to :role
  belongs_to :tracker
  belongs_to :issue_status

  validates_presence_of :role
  
  # Returns workflow transitions count by tracker and role
  def self.count_by_tracker_and_role
    counts = connection.select_all("SELECT role_id, tracker_id, count(id) AS c FROM #{Permit.table_name} GROUP BY role_id, tracker_id")
    roles = Role.find(:all, :order => 'builtin, position')
    trackers = Tracker.find(:all, :order => 'position')
    
    result = []
    trackers.each do |tracker|
      t = []
      roles.each do |role|
        row = counts.detect {|c| c['role_id'].to_s == role.id.to_s && c['tracker_id'].to_s == tracker.id.to_s}
        t << [role, (row.nil? ? 0 : row['c'].to_i)]
      end
      result << [tracker, t]
    end
    
    result
  end

  # Find potential statuses the user could be allowed to switch issues to
#  def self.available_statuses(project, user=User.current)
#    Workflow.find(:all,
#                  :include => :new_status,
#                  :conditions => {:role_id => user.roles_for_project(project).collect(&:id)}).
#      collect(&:new_status).
#      compact.
#      uniq.
#      sort
#  end
  
  # Copies workflows from source to targets
  def self.copy(source_tracker, source_role, source_status, target_trackers, target_roles, target_stati)
    unless source_tracker.is_a?(Tracker) || source_role.is_a?(Role) || source_status.is_a?(IssueStatus)
      raise ArgumentError.new("source_tracker or source_role or source_status must be specified")
    end
    
    target_trackers = [target_trackers].flatten.compact
    target_roles = [target_roles].flatten.compact
    target_stati = [target_stati].flatten.compact
    
    target_trackers = Tracker.all if target_trackers.empty?
    target_roles = Role.all if target_roles.empty?
    target_stati = IssueStatus.all if target_stati.empty?
    
    target_trackers.each do |target_tracker|
      target_roles.each do |target_role|
        target_stati.each do |target_status|
          copy_one(source_tracker || target_tracker,
                     source_role || target_role,
                     source_status || target_status,
                     target_tracker,
                     target_role,
                     target_status)
        end
      end
    end
  end
  
  # Copies a single set of workflows from source to target
  def self.copy_one(source_tracker, source_role, source_status, target_tracker, target_role, target_status)
    unless source_tracker.is_a?(Tracker) && !source_tracker.new_record? &&
      source_role.is_a?(Role) && !source_role.new_record? &&
      source_status.is_a?(IssueStatus) && !source_status.new_record? &&
      target_tracker.is_a?(Tracker) && !target_tracker.new_record? &&
      target_role.is_a?(Role) && !target_role.new_record? &&
      target_status.is_a?(IssueStatus) && !target_status.new_record?
      
      raise ArgumentError.new("arguments can not be nil or unsaved objects")
    end
    
    if source_tracker == target_tracker && source_role == target_role && source_status == target_status
      false
    else
      transaction do
        delete_all :tracker_id => target_tracker.id, :role_id => target_role.id, :status_id => target_status.id
        connection.insert "INSERT INTO #{Permit.table_name} (tracker_id, role_id, status_id, fieldname, visible, writable)" +
                          " SELECT #{target_tracker.id}, #{target_role.id}, #{target_status.id}, fieldname, visible, writable" +
                          " FROM #{Permit.table_name}" +
                          " WHERE tracker_id = #{source_tracker.id} AND role_id = #{source_role.id} AND status_id = #{source_status.id}"
      end
      true
    end
  end
end
