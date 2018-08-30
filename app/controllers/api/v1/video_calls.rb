module API
  module V1
    class VideoCalls < API::V1::Base
      before do
        @twilio_service_object = TwilioConnectionService.new()
        # @ivy_chat_app_object = IvyChatAppService.new()
      end

      resource :video_calls do

        desc "List video calls of particular user.", {
          headers: {
            "Authorization" => {
              description: "Authorization key",
              required: true
            }
          }
        }
        params do
          requires :user_id, type: String, desc: "User is of user for which video calls needs to be listed"
        end
        get '/', jbuilder: 'video_calls/index.json.jbuilder' do
          @user_id = params[:user_id]
          @twilio_conversation_groups = TwilioConversationGroup.joins(:twilio_group_members).where(twilio_group_members: {participant_id: @user_id})
        end

        desc "Create room and generate access token for the caller to join this room.", {
          headers: {
            "Authorization" => {
              description: "Authorization key",
              required: true
            }
          }
        }
        params do
          requires :user_identity, type: String, desc: "User identity for call.E.g : User Email Address"
          requires :user_id, type: Integer, desc: "User ID"
          requires :user_phone_number, type: String, desc: "User phone number"
          requires :call_end_time, type: String, desc: "Call end time"
          requires :user_type, type: String, desc: "if you have different types of user in your system then enter the relevant one, else enter 'Caller'"
          requires :extend_call, type: Boolean, desc: "can extend the call"
        end
        get :initiate_video_call do
          room_name = SecureRandom.hex(4)
          response = @twilio_service_object.create_twilio_video_call_room(room_name, params[:call_end_time], params[:extend_call])
          twilio_room = response[:twilio_resonse]
          token = @twilio_service_object.get_authentication_token(
            room_name , params[:user_identity], params[:user_id], params[:user_type], response[:twilio_session_id], params[:user_phone_number])
          {success: true, room_id: twilio_room.sid, room_name: twilio_room.unique_name, token: token, session_id: response[:twilio_session_id], status: 200}
        end

        desc "Add user to room.", {
          headers: {
            "Authorization" => {
              description: "Authorization key",
              required: true
            }
          }
        }
        params do
          requires :user_identity, type: String, desc: "User identity for call.E.g : User Email Address"
          requires :user_id, type: Integer, desc: "User ID"
          requires :user_type, type: String, desc: "if you have different types of user in your system then enter the relevant one, else enter 'Callee'"
          requires :room_id, type: String, desc: "Id of room in which user needs to be added"
          requires :twilio_session_id, type: Integer, desc: "Id of Session for user to be added"
          requires :user_phone_number, type: String, desc: "User phone number"
        end
        get :add_participant_to_room do
          room = @twilio_service_object.fetch_room(params[:room_id])
          if room.status == 'in-progress'
            token = @twilio_service_object.get_authentication_token(
              room.unique_name , params[:identity], params[:user_id], params[:user_type], params[:twilio_session_id], params[:user_phone_number])
            {success: true, room_id: room.sid, room_name: room.unique_name, token: token, session_id: params[:twilio_session_id], status: 200}
          else
            {success: false, message: 'Room Completed', status: 404}
          end
        end
        desc "call Status Callback.", {
          headers: {}
        }
        post :call_status_callback do
          Rails.logger.info "VIDEO PARAMS=========#{params}"
          if params[:RoomStatus] == "in-progress" && params[:StatusCallbackEvent] == "room-created"
            end_time = params[:call_end_time].to_time
            EndCallNotificationSms.set(wait_until: end_time - 5.minute).perform_later(params[:session_id]) if params[:extend_call] == "true"
            EndVideoCall.set(wait_until: end_time).perform_later(params[:RoomSid], params[:session_id])
          end
          twilio_session = TwilioSession.find_by_id(params[:session_id])
          if twilio_session.present?
            twilio_session.update_attribute('call_status', params[:RoomStatus])
            if params[:RoomStatus] == 'completed'
              Rails.logger.info "ROOM COMPLETED =========#{params}"
              twilio_conversation_group = twilio_session.twilio_conversation_group
              twilio_conversation_group.create_twilio_video_call(room_id: params[:RoomSid], call_duration: params[:RoomDuration])
              # participant_ids = get_participant_ids twilio_conversation_group
              # if participant_ids[:student_id].present? && participant_ids[:advisor_id].present?
              #   @ivy_chat_app_object.update_call_history({
              #     call_stats:{
              #       twilio_session_id: params[:session_id],
              #       advisor_id: participant_ids[:advisor_id],
              #       student_id: participant_ids[:student_id]
              #     }
              #   })
              # end
            end
          end
        end
      end
    end
  end
end
