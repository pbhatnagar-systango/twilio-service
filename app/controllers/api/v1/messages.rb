module API
    module V1
      class Messages < API::V1::Base

        before do
          @twilio_connection_service_object = TwilioConnectionService.new()
        end

        resource :messages do

          desc "Send message to users.", {
            headers: {
              "Authorization" => {
                description: "Authorization key",
                required: true
              }
            }
          }
          params do
            requires :message, type: String, desc: "The message that needs to be send"
            requires :phone_number, type: String, desc: "The reciepient's phone number"
          end
          post :send_message do
            @twilio_connection_service_object.send_message params[:message], params[:phone_number]
          end
        end
      end
    end
  end
