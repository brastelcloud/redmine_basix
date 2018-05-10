class BasixController < ApplicationController
  unloadable

  before_action :require_admin
  accept_api_auth :configure_integration

  def configure_integration
    cf_phone_number = CustomField.find_by name: 'phone_number', type: 'IssueCustomField'
    tracker_ids = Tracker.all.map(&:id)
    project_ids = Project.where("name IN (?)", params[:group_names]).map(&:id)

    cf_creation_params = {
      description: "Phone Number for Basix Call Aggregation",
      is_required: false,
      max_length: 32,
      min_length: nil,
      field_format: "string",
      name: "phone_number",
      is_for_all: false, # is_for_all means, "is for all projects". In our case, no.
      is_filter: true,
      searchable: true,
      editable: true,
      visible: true,
      multiple: false,
      tracker_ids: tracker_ids,
      project_ids: project_ids
    }

    if not cf_phone_number then
      cf_phone_number = CustomField.new_subclass_instance('IssueCustomField', cf_creation_params)
      if cf_phone_number.save then
        call_hook(:controller_custom_fields_new_after_save, :params => cf_creation_params, :custom_field => cf_phone_number)
      else
        render json: {success: false, error: "failed to create custom_field phone_number"}
        return
      end
    else
      cf_phone_number.safe_attributes = {tracker_ids: tracker_ids, project_ids: project_ids}
      if cf_phone_number.save then
        call_hook(:controller_custom_fields_edit_after_save, :params => cf_creation_params, :custom_field => cf_phone_number)
      else
        render json: {success: false, error: "failed to update custom_field phone_number"}
        return
      end
    end

    priority = Enumeration.find_by name: params[:issue_priority_name], type: "IssuePriority"
    if not priority then
      render json: {success: false, error: "could not find priority named #{params[:issue_priority_name]}"}
      return
    end

    tracker = Tracker.find_by name: params[:issue_tracker_name]
    if not tracker then
      render json: {success: false, error: "could not find tracker named #{params[:issue_tracker_name]}"}
      return
    end

    render json: {success: true, data: {issue_phone_number_custom_field_id: cf_phone_number.id, issue_priority_id: priority.id, issue_tracker_id: tracker.id, }}
  end
end
