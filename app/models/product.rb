class Product < ApplicationRecord
  before_validation :assign_sync_key, on: :create

  validates :sync_key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

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
end