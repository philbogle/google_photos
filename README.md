# Google photos utilities

These are some quick and dirty utilities to dump metadata for a user's Google Photos and to scan metadata for potential duplicates.
There is also a sinatra web app for viewing the potential duplicates.

Follow these instructions to run the utilities.

## Enable the Drive API

First, you need to enable the Drive API for your app. You can do this in your
app's API project in the [Google developers
   Console](https://console.developers.google.com/project).

1. Create an API project in the [Google developers
   Console](https://console.developers.google.com/project).
2. Select the **Services** tab in your API project, and enable the Drive API.
3. Select the **API Access** tab in your API project, and click **Create an
   OAuth 2.0 client ID**.
4. In the **Branding Information** section, provide a name for your application
   (e.g. "Photo metadata dumper"), and click **Next**.  Providing a product
   logo is optional.
5. In the **Client ID Settings** section, do the following:
      1. Select **Installed application** for the **Application type**
         (or **Web application** for the JavaScript sample).
      2. Select **Other** for the **Installed application type**.
      3. Click **Create Client ID**.
6. In the **API Access** page, locate the section **Client ID for installed
   applications**, and click "Download JSON" and save the file as
   `client_secrets.json` in your home directory.

## Install the Google Client Library

To run the code, you'll need to install the Google API clientlibrary.

    bundle install

## Run the Metadata Dumper

After you have set up your Google API project, installed the Google API client
library, and set up the sample source code, the sample is ready to run.  The
command-line samples provide a link you'll need to visit in order to
authorize the sample.

    bundle exec ruby print_photos_json.rb photos.json_list

1. Browse to the provided URL in your web browser to authorize access to your photos and enter the specified access code.
2. The application will then output the photos metadata as a list of JSON lines to the specified file.

## Run the duplication heuristics

Group photos which have the name, date, location, camera model, and aspect ratio (ignoring rotation),
preferring the photo with the highest resolution.
    ruby dump_dups.rb photos.json_list resize > resizes.json

## View a web page to verify the duplicates are correct
Start the web server
     cd sinatra
     ruby ./server.rb

Go to (e.g.) http://localhost:4567/show/resizes.json and make sure the detected duplicates are valid.  
Since I have only tried these heuristics against my own collection, it's important that you make
sure they work on your correctly as well before going on to the next step.

## Delete the duplicates

    ruby remove_dups.rb resizes.json

