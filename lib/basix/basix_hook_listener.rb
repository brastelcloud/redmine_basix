module Basix
  class BasixHookListener < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      user = User.current
      return '' unless user && user.logged?

      controller = context[:controller]
      return '' unless controller.is_a?(IssuesController)
      return '' unless controller.action_name == 'show'

      current_user_id = user.id
      current_user_login = user.login
      current_user_email = user.mail
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

        function showBasixNotification(message) {
          $('#basix-notify-message').text(message);
          $('#basix-notify-modal').show();
        }

        $(document).ready(function() {
          var confirm_modal_html = '<div id="basix-confirm-modal" style="display: none; position: fixed; z-index: 1000; top: 0; left: 0; width: 100%%; height: 100%%; background-color: rgba(0,0,0,0.5);"><div style="position: fixed; top: 50%%; left: 50%%; transform: translate(-50%%, -50%%); background-color: #fff; padding: 20px; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><p id="basix-confirm-message"></p><button id="basix-confirm-yes">Yes</button> <button id="basix-confirm-no">No</button></div></div>';
          var notify_modal_html = '<div id="basix-notify-modal" style="display: none; position: fixed; z-index: 1001; top: 0; left: 0; width: 100%%; height: 100%%; background-color: rgba(0,0,0,0.5);"><div style="position: fixed; top: 50%%; left: 50%%; transform: translate(-50%%, -50%%); background-color: #fff; padding: 20px; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);"><p id="basix-notify-message"></p><button id="basix-notify-ok">OK</button></div></div>';
          $('body').append(confirm_modal_html);
          $('body').append(notify_modal_html);

          $('#basix-notify-ok').on('click', function() {
            $('#basix-notify-modal').hide();
          });

          var currentUserId = %{current_user_id};
          var currentUserLogin = %{current_user_login};
          var currentUserEmail = '%{current_user_email}';
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

          try {
              $('div.string_cf:has(div.label:contains("phone_number")) div.value').each(function() {
                  var $valueDiv = $(this);
                  $valueDiv.css('display', 'inline-block');
                  var phoneNumber = $valueDiv.text().trim();

                  if (phoneNumber && userHasProjectGroupMemberRole) {
                      var title = 'Call ' + phoneNumber;
                      var icon = ' <span class="phone-icon-details" style="cursor: pointer; color: green !important; font-size: 1.2em;" title="' + title + '" data-phone-number="' + phoneNumber + '"> &#9742;</span>';
                      $valueDiv.after(icon);
                  }
              });
          } catch (err) {
              console.log('Failed when processing phone_number: ' + err);
          }


          $(document).on('click', '.phone-icon, .phone-icon-details', function() {
            var $this = $(this);
            var confirmName;
            var data = {};

            var phoneNumber = $this.data('phoneNumber');

            if (phoneNumber) { // This is the new phone icon
              confirmName = phoneNumber;
              data = {
                destination: phoneNumber,
                user_name: currentUserLogin,
                user_email: currentUserEmail,
                group_name: projectName
              };
            } else { // This is the existing user phone icon
              var userName = $this.data('userName');
              var userId = $this.data('userId');

              if (issueId && !userHasProjectGroupMemberRole) {
                // Call project
                confirmName = projectName;
                data = {
                  destination: projectName,
                  user_name: currentUserLogin,
                  user_email: currentUserEmail
                };
              } else {
                // Call user
                confirmName = userName;
                data = {
                  destination: 'user://' + userId,
                  user_name: currentUserLogin,
                  user_email: currentUserEmail,
                  group_name: projectName,
                  project_id: projectId
                };
              }
            }

            // Show custom confirm
            $('#basix-confirm-message').text('Do you really want to call ' + confirmName + '?');
            $('#basix-confirm-modal').show();

            $('#basix-confirm-yes').off('click').on('click', function() {
              $('#basix-confirm-modal').hide();
              $.ajax({
                url: baseUri + '/basix/call_user',
                type: 'POST',
                data: data,
                success: function(response) {
                  if (response.result_code != 0) {
                    showBasixNotification('Error: ' + (response.error.id || 'Failed to initiate call.'));
                  }
                },
                error: function() {
                  showBasixNotification('Error communicating with the server.');
                }
              });
            });

            $('#basix-confirm-no').off('click').on('click', function() {
              $('#basix-confirm-modal').hide();
            });
          });
        });
      JS

      js = js_template % { current_user_id: current_user_id, current_user_login: current_user_login.to_json, current_user_email: current_user_email, base_uri: base_uri, project_id: project_id, project_name: project_name.to_json, issue_id: issue_id, user_has_role: user_has_role }

      "<script type=\"text/javascript\">#{javascript_cdata_section(js)}</script>"
    end
  end
end
