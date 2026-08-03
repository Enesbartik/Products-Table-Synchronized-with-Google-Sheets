module Products
  class SyncToSheet
    def initialize(
      client: GoogleSheets::Client.new,
      worksheet_name: Rails.application.credentials.dig(
        :google_sheets,
        :worksheet_name
      )
    )
      @client = client
      @worksheet_name = worksheet_name
    end

    def upsert(product)
      synced_at = Time.current

      values = [[
        product.sync_key,
        product.name,
        product.price.to_f,
        product.stock,
        product.category,
        "Synced",
        "",
        synced_at.iso8601
      ]]

      row_number = find_row_number(product.sync_key)

      if row_number
        @client.update_values(
          "#{@worksheet_name}!A#{row_number}:H#{row_number}",
          values
        )
      else
        @client.append_values(
          "#{@worksheet_name}!A:H",
          values
        )
      end

      product.update_columns(
        sheet_managed: true,
        last_synced_at: synced_at
      )

      row_number ? :updated : :created
    end

    def delete(sync_key)
      row_number = find_row_number(sync_key)

      return false if row_number.nil?

      @client.delete_row(
        @worksheet_name,
        row_number
      )

      true
    end

    private

    def find_row_number(sync_key)
      rows = @client.read(
        "#{@worksheet_name}!A2:A"
      )

      index = rows.index do |row|
        row.first.to_s == sync_key.to_s
      end

      index ? index + 2 : nil
    end
  end
end