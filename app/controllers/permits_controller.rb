class PermitsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin
  before_filter :find_roles
  before_filter :find_trackers
  before_filter :find_status
  before_filter :setup_fields
  
  class Field
    attr_reader :name, :id
    attr_writer :name, :id
    def initialize(name, id)
      @name = name
      @id = id
      #@type = type
    end
    
    def isVisible?(role, tracker, status)
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id = ? AND fieldname = ?", role.id, tracker.id, status.id, @id])
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id IS NULL AND fieldname = ?", role.id, tracker.id, @id]) unless p

      if p && p.visible == false
        return false
      else
        return true
      end
    end
    
    def isWritable?(role, tracker, status)
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id = ? AND fieldname = ?", role.id, tracker.id, status.id, @id])
      p = Permit.find(:first, :conditions => [ "role_id = ? AND tracker_id = ? AND status_id IS NULL AND fieldname = ?", role.id, tracker.id, @id]) unless p

      if p && p.writable == false
        return false
      else
        return true
      end
    end
  end
  
  def setup_fields

    @builtin_fields = [
      Field.new("Status", "status_id"),
      Field.new("Priority", "priority_id"),
      Field.new("Assigned To", "assigned_to_id"),
      Field.new("Product", "category_id"),
      Field.new("Affected Build", "affected_build_id"),
      Field.new("Fixed Build", "fixed_build_id"),
      Field.new("Verified Build", "verified_build_id"),
      Field.new("Project Stage", "fixed_version_id"),
      Field.new("Start Date", "start_date"),
      Field.new("Due Date", "due_date"),
      Field.new("Estimated Hours", "estimated_hours"),
      Field.new("Done Ratio", "done_ratio"),
      Field.new("Issue Score", "issue_score"),
      Field.new("Story Points", "story_points"),
      Field.new("Remaining Hours", "remaining_hours")
    ]
    
    @custom_fields = []
    
    cfs = CustomField.find(:all, :conditions => ['type = ? ', "IssueCustomField"])
    for field in cfs
      @custom_fields << Field.new(field.name, field.id)
    end
  end
  
  def index
    @permit_counts = Permit.count_by_tracker_and_role
  end
  
  def edit
    @role = Role.find_by_id(params[:role_id])
    @tracker = Tracker.find_by_id(params[:tracker_id])
    @status = IssueStatus.find_by_id(params[:status_id])
    
    if request.post?
      Permit.destroy_all( ["role_id=? and tracker_id=? AND status_id=?", @role.id, @tracker.id, @status.id])
      for ifield in @builtin_fields
        new_visible = params[:permits] && params[:permits][ifield.id] && params[:permits][ifield.id]['visible'] ? true : false
        new_writable = params[:permits] && params[:permits][ifield.id] && params[:permits][ifield.id]['writable'] ? true : false
        @role.permits.build(:tracker_id => @tracker.id, :status_id => @status.id, :fieldname => ifield.id, :visible => new_visible, :writable => new_writable)
      end
      for ifield in @custom_fields
        new_visible = params[:permits] && params[:permits][ifield.id.to_s] && params[:permits][ifield.id.to_s]['visible'] ? true : false
        new_writable = params[:permits] && params[:permits][ifield.id.to_s] && params[:permits][ifield.id.to_s]['writable'] ? true : false
        @role.permits.build(:tracker_id => @tracker.id, :status_id => @status.id, :fieldname => ifield.id.to_s, :visible => new_visible, :writable => new_writable)
      end
      if @role.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'edit', :role_id => @role, :tracker_id => @tracker, :status_id => @status.id
      else
        flash[:notice] = "COULD NOT BE SAVED"
      end
    end
    
  end
  
  def copy
    
    if params[:source_tracker_id].blank? || params[:source_tracker_id] == 'any'
      @source_tracker = nil
    else
      @source_tracker = Tracker.find_by_id(params[:source_tracker_id].to_i)
    end
    if params[:source_role_id].blank? || params[:source_role_id] == 'any'
      @source_role = nil
    else
      @source_role = Role.find_by_id(params[:source_role_id].to_i)
    end
    if params[:source_status_id].blank? || params[:source_status_id] == 'any'
      @source_status = nil
    else
      @source_status = IssueStatus.find_by_id(params[:source_status_id].to_i)
    end
    
    @target_trackers = params[:target_tracker_ids].blank? ? nil : Tracker.find_all_by_id(params[:target_tracker_ids])
    @target_roles = params[:target_role_ids].blank? ? nil : Role.find_all_by_id(params[:target_role_ids])
    @target_stati = params[:target_status_ids].blank? ? nil : IssueStatus.find_all_by_id(params[:target_status_ids])
     
    if request.post?
      if params[:source_tracker_id].blank? || params[:source_role_id].blank? || params[:source_status_id].blank? || (@source_tracker.nil? && @source_role.nil? && @source_stati.nil?)
        flash.now[:error] = l(:error_permit_copy_source)
      elsif @target_trackers.nil? || @target_roles.nil? || @target_stati.nil?
        flash.now[:error] = l(:error_permit_copy_target)
      else
        Permit.copy(@source_tracker, @source_role, @source_status, @target_trackers, @target_roles, @target_stati)
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'copy', :source_tracker_id => @source_tracker, :source_role_id => @source_role, :source_status_id => @source_status
      end
    end
  end
  

  private

  def find_roles
    @roles = Role.find(:all, :order => 'builtin, position')
  end
  
  def find_trackers
    @trackers = Tracker.find(:all, :order => 'position')
  end
  
  def find_status
    @stati = IssueStatus.find(:all, :order => 'position')
  end
end
