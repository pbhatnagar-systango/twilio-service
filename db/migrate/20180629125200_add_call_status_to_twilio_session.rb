class AddCallStatusToTwilioSession < ActiveRecord::Migration[5.2]
  def change
    add_column :twilio_sessions, :call_status, :string
  end
end
