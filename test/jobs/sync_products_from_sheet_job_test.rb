require "test_helper"

class SyncProductsFromSheetJobTest < ActiveJob::TestCase
  class FakeSyncFromSheet
    attr_reader :called

    def initialize
      @called = false
    end

    def call
      @called = true

      {
        created: 0,
        updated: 1,
        unchanged: 2,
        deleted: 0,
        errors: 0
      }
    end
  end

  test "calls Products SyncFromSheet service" do
    fake_service = FakeSyncFromSheet.new

    Products::SyncFromSheet.stub(
      :new,
      -> { fake_service }
    ) do
      SyncProductsFromSheetJob.perform_now
    end

    assert fake_service.called
  end
end