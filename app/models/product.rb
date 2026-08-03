class Product < ApplicationRecord
  SHEET_SYNC_ATTRIBUTES = %w[
    name
    price
    stock
    category
  ].freeze

  attr_accessor :skip_sheet_sync

  before_validation :assign_sync_key, on: :create

  after_save_commit :enqueue_sheet_upsert,
                    if: :should_sync_to_sheet?

  after_destroy_commit :enqueue_sheet_delete,
                       unless: :skip_sheet_sync

  validates :sync_key,
            presence: true,
            uniqueness: true

  validates :name,
            presence: true

  validates :price,
            presence: true,
            numericality: {
              greater_than_or_equal_to: 0
            }

  validates :stock,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  private

  def assign_sync_key
    self.sync_key = SecureRandom.uuid if sync_key.blank?
  end

  def should_sync_to_sheet?
    return false if skip_sheet_sync

    newly_created = previous_changes.key?("id")

    product_data_changed =
      previous_changes.keys.intersect?(
        SHEET_SYNC_ATTRIBUTES
      )

    newly_created || product_data_changed
  end

  def enqueue_sheet_upsert
    SyncProductToSheetJob.perform_later(
      action: "upsert",
      product_id: id,
      sync_key: sync_key
    )
  end

  def enqueue_sheet_delete
    SyncProductToSheetJob.perform_later(
      action: "delete",
      sync_key: sync_key
    )
  end
end