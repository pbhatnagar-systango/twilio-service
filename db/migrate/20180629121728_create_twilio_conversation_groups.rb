class CreateTwilioConversationGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :twilio_conversation_groups do |t|

      t.timestamps
    end
  end
end
