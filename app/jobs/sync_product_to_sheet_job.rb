class SyncProductToSheetJob < ApplicationJob
  queue_as :default

  def perform(action:, sync_key:, product_id: nil)
    service = Products::SyncToSheet.new

    case action
    when "upsert"
      product = Product.find_by(id: product_id)

      return if product.nil?

      service.upsert(product)
    when "delete"
      service.delete(sync_key)
    else
      raise ArgumentError, "Unknown sheet sync action: #{action}"
    end
  end
end