# Helper functions for doing Drive OAuth2 authentication and returning
# a drive client.
#
# Derived from https://github.com/google/google-api-ruby-client-samples/tree/master/drive
#
# Copyright (C) 2012 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/drive_v3'
require 'fileutils'
require 'logger'

module Drive

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

  # Handles authentication and loading of the API.
  def Drive.setup(application_name, application_version)
    log_file = File.open('drive.log', 'a+')
    log_file.sync = true
    logger = Logger.new(log_file)
    logger.level = Logger::DEBUG

    FileUtils.mkdir_p(File.dirname(Drive.token_store_path))

    client = Google::Apis::DriveV3::DriveService.new
    client.authorization = Drive.user_credentials_for([
      Google::Apis::DriveV3::AUTH_DRIVE,
      Google::Apis::DriveV3::AUTH_DRIVE_PHOTOS_READONLY
    ])
    client.request_options.retries = 3
    client
  end


  # Returns the path to the client_secrets.json file.
  def Drive.client_secrets_path
    return ENV['GOOGLE_CLIENT_SECRETS'] if ENV.has_key?('GOOGLE_CLIENT_SECRETS')
    return well_known_path_for('client_secrets.json')
  end

  # Returns the path to the token store.
  def Drive.token_store_path
    return ENV['GOOGLE_CREDENTIAL_STORE'] if ENV.has_key?('GOOGLE_CREDENTIAL_STORE')
    return well_known_path_for('photos-credentials.yaml')
  end

  # Builds a path to a file in $HOME/.config/google (or %APPDATA%/google,
  # on Windows)
  def Drive.well_known_path_for(file)
    if OS.windows?
      File.join(ENV['APPDATA'], 'google', file)
    else
      File.join(ENV['HOME'], '.config', 'google', file)
    end
  end


  # Returns user credentials for the given scope. Requests authorization
  # if requrired.
  def Drive.user_credentials_for(scope)
    FileUtils.mkdir_p(File.dirname(token_store_path))

    if ENV['GOOGLE_CLIENT_ID']
      client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
    else
      client_id = Google::Auth::ClientId.from_file(client_secrets_path)
    end
    token_store = Google::Auth::Stores::FileTokenStore.new(:file => token_store_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

    user_id = 'default'

    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in your browser and authorize the application."
      puts url
      puts "Enter the authorization code:"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

end
