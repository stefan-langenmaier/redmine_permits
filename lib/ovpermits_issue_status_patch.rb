require_dependency 'issue_status'

# Patches Redmine's Attachment dynamically.
module OVPermitPatches
  module IssueStatusPatch
    def self.included(base) # :nodoc:

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        has_many :permits, :dependent => :delete_all, :foreign_key => "status_id"
      end
  
    end
  end
end

# Add module to Issue
IssueStatus.send(:include, OVPermitPatches::IssueStatusPatch)