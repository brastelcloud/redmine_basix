module Basix
  # Patches Redmine's Tracker model
  module TrackerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)
 
      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        after_create :handle_tracker_after_create
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def handle_tracker_after_create
        # new tracker was created. Update tracker list for custom_field phone_number
        cf_phone_number = CustomField.find_by name: 'phone_number', type: 'IssueCustomField'
        if not cf_phone_number then
          # custom_field doesnt' exist yet (probably because initial integration configuration was not done yet. So just ignore
          return
        end
        tracker_ids = Tracker.all.map(&:id)
        cf_phone_number.safe_attributes = {tracker_ids: tracker_ids}
        if cf_phone_number.save then
          logger.error "OK OK OK"
        else
          logger.error "Failed to update custom_field phone_number list of trackers after creation of #{self.name}"
        end
      end
    end
  end
end 
