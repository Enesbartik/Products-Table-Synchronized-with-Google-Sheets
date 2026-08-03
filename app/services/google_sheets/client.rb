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

    def append_values(range, values)
      value_range = Google::Apis::SheetsV4::ValueRange.new(
        values: values
      )

      @service.append_spreadsheet_value(
        spreadsheet_id,
        range,
        value_range,
        value_input_option: "RAW",
        insert_data_option: "INSERT_ROWS"
      )
    end

    def update_values(range, values)
      value_range = Google::Apis::SheetsV4::ValueRange.new(
        values: values
      )

      @service.update_spreadsheet_value(
        spreadsheet_id,
        range,
        value_range,
        value_input_option: "RAW"
      )
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

    def delete_row(worksheet_name, row_number)
      worksheet_id = find_worksheet_id(worksheet_name)

      dimension_range = Google::Apis::SheetsV4::DimensionRange.new(
        sheet_id: worksheet_id,
        dimension: "ROWS",
        start_index: row_number - 1,
        end_index: row_number
      )

      delete_request = Google::Apis::SheetsV4::DeleteDimensionRequest.new(
        range: dimension_range
      )

      request = Google::Apis::SheetsV4::Request.new(
        delete_dimension: delete_request
      )

      batch_request =
        Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
          requests: [request]
        )

      @service.batch_update_spreadsheet(
        spreadsheet_id,
        batch_request
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

    def find_worksheet_id(worksheet_name)
      spreadsheet = @service.get_spreadsheet(
        spreadsheet_id,
        fields: "sheets.properties"
      )

      worksheet = spreadsheet.sheets.find do |sheet|
        sheet.properties.title == worksheet_name
      end

      raise ArgumentError, "Worksheet not found: #{worksheet_name}" if worksheet.nil?

      worksheet.properties.sheet_id
    end
  end
end