# app/jobs/sync_products_from_sheet_job.rb

class SyncProductsFromSheetJob < ApplicationJob
  queue_as :default

  def perform
    Products::SyncFromSheet.new.call
  end
end