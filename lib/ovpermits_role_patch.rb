require_dependency 'role'

# Patches Redmine's Attachment dynamically.
module OVPermitPatches
  module RolePatch
    def self.included(base) # :nodoc:

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        has_many :permits, :dependent => :delete_all
      end
  
    end
  end
end

# Add module to Issue
Role.send(:include, OVPermitPatches::RolePatch)