require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product is saved" do
    product = Product.new(
      name: "Keyboard",
      price: 1500,
      stock: 10,
      category: "Electronics"
    )

    assert product.valid?
    assert product.sync_key.present?
  end

  test "name is required" do
    product = Product.new(
      price: 1500,
      stock: 10
    )

    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "price cannot be negative" do
    product = Product.new(
      name: "Keyboard",
      price: -1,
      stock: 10
    )

    assert_not product.valid?
    assert product.errors[:price].any?
  end

  test "stock cannot be negative" do
    product = Product.new(
      name: "Keyboard",
      price: 1500,
      stock: -1
    )

    assert_not product.valid?
    assert product.errors[:stock].any?
  end

  test "stock must be an integer" do
    product = Product.new(
      name: "Keyboard",
      price: 1500,
      stock: 2.5
    )

    assert_not product.valid?
    assert product.errors[:stock].any?
  end

  test "sync key must be unique" do
    first_product = Product.create!(
      name: "Keyboard",
      price: 1500,
      stock: 10
    )

    second_product = Product.new(
      sync_key: first_product.sync_key,
      name: "Mouse",
      price: 500,
      stock: 20
    )

    assert_not second_product.valid?
    assert_includes second_product.errors[:sync_key], "has already been taken"
  end
end