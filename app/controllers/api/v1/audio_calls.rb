module API
  module V1
    class AudioCalls < API::V1::Base
      content_type :xml, 'application/xml'
      content_type :json, 'application/json'

      before do
        @twilio_connection_service_object = TwilioConnectionService.new()
        # @ivy_chat_app_object = IvyChatAppService.new()
      end

      resource :audio_calls do

        desc "List audio calls of particular user.", {
          headers: {
            "Authorization" => {
              description: "Authorization key",
              required: true
            }
          }
        }
        params do
          requires :user_id, type: String, desc: "User is of user for which audio calls needs to be listed"
        end
        get '/', jbuilder: 'audio_calls/index.json.jbuilder' do
          @user_id = params[:user_id]
          @twilio_conversation_groups = TwilioConversationGroup.joins(:twilio_group_members).where(twilio_group_members: {participant_id: @user_id})
        end

        desc "Initiate Audio Call", {
          headers: {
            "Authorization" => {
              description: "Authorization key",
              required: true
            }
          }
        }
        params do
          requires :caller_phone_number, type: String, desc: "Caller Phone number"
          requires :callee_phone_number, type: String, desc: "Callee Phone Number"
          requires :callee_id, type: Integer, desc: "callee ID"
          requires :caller_id, type: Integer, desc: "caller ID"
          requires :call_end_time, type: String, desc: "Call end time"
          requires :extend_call, type: Boolean, desc: "can extend the call"
        end
        post :initiate_audio_call do
          @twilio_connection_service_object.call_callee(
            params[:caller_phone_number],
            params[:callee_phone_number],
            params[:callee_id],
            params[:caller_id],
            params[:call_end_time],
            params[:extend_call]
          )
          { success: true, message: 'Phone call incoming!', status: 200 }
        end

        desc "This is the callback that is recieved from twilio after calle accepts the call, This triggers a call back to caller", {
          headers: {}
        }
        post :call_caller do
          @twilio_connection_service_object.call_caller(
            params[:caller_phone_number],
            params[:callee_phone_number],
            params[:callee_id],
            params[:caller_id],
            params[:call_end_time],
            params[:extend_call]
          )
        end

        desc "Call Status Callback from twilio which updated the stats of the call in the database", {
          headers: {}
        }
        post :call_status_callback do
          Rails.logger.info "===== AUDIO params===#{params}"
          twilio_session = TwilioSession.find_by_id(params[:session_id])
          call_status = params[:CallStatus] == "completed" ? params[:CallStatus] : @twilio_connection_service_object.end_audio_call(params[:CallSid])
          if twilio_session.present?
            twilio_session.update_attribute('call_status',call_status)
            if call_status == "completed"
              twilio_session.twilio_conversation_group.create_twilio_audio_call(
                recording_url: params[:RecordingUrl],
                twilio_call_sid: params[:CallSid],
                call_duration: params[:DialCallDuration]
              )
              # twilio_conversation_group = twilio_session.twilio_conversation_group
              # participant_ids = get_participant_ids twilio_conversation_group
              # @ivy_chat_app_object.update_call_history({
              #   call_stats:{
              #     twilio_session_id: twilio_session.id,
              #     advisor_id: participant_ids[:advisor_id],
              #     student_id: participant_ids[:student_id]
              #   }
              # })
            end
          end
        end

        desc "call transcript callback in which twilio sends the transcript of particular call.", {
          headers: {}
        }
        post :call_transcript_callback do
          response = JSON.parse(params[:AddOns])
          call_transcript = @twilio_connection_service_object.get_call_transcript response
          call = find_call_with_recording_url response["results"]["voicebase_transcription"]["links"]["recording"]
          if call.present?
            call.update_attribute('transcript_data', call_transcript)
          end
        end

        desc "Call recording Callback for twilio which is triggered once the recording is started, in-progress or finished for a call.", {
          headers: {}
        }
        post :audio_call_recording_callback do
          if params[:RecordingStatus] == 'in-progress'
            end_time = params[:call_end_time].to_time
            EndCallNotificationSMS.set(wait_until: end_time - 5.minute).perform_later(params[:session_id]) if params[:extend_call] == "true"
            EndAudioCall.set(wait_until: end_time).perform_later(params[:CallSid], params[:session_id])
          end
        end

        desc "Get Call Transcript.", {
          headers: {
            "Authorization" => {
              description: "Authorization key",
              required: true
            }
          }
        }
        params do
          requires :twilio_session_id, type: Integer, desc: "Twilio Session Id, for which you want the transcript"
        end
        get :get_transcript do
          call = TwilioAudioCall.joins(twilio_conversation_group: :twilio_session).where('twilio_sessions.id = ?', params[:twilio_session_id]).first
          if call.present?
            { success: true, call_transcript: call.transcript_data, status: 200 }
          else
            { success: false, message: 'Record not found for this session id', status: 404 }
          end
        end
      end
    end
  end
end
