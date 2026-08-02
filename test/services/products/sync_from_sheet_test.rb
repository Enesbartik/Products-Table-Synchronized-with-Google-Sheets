require "test_helper"

class Products::SyncFromSheetTest < ActiveSupport::TestCase
  class FakeGoogleSheetsClient
    attr_accessor :rows
    attr_reader :updates, :last_read_range

    def initialize(rows:)
      @rows = rows
      @updates = []
    end

    def read(range)
      @last_read_range = range
      rows
    end

    def batch_update(updates)
      @updates.concat(updates)
    end
  end

  test "creates a product from a new sheet row" do
    client = FakeGoogleSheetsClient.new(
      rows: [
        ["", "Sheet Keyboard Test", 1500, 10, "Electronics"]
      ]
    )

    assert_difference("Product.count", 1) do
      result = sync_with(client)

      assert_equal 1, result[:created]
      assert_equal 0, result[:errors]
    end

    product = Product.find_by!(name: "Sheet Keyboard Test")

    assert product.sync_key.present?
    assert_equal 1500, product.price
    assert_equal 10, product.stock
    assert product.sheet_managed?
    assert product.last_synced_at.present?

    assert_equal "Products!A2:H", client.last_read_range

    assert client.updates.any? { |update|
      update[:range] == "Products!A2" &&
        update[:values] == [[product.sync_key]]
    }

    assert client.updates.any? { |update|
      update[:range] == "Products!F2:H2" &&
        update[:values].first.first == "Synced"
    }
  end

  test "updates an existing product" do
    product = Product.create!(
      sync_key: "existing-sheet-product",
      name: "Old Product Name",
      price: 100,
      stock: 5,
      category: "Old Category",
      sheet_managed: true
    )

    client = FakeGoogleSheetsClient.new(
      rows: [
        [
          product.sync_key,
          "Updated Product Name",
          250,
          15,
          "New Category"
        ]
      ]
    )

    result = sync_with(client)

    product.reload

    assert_equal 0, result[:created]
    assert_equal 1, result[:updated]
    assert_equal "Updated Product Name", product.name
    assert_equal 250, product.price
    assert_equal 15, product.stock
    assert_equal "New Category", product.category
  end

  test "does not duplicate an unchanged product" do
    product = Product.create!(
      sync_key: "unchanged-sheet-product",
      name: "Unchanged Product",
      price: 400,
      stock: 8,
      category: "Accessories",
      sheet_managed: true
    )

    client = FakeGoogleSheetsClient.new(
      rows: [
        [
          product.sync_key,
          product.name,
          product.price,
          product.stock,
          product.category
        ]
      ]
    )

    assert_no_difference("Product.count") do
      result = sync_with(client)

      assert_equal 0, result[:created]
      assert_equal 0, result[:updated]
      assert_equal 1, result[:unchanged]
    end
  end

  test "does not save an invalid row and writes the error to the sheet" do
    client = FakeGoogleSheetsClient.new(
      rows: [
        ["", "", -50, 5, "Invalid Test Category"]
      ]
    )

    assert_no_difference("Product.count") do
      result = sync_with(client)

      assert_equal 1, result[:errors]
    end

    assert_not Product.exists?(category: "Invalid Test Category")

    error_update = client.updates.find do |update|
      update[:range] == "Products!F2:H2"
    end

    assert_not_nil error_update
    assert_equal "Error", error_update[:values].first[0]
    assert_includes error_update[:values].first[1], "Name can't be blank"
    assert_includes error_update[:values].first[1], "Price must be greater than or equal to 0"
  end

  test "deletes sheet managed products missing from the sheet" do
    sheet_product = Product.create!(
      sync_key: "deleted-sheet-product",
      name: "Deleted Sheet Product",
      price: 100,
      stock: 2,
      sheet_managed: true
    )

    client = FakeGoogleSheetsClient.new(rows: [])

    result = sync_with(client)

    assert_equal 1, result[:deleted]
    assert_not Product.exists?(sheet_product.id)
  end

  test "does not delete products created locally in Rails" do
    local_product = Product.create!(
      sync_key: "local-rails-product",
      name: "Local Rails Product",
      price: 300,
      stock: 4,
      sheet_managed: false
    )

    client = FakeGoogleSheetsClient.new(rows: [])

    result = sync_with(client)

    assert_equal 0, result[:deleted]
    assert Product.exists?(local_product.id)
  end

  private

  def sync_with(client)
    Products::SyncFromSheet.new(
      client: client,
      worksheet_name: "Products"
    ).call
  end
end