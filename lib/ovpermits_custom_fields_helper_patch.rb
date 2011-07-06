require_dependency 'custom_fields_helper'

# Patches Redmine's Attachment dynamically.
module OVPermitsPatch
  module OVPermitsCustomFieldsHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
  
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        alias_method_chain :custom_field_tag, :permits
      end
  
    end
    
    module InstanceMethods
      
      # Return custom field html tag corresponding to its format
      def custom_field_tag_with_permits(name, custom_value)
        return custom_field_tag_without_permits(name, custom_value) if @issue.nil?
          
        custom_field = custom_value.custom_field
        field_name = "#{name}[custom_field_values][#{custom_field.id}]"
        field_id = "#{name}_custom_field_values_#{custom_field.id}"
        tooltip = "tooltip_cf_#{custom_field.id}"
    
        field_format = Redmine::CustomFieldFormat.find_by_name(custom_field.field_format)
        case field_format.try(:edit_as)
        when "date"
          text_field_tag(field_name, custom_value.value, :id => field_id, :size => 10, :disabled => PermitsHelper.isDisabled?(@issue, custom_field.id), :title => l(tooltip)) + 
          (PermitsHelper.isDisabled?(@issue, custom_field.id) ? nil : calendar_for(field_id))
        when "text"
          text_area_tag(field_name, custom_value.value, :id => field_id, :rows => 3, :style => 'width:90%', :disabled => PermitsHelper.isDisabled?(@issue, custom_field.id), :title => l(tooltip))
        when "bool"
          hidden_field_tag(field_name, '0') + check_box_tag(field_name, '1', custom_value.true?, :id => field_id, :disabled => PermitsHelper.isDisabled?(@issue, custom_field.id), :title => l(tooltip))
        when "list"
          blank_option = custom_field.is_required? ?
                           (custom_field.default_value.blank? ? "<option value=\"\">--- #{l(:actionview_instancetag_blank_option)} ---</option>" : '') : 
                           '<option></option>'
          select_tag(field_name, blank_option + options_for_select(custom_field.possible_values_options(custom_value.customized), custom_value.value), :id => field_id, :disabled => PermitsHelper.isDisabled?(@issue, custom_field.id), :title => l(tooltip))
        else
          text_field_tag(field_name, custom_value.value, :id => field_id, :disabled => PermitsHelper.isDisabled?(@issue, custom_field.id), :title => l(tooltip))
        end
   
      end
      
    end
  end
end

# Add module to Attachement
CustomFieldsHelper.send(:include, OVPermitsPatch::OVPermitsCustomFieldsHelperPatch)