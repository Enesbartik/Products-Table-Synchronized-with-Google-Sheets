class SheetSyncsController < ApplicationController
  def create
    result = Products::SyncFromSheet.call

    message = [
      "#{result[:created]} created",
      "#{result[:updated]} updated",
      "#{result[:unchanged]} unchanged",
      "#{result[:deleted]} deleted",
      "#{result[:errors]} errors"
    ].join(", ")

    redirect_to products_path,
                notice: "Synchronization completed: #{message}."
  rescue Google::Apis::Error, Errno::ENOENT => error
    redirect_to products_path,
                alert: "Synchronization failed: #{error.message}"
  end
end