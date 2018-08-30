class AddCallExtendedToTwilioSession < ActiveRecord::Migration[5.2]
  def change
    add_column :twilio_sessions, :call_extended, :boolean,default: false
  end
end
