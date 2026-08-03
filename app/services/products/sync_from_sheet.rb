module Products
  class SyncFromSheet
    SYNCED_ATTRIBUTES = %w[name price stock category].freeze

    def self.call
      new.call
    end

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

    def call
      result = {
        created: 0,
        updated: 0,
        unchanged: 0,
        deleted: 0,
        errors: 0
      }

      seen_sync_keys = []

      rows.each_with_index do |row, index|
        row_number = index + 2

        sync_key = sync_row(row, row_number, result)
        seen_sync_keys << sync_key if sync_key.present?
      end

      delete_missing_products(seen_sync_keys, result)

      result
    end

    private

    def rows
      @client.read("#{@worksheet_name}!A2:H")
    end

    def sync_row(row, row_number, result)
      sync_key, name, price, stock, category = row

      return if [sync_key, name, price, stock, category].all?(&:blank?)

      product =
        if sync_key.present?
          Product.find_or_initialize_by(sync_key: sync_key)
        else
          Product.new
        end

      product.skip_sheet_sync = true  
      new_record = product.new_record?

      product.assign_attributes(
        name: name,
        price: price,
        stock: stock,
        category: category,
        sheet_managed: true
      )

      product_data_changed =
        product.changes_to_save.keys.intersect?(SYNCED_ATTRIBUTES)

      product.last_synced_at = Time.current

      if product.save
        if new_record
          result[:created] += 1
        elsif product_data_changed
          result[:updated] += 1
        else
          result[:unchanged] += 1
        end

        write_success(row_number, product)
      else
        result[:errors] += 1
        write_error(row_number, product)
      end

      product.sync_key
    end

    def delete_missing_products(seen_sync_keys, result)
  products_to_delete = Product.where(sheet_managed: true)

  if seen_sync_keys.any?
    products_to_delete =
      products_to_delete.where.not(
        sync_key: seen_sync_keys
      )
  end

  products_to_delete.find_each do |product|
    product.skip_sheet_sync = true
    product.destroy!

    result[:deleted] += 1
  end
end

    def write_success(row_number, product)
      @client.batch_update(
        [
          {
            range: "#{@worksheet_name}!A#{row_number}",
            values: [[product.sync_key]]
          },
          {
            range: "#{@worksheet_name}!F#{row_number}:H#{row_number}",
            values: [[
              "Synced",
              "",
              product.last_synced_at.iso8601
            ]]
          }
        ]
      )
    end

    def write_error(row_number, product)
      @client.batch_update(
        [
          {
            range: "#{@worksheet_name}!A#{row_number}",
            values: [[product.sync_key]]
          },
          {
            range: "#{@worksheet_name}!F#{row_number}:H#{row_number}",
            values: [[
              "Error",
              product.errors.full_messages.join(", "),
              ""
            ]]
          }
        ]
      )
    end
  end
end