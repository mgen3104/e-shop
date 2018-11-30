require 'Kconv'
class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy, :pay]

  # GET /products
  # GET /products.json
  def index
    @products = Product.all
  end

  # GET /products/1
  # GET /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)
    image = product_params[:imageobject]
    image_name = image.original_filename
    @product.image= image.original_filename
    result = uploadimg(image,image_name)

    respond_to do |format|
      if result=="success" && @product.save
        format.html { redirect_to @product, notice: '商品が登録されました。' }
        format.json { render :show, status: :created, location: @product }
      else
        deleteimg(image_name)
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to products_url, notice: '商品情報を更新しました。' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: '商品を削除しました。' }
      format.json { head :no_content }
    end
  end

  def pay
    Payjp.api_key = 'sk_test_c62fade9d045b54cd76d7036'
    charge = Payjp::Charge.create(
      :amount => @product.price,
      :card => params['payjp-token'],
      :currency => 'jpy',
    )
    @product[:stock] = @product[:stock] - 1
    @product.save
    redirect_to products_url, notice: 'ありがとうございました。'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:name, :price, :stock, :note, :imageobject)
    end

    def uploadimg(img_object,image_name)
      ext = image_name[image_name.rindex('.') + 1, 4].downcase
      perms = ['.jpg', '.jpeg', '.gif', '.png']
      if !perms.include?(File.extname(image_name).downcase)
        result = 'アップロードできるのは画像ファイルのみです。'
      elsif img_object.size > 4.megabyte
        result = 'ファイルサイズは4MBまでです。'
      else
        File.open("public/#{image_name.toutf8}", 'wb') { |f| f.write(img_object.read) }
        result = "success"
      end
      return result
    end

    def deleteimg(image_name)
      File.unlink "public/"+image_name.toutf8
    end
end
