require "test_helper"

class ProductsFilteringTest < ActionDispatch::IntegrationTest
  setup do
    Product.delete_all

    @sheet_mouse = create_product(
      name: "Wireless Mouse Unique",
      price: 750,
      stock: 10,
      category: "Electronics",
      sheet_managed: true
    )

    @local_keyboard = create_product(
      name: "Mechanical Keyboard Unique",
      price: 2_500,
      stock: 5,
      category: "Electronics",
      sheet_managed: false
    )

    @local_book = create_product(
      name: "Ruby Programming Book Unique",
      price: 400,
      stock: 20,
      category: "Books",
      sheet_managed: false
    )
  end

  test "shows all products when no filter is supplied" do
    get products_path

    assert_response :success

    assert_includes response.body, @sheet_mouse.name
    assert_includes response.body, @local_keyboard.name
    assert_includes response.body, @local_book.name
  end

  test "filters products by name without case sensitivity" do
    get products_path, params: {
      name: "wireless mouse"
    }

    assert_response :success

    assert_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_keyboard.name
    refute_includes response.body, @local_book.name
  end

  test "filters products by partial name" do
    get products_path, params: {
      name: "Keyboard"
    }

    assert_response :success

    assert_includes response.body, @local_keyboard.name
    refute_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_book.name
  end

  test "filters products by category" do
    get products_path, params: {
      category: "Books"
    }

    assert_response :success

    assert_includes response.body, @local_book.name
    refute_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_keyboard.name
  end

  test "filters products by minimum price" do
    get products_path, params: {
      min_price: 1_000
    }

    assert_response :success

    assert_includes response.body, @local_keyboard.name
    refute_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_book.name
  end

  test "filters products by maximum price" do
    get products_path, params: {
      max_price: 500
    }

    assert_response :success

    assert_includes response.body, @local_book.name
    refute_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_keyboard.name
  end

  test "filters products by price interval" do
    get products_path, params: {
      min_price: 500,
      max_price: 1_000
    }

    assert_response :success

    assert_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_keyboard.name
    refute_includes response.body, @local_book.name
  end

  test "filters Google Sheets managed products" do
    get products_path, params: {
      sheet_managed: "true"
    }

    assert_response :success

    assert_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_keyboard.name
    refute_includes response.body, @local_book.name
  end

  test "filters local products" do
    get products_path, params: {
      sheet_managed: "false"
    }

    assert_response :success

    refute_includes response.body, @sheet_mouse.name
    assert_includes response.body, @local_keyboard.name
    assert_includes response.body, @local_book.name
  end

  test "combines multiple filters" do
    get products_path, params: {
      name: "mouse",
      category: "Electronics",
      min_price: 500,
      max_price: 1_000,
      sheet_managed: "true"
    }

    assert_response :success

    assert_includes response.body, @sheet_mouse.name
    refute_includes response.body, @local_keyboard.name
    refute_includes response.body, @local_book.name
  end

  test "shows other products from the same category" do
    get product_path(@sheet_mouse)

    assert_response :success

    assert_select ".related-products" do
      assert_select "a",
                    text: /#{Regexp.escape(@local_keyboard.name)}/,
                    minimum: 1

      assert_select "a",
                    text: /#{Regexp.escape(@local_book.name)}/,
                    count: 0

      assert_select "a",
                    text: /#{Regexp.escape(@sheet_mouse.name)}/,
                    count: 0
    end
  end

  test "does not show related products when category is blank" do
    product = create_product(
      name: "No Category Product Unique",
      price: 100,
      stock: 1,
      category: nil,
      sheet_managed: false
    )

    get product_path(product)

    assert_response :success
    assert_select ".related-products", count: 0
  end

  test "limits related products to five" do
    6.times do |index|
      create_product(
        name: "Related Electronics #{index}",
        price: 100 + index,
        stock: 1,
        category: "Electronics",
        sheet_managed: false
      )
    end

    get product_path(@sheet_mouse)

    assert_response :success

    assert_select ".related-products" do
      assert_select ".related-product-card",
                    count: 5
    end
  end

  private

  def create_product(attributes)
    product = Product.new(attributes)

    # Test sırasında gerçek Google Sheet job'ı çalışmasın.
    product.skip_sheet_sync = true
    product.save!

    product
  end
end