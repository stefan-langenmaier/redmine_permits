module PermitsHelper
  
  def self.isDisabled?(issue, field)
    disabled = true
    
    user=User.current
    roles = user.roles_for_project(issue.project) unless issue.project.nil?
    for role in roles
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id = ? AND fieldname = ?", role.id, issue.tracker_id, issue.status_id, field])
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id IS NULL AND fieldname = ?", role.id, issue.tracker_id, field]) unless p
      if p.nil? || p.writable == true
        disabled = false
      end
    end unless roles.nil?
    
    return disabled
  end
  
  def self.isDisabledHTML?(issue, field)
    if self.isDisabled?(issue, field)
      return {:disabled => "disabled"}
    else
      return {}
    end
  end
  
  def self.isVisible?(issue, field)
    visible = false
    
    user=User.current
    roles = user.roles_for_project(issue.project) unless issue.nil? || issue.project.nil?
    for role in roles
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id = ? AND fieldname = ?", role.id, issue.tracker_id, issue.status_id, field])
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id IS NULL AND fieldname = ?", role.id, issue.tracker_id, field]) unless p
      if p.nil? || p.visible == true
        visible = true
      end
    end unless roles.nil?
    
    return visible
  end
  
end
