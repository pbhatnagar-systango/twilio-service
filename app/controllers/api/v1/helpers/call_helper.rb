# module API
#   module V1
#     module Helpers
#       module CallHelper
#         extend Grape::API::Helpers
#
#         def get_participant_ids twilio_conversation_group
#           participant_ids = {advisor_id: nil, student_id: nil}
#           twilio_conversation_group.twilio_group_members.each do |member|
#             participant_ids[:advisor_id] = member.participant_id if member.tag == 'advisor'
#             participant_ids[:student_id] = member.participant_id if member.tag == 'student'
#           end
#           participant_ids
#         end
#
#         def find_call_with_recording_url recording_url
#           TwilioAudioCall.where(recording_url: recording_url).first
#         end
#       end
#     end
#   end
# end
