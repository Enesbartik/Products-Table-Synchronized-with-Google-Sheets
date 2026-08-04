require "test_helper"

class ProductSheetSyncCallbacksTest < ActiveJob::TestCase
  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "enqueues upsert job after product creation" do
    product = nil

    assert_enqueued_jobs 1,
                         only: SyncProductToSheetJob do
      product = Product.create!(
        name: "Callback Create Test",
        price: 100,
        stock: 5,
        category: "Test"
      )
    end

    payload = last_job_payload

    assert_equal "upsert", payload["action"]
    assert_equal product.id, payload["product_id"]
    assert_equal product.sync_key, payload["sync_key"]
  end

  test "enqueues upsert job after product data update" do
    product = create_without_sync(
      name: "Callback Update Test",
      price: 100
    )

    assert_enqueued_jobs 1,
                         only: SyncProductToSheetJob do
      product.update!(price: 250)
    end

    payload = last_job_payload

    assert_equal "upsert", payload["action"]
    assert_equal product.id, payload["product_id"]
    assert_equal product.sync_key, payload["sync_key"]
  end

  test "enqueues job when product name changes" do
    product = create_without_sync(
      name: "Old Product Name"
    )

    assert_enqueued_jobs 1,
                         only: SyncProductToSheetJob do
      product.update!(name: "New Product Name")
    end
  end

  test "enqueues job when stock changes" do
    product = create_without_sync(stock: 4)

    assert_enqueued_jobs 1,
                         only: SyncProductToSheetJob do
      product.update!(stock: 0)
    end
  end

  test "enqueues job when category changes" do
    product = create_without_sync(
      category: "Old Category"
    )

    assert_enqueued_jobs 1,
                         only: SyncProductToSheetJob do
      product.update!(category: "New Category")
    end
  end

  test "does not enqueue job when only last synced time changes" do
    product = create_without_sync

    assert_no_enqueued_jobs do
      product.update!(
        last_synced_at: Time.current
      )
    end
  end

  test "skip sheet sync prevents update job" do
    product = create_without_sync(price: 100)
    product.skip_sheet_sync = true

    assert_no_enqueued_jobs do
      product.update!(price: 200)
    end
  end

  test "skip sheet sync prevents create job" do
    product = Product.new(
      name: "Skipped Create Product",
      price: 100,
      stock: 1,
      category: "Test"
    )

    product.skip_sheet_sync = true

    assert_no_enqueued_jobs do
      product.save!
    end
  end

  test "enqueues delete job after product destruction" do
    product = create_without_sync
    sync_key = product.sync_key

    assert_enqueued_jobs 1,
                         only: SyncProductToSheetJob do
      product.destroy!
    end

    payload = last_job_payload

    assert_equal "delete", payload["action"]
    assert_equal sync_key, payload["sync_key"]
  end

  test "skip sheet sync prevents delete job" do
    product = create_without_sync
    product.skip_sheet_sync = true

    assert_no_enqueued_jobs do
      product.destroy!
    end
  end

  private

  def create_without_sync(attributes = {})
    product = Product.new(
      {
        name: "Callback Test Product",
        price: 500,
        stock: 10,
        category: "Test"
      }.merge(attributes)
    )

    product.skip_sheet_sync = true
    product.save!

    # Sonraki update ve destroy işlemlerinde
    # callback yeniden kullanılabilsin.
    product.skip_sheet_sync = false

    product
  end

  def last_job_payload
    raw_payload = enqueued_jobs.last
                               .fetch(:args)
                               .first

    raw_payload.stringify_keys
  end
end