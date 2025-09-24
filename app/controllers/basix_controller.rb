require 'net/http'
require 'uri'
require 'base64'
require 'json'

class BasixController < ApplicationController
  unloadable

  before_action :require_admin, except: [:call_user]
  skip_before_action :verify_authenticity_token, only: [:call_user]
  accept_api_auth :configure_integration

  def call_user
    settings = Setting.plugin_redmine_basix
    api_uri = settings['api_uri']

    if api_uri.blank?
      render json: { success: false, msg: "API URI is not configured in the plugin settings." }
      return
    end

    begin
      caller = User.find(params[:caller_user_id])
      callee = User.find(params[:callee_user_id])
      project = Project.find(params[:project_id]) if params[:project_id].present? && params[:project_id] != 'null'
      issue = Issue.find(params[:issue_id]) if params[:issue_id].present? && params[:issue_id] != 'null'
    rescue ActiveRecord::RecordNotFound => e
      render json: { success: false, msg: "Could not find user, project, or issue: #{e.message}" }
      return
    end

    # Determine destination based on new rules
    destination = nil
    cf_phone = CustomField.find_by(name: 'phone_number') # Assuming 'phone_number' custom field exists

    if cf_phone
      if issue && issue.custom_value_for(cf_phone).present? && issue.custom_value_for(cf_phone).value.present?
        destination = issue.custom_value_for(cf_phone).value
      elsif callee.custom_value_for(cf_phone).present? && callee.custom_value_for(cf_phone).value.present?
        destination = callee.custom_value_for(cf_phone).value
      end
    end

    destination ||= callee.login # Fallback to callee.login if no custom field value found

    # Check project membership (only if project is present)
    caller_is_member = project.present? && caller.projects.include?(project)
    callee_is_member = project.present? && callee.projects.include?(project)

    payload = {
      user_name: caller.login,
      destination: destination
    }

    if project.present? && caller_is_member && !callee_is_member
      payload[:group_name] = project.name
    end

    begin
      uri = URI.parse(api_uri + '/call_user')
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        if Rails.env.development?
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
      
      api_domain = settings['api_domain']
      api_token = settings['api_token']
      auth = Base64.strict_encode64("#{api_domain}:#{api_token}")
      request['Authorization'] = "Basic #{auth}"
      
      request.body = payload.to_json
      
      response = http.request(request)

      # Return the response from the external API to the frontend
      render json: response.body
    rescue => e
      render json: { success: false, msg: "An error occurred while making the API call: #{e.message}" }
    end
  end

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
      render json: {success: false, error: "could not find tracker named #{params[:issue_priority_name]}"}
      return
    end

    render json: {success: true, data: {issue_phone_number_custom_field_id: cf_phone_number.id, issue_priority_id: priority.id, issue_tracker_id: tracker.id, }}
  end
end
