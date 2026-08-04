class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]

def index
  @products = Product.all

  if params[:name].present?
    safe_name = Product.sanitize_sql_like(params[:name].strip.downcase)

    @products = @products.where(
      "LOWER(name) LIKE ?",
      "%#{safe_name}%"
    )
  end

  if params[:category].present?
    @products = @products.where(
      category: params[:category]
    )
  end

  case params[:sheet_managed]
  when "true"
    @products = @products.where(sheet_managed: true)
  when "false"
    @products = @products.where(sheet_managed: false)
  end

  if params[:min_price].present?
    @products = @products.where(
      "price >= ?",
      params[:min_price]
    )
  end

  if params[:max_price].present?
    @products = @products.where(
      "price <= ?",
      params[:max_price]
    )
  end

  @products = @products.order(created_at: :desc)

  @categories = Product
    .where.not(category: [nil, ""])
    .distinct
    .order(:category)
    .pluck(:category)
end

 def show
  if @product.category.present?
    @related_products = Product
      .where(category: @product.category)
      .where.not(id: @product.id)
      .order(created_at: :desc)
      .limit(5)
  else
    @related_products = Product.none
  end
end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy!

    redirect_to products_path,
                notice: "Product was successfully deleted.",
                status: :see_other
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.expect(product: %i[name price stock category])
  end
end