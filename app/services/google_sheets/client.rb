require "google/apis/sheets_v4"
require "googleauth"

module GoogleSheets
  class Client
    SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

    CREDENTIALS_PATH = Rails.root.join(
      "config",
      "google_service_account.json"
    )

    def initialize
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.client_options.application_name = "Products Sheet Sync"
      @service.authorization = authorization
    end

    def read(range)
      response = @service.get_spreadsheet_values(
        spreadsheet_id,
        range,
        value_render_option: "UNFORMATTED_VALUE"
      )

      response.values || []
    end

    def batch_update(updates)
      value_ranges = updates.map do |update|
        Google::Apis::SheetsV4::ValueRange.new(
          range: update.fetch(:range),
          values: update.fetch(:values)
        )
      end

      request = Google::Apis::SheetsV4::BatchUpdateValuesRequest.new(
        value_input_option: "RAW",
        data: value_ranges
      )

      @service.batch_update_values(
        spreadsheet_id,
        request
      )
    end

    private

    def authorization
      File.open(CREDENTIALS_PATH) do |file|
        Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: file,
          scope: SCOPE
        )
      end
    end

    def spreadsheet_id
      Rails.application.credentials.dig(
        :google_sheets,
        :spreadsheet_id
      )
    end
  end
end