module API
  class Base < Grape::API
    format :json
    formatter :json, Grape::Formatter::Jbuilder
    prefix 'api'

    mount API::V1::Base

    add_swagger_documentation mount_path: '/api_docs', api_version: 'v1',
      info: {
        title: "TwilioService API's",
        description: "API's available for TwilioService users"
      }
  end
end
