require "test_helper"

class SyncProductToSheetJobTest < ActiveJob::TestCase
  class FakeSyncToSheet
    attr_reader :upserted_product,
                :deleted_sync_key

    def upsert(product)
      @upserted_product = product
      :updated
    end

    def delete(sync_key)
      @deleted_sync_key = sync_key
      true
    end
  end

  setup do
    @product = Product.new(
      name: "Job Test Product",
      price: 500,
      stock: 10,
      category: "Test"
    )

    @product.skip_sheet_sync = true
    @product.save!
  end

  test "upserts existing product to sheet" do
    fake_service = FakeSyncToSheet.new

    Products::SyncToSheet.stub :new, fake_service do
      SyncProductToSheetJob.perform_now(
        action: "upsert",
        product_id: @product.id,
        sync_key: @product.sync_key
      )
    end

    assert_equal @product.id,
                 fake_service.upserted_product.id
  end

  test "does nothing when upsert product does not exist" do
    fake_service = FakeSyncToSheet.new

    Products::SyncToSheet.stub :new, fake_service do
      SyncProductToSheetJob.perform_now(
        action: "upsert",
        product_id: -1,
        sync_key: "missing-sync-key"
      )
    end

    assert_nil fake_service.upserted_product
  end

  test "deletes product from sheet using sync key" do
    fake_service = FakeSyncToSheet.new

    Products::SyncToSheet.stub :new, fake_service do
      SyncProductToSheetJob.perform_now(
        action: "delete",
        sync_key: @product.sync_key
      )
    end

    assert_equal @product.sync_key,
                 fake_service.deleted_sync_key
  end

  test "raises error for unknown action" do
    fake_service = FakeSyncToSheet.new

    assert_raises ArgumentError do
      Products::SyncToSheet.stub :new, fake_service do
        SyncProductToSheetJob.perform_now(
          action: "unknown",
          sync_key: @product.sync_key
        )
      end
    end
  end
end