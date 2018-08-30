class TwilioConnectionService
  def initialize(sid = $secret[:twilio][:sid], token = $secret[:twilio][:auth_token] , api_key = $secret[:twilio][:api_key], api_secret_key = $secret[:twilio][:api_secret_key], caller_id =  $secret[:twilio][:caller_id])
    @api_secret_key = api_secret_key
    @sid = sid
    @token = token
    @api_key = api_key
    @caller_id = caller_id
  end

  def create_twilio_video_call_room unique_room_name, call_end_time, extend_call
    create_video_call_room twilio_object, unique_room_name, call_end_time, extend_call
  end

  def get_authentication_token unique_room_name, identity, user_id, user_type, twilio_session_id, user_phone_number
    generate_token(unique_room_name, identity, user_id, user_type, twilio_session_id, user_phone_number)
  end

  def call_callee caller_phone_number, callee_phone_number, callee_id, caller_id, call_end_time, extend_call
    make_call_to_callee(caller_phone_number,callee_phone_number,callee_id,caller_id, call_end_time, extend_call)
  end

  def call_caller caller_phone_number, callee_phone_number, callee_id, caller_id, call_end_time, extend_call
    make_call_to_caller(
      caller_phone_number,
      callee_phone_number,
      callee_id,
      caller_id,
      call_end_time,
      extend_call
    )
  end

  def end_audio_call call_sid
    end_ongoing_audio_call call_sid
    call = fetch_call call_sid
    call.status
  end

  def end_video_call room_sid
    end_ongoing_video_call room_sid
  end

  def fetch_room room_id
    fetch_twilio_room(twilio_object, room_id)
  end

  def get_call_transcript response
    get_transcript response
  end

  def send_message message, phone_number
    phone_number = '+' + phone_number.strip
    send_message message, phone_number
  end

  private

    def twilio_object
      Twilio::REST::Client.new @sid, @token
    end

    def add_video_grant_to_token unique_name, token
      grant = Twilio::JWT::AccessToken::VideoGrant.new
      grant.room = unique_name
      token.add_grant(grant)
      token.to_jwt
    end

    def generate_token unique_room_name, identity, user_id, user_type, twilio_session_id, user_phone_number
      video_grant = Twilio::JWT::AccessToken::VideoGrant.new
      video_grant.room = unique_room_name
      token = Twilio::JWT::AccessToken.new(
        @sid,
        @api_key,
        @api_secret_key,
        [video_grant],
        identity: identity
      )
      add_participant_to_group_members(user_id, user_type, twilio_session_id, user_phone_number)
      token.to_jwt
    end

    def add_participant_to_group_members user_id, user_type, twilio_session_id, user_phone_number
      twilio_session = TwilioSession.find_by_id twilio_session_id
      phone_number = '+' + user_phone_number.strip
      if twilio_session.present?
        twilio_session.twilio_conversation_group.twilio_group_members.create(
          participant_id: user_id,
          tag: user_type,
          phone_number: phone_number
        )
      end
    end

    def fetch_twilio_room twilio_object, room_id
      twilio_object.video.rooms(room_id).fetch
    end

    def build_twilio_group_and_session call_type, call_status
      twilio_conversation_group = TwilioConversationGroup.new
      if twilio_conversation_group.save
        twilio_session = twilio_conversation_group.build_twilio_session(call_type: call_type, call_status: call_status)
      end
      twilio_session
    end

    def create_video_call_room twilio_object, unique_room_name, call_end_time, extend_call
      twilio_session = build_twilio_group_and_session('video', 'initiating call')
      if twilio_session.save
        params = 'session_id=' + twilio_session.id.to_s + '&call_end_time=' + call_end_time.split(" ").join("_") + "&extend_call=" + extend_call.to_s
        response = twilio_object.video.rooms.create(
                    unique_name: unique_room_name,
                    enable_turn: false,
                    record_participants_on_connect: true,
                    status_callback: $secret[:base_url] + $secret[:twilio][:video_call_status_callback_api] + '?' + params
                  )
        twilio_session.update_attribute('call_status', response.status) if (response.status == 'in-progress')
        {twilio_resonse: response, twilio_session_id: twilio_session.id}
      end
    end

    def make_call_to_callee caller_phone_number, callee_phone_number, callee_id, caller_id, call_end_time, extend_call
      params = "caller_phone_number=" + (caller_phone_number.strip) + "&callee_phone_number=" + (callee_phone_number.strip) + "&caller_id=" + caller_id.to_s + "&callee_id=" + callee_id.to_s + "&call_end_time=" + call_end_time.split(" ").join("_") + "&extend_call=" + extend_call.to_s
      twilio_object.calls.create(
        url: $secret[:base_url] + $secret[:twilio][:call_caller_api] + "?" + params,
        to: callee_phone_number,
        from: @caller_id
      )
    end

    def make_call_to_caller caller_phone_number, callee_phone_number, callee_id, caller_id, call_end_time, extend_call
      twilio_session = build_twilio_group_and_session('audio', 'initiating call')
      if twilio_session.save
        add_participant_to_group_members callee_id, 'callee', twilio_session.id, callee_phone_number
        add_participant_to_group_members caller_id, 'caller', twilio_session.id, caller_phone_number
        params = 'session_id=' + twilio_session.id.to_s + '&call_end_time=' + call_end_time + '&extend_call=' + extend_call
        Twilio::TwiML::VoiceResponse.new do |r|
          r.say('Connecting to caller.', voice: 'alice')
          r.dial(
            caller_id: @caller_id,
            action: $secret[:base_url] + $secret[:twilio][:audio_call_status_callback_api] + '?' + params,
            record: 'record-from-answer-dual',
            recording_status_callback: $secret[:base_url] + $secret[:twilio][:audio_call_recording_callback_api] + '?' + params,
            recording_status_callback_event: 'in-progress',
          ) do |dial|
            dial.number(caller_phone_number)
          end
          r.record(
            transcribe: true
          )
        end
      end
    end

    def end_ongoing_audio_call call_sid
      twilio_object.calls(call_sid).update(status: 'completed')
    end

    def end_ongoing_video_call room_sid
      twilio_object.video.rooms(room_sid).update(status: 'completed')
    end

    def fetch_call call_sid
      twilio_object.calls(call_sid).fetch
    end

    def get_transcript response
      payload = response["results"]["voicebase_transcription"]["payload"].first
      if payload.present?
        transcript_response = HTTParty.get(payload["url"], { basic_auth: { username: @sid, password: @token} })
        transcript_response["media"]["transcripts"]["text"]
      end
    end

    def send_message message, phone_number
      twilio_response = twilio_object.messages.create(
                          body: message,
                          from: @caller_id,
                          to: phone_number,
                        )
      if twilio_response.error_code == 0
        {success: true, message: 'Message Sent', status: 200 }
      else
        {success: false, message: twilio_resonse.error_message, error_code: twilio_resonse.error_code, status: 500 }
      end
    end
end
