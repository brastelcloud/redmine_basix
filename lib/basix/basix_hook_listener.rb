module Basix
  class BasixHookListener < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      user = User.current
      return '' unless user && user.logged?

      current_user_id = user.id
      base_uri = Redmine::Utils.relative_url_root
      project = context[:project]
      project_id = project&.id || 'null'
      project_name = project&.name || ''

      # Get issue_id from the URL if on an issue page
      issue_id = 'null'
      if context[:controller].controller_name == 'issues' && context[:controller].action_name == 'show'
        issue_id = context[:request].params[:id] || 'null'
      end

      user_has_role = false
      if project && Setting.plugin_redmine_basix['project_group_member_role'].present?
        user_has_role = user.roles_for_project(project).any? { |role| role.name.downcase == Setting.plugin_redmine_basix['project_group_member_role'].downcase }
      end

      js_template = <<~'JS'
        function showFlashMessage(type, message) {
          var flashDiv = $('<div class="flash ' + type + '"></div>');
          var closeButton = $('<a href="#" class="close">×</a>');
          closeButton.on('click', function(e) {
            e.preventDefault();
            $(this).parent().fadeOut();
          });
          flashDiv.append(closeButton).append(message);

          $('#flash-messages').append(flashDiv);

          setTimeout(function() {
            flashDiv.fadeOut();
          }, 5000);
        }

        $(document).ready(function() {
          var currentUserId = %{current_user_id};
          var baseUri = '%{base_uri}';
          var projectId = %{project_id};
          var projectName = %{project_name};
          var issueId = %{issue_id};
          var userHasProjectGroupMemberRole = %{user_has_role};

          try {
            $('a').each(function() {
              var $this = $(this);
              var href = $this.attr('href');

              if (!href) {
                return;
              }

              var audioRe = /basix\/(voicemail|callrecording)\/.*\.(wav|mp3)/;
              if (href.match(audioRe)) {
                try {
                  $this.replaceWith("<audio controls preload='none'><source src='" + href + "'/></audio>");
                } catch(err) {
                  console.log('Failed when processing audio link: ' + err);
                }
                return;
              }

              var userLinkRegex = new RegExp('^' + baseUri + '/users/(\\d+)$');
              var match = href.match(userLinkRegex);
              if (match) {
                var userId = parseInt(match[1], 10);
                if (userId !== currentUserId) {
                  var title = 'Call ' + $this.text();

                  // if we are in a isssue/ID page, if the current user is not a member, change to call the group
                  if (issueId && !userHasProjectGroupMemberRole) {
                    title = 'Call ' + projectName;
                  }
                  var icon = $('<span class="phone-icon" style="cursor: pointer; color: green !important; font-size: 1.2em;" title="' + title + '" data-user-id="' + userId + '" data-user-name="' + $this.text() + '"> &#9742;</span>');
                  $this.after(icon);
                }
              }
            });
          } catch (err) {
            console.log('Failed when processing links: ' + err);
          }

          $(document).on('click', '.phone-icon', function() {
            var $this = $(this);
            var userName = $this.data('userName');
            var userId = $this.data('userId');
            if (confirm('Do you really want to call ' + userName + '?')) {
              $.ajax({
                url: baseUri + '/basix/call_user',
                type: 'POST',
                data: { caller_user_id: currentUserId, callee_user_id: userId, project_id: projectId, issue_id: issueId },
                success: function(response) {
                  if (response.success) {
                    alert(response.msg);
                  } else {
                    alert('Error: ' + (response.msg || 'Failed to initiate call.'));
                  }
                },
                error: function() {
                  alert('Error communicating with the server.');
                }
              });
            }
          });
        });
      JS

      js = js_template % { current_user_id: current_user_id, base_uri: base_uri, project_id: project_id, project_name: project_name.to_json, issue_id: issue_id, user_has_role: user_has_role }

      "<script type=\"text/javascript\">#{javascript_cdata_section(js)}</script>"
    end
  end
end
