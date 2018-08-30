module API
  module V1
    class Base < API::Base
      helpers API::V1::Helpers::CallHelper

      before do
        if  request.present? && request.env['REQUEST_URI'].present? && !(['voicebase_call_transcript_callback.json', 'audio_call_recording_callback.json', 'call_status_callback.json', 'call_status_callback', 'call_recording_callback.json', 'call_student.xml', 'message_status_callback'].include?(request.env['REQUEST_URI'].split('/').last.split('?').first))
          error!({ success: false, message: 'Invalid authorization key' }, 401) unless authorized
          status 200
        end
      end

      helpers do
        def authorized
          # cm9yX3BsdXM6SERGa2ZSb3JQbHVzNjQ1
          authorization_key = Base64.strict_decode64(request.headers['Authorization']) rescue false
          authorization_key == "#{$secret[:api_client_id]}:#{$secret[:api_client_secret]}"
        end
      end

      version 'v1', using: :header, vendor: 'twilio'
      mount API::V1::AudioCalls
      mount API::V1::VideoCalls
      mount API::V1::Messages
    end
  end
end
