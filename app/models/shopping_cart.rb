# == Schema Information
#
# Table name: shopping_carts
#
#  id         :bigint           not null, primary key
#  total      :integer          default(0)
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  active     :boolean          default(FALSE)
#
class ShoppingCart < ApplicationRecord

  include  AASM

  belongs_to :user
  has_many :shopping_cart_products
  has_many :products, through: :shopping_cart_products

  enum status: [:created, :canceled, :payed, :completed]

  aasm column: 'status' do
    state :created, initial: true
    state :canceled
    state :payed
    state :completed

    before_all_transactions :before_transaction
    after_all_transactions  :after_transaction

    event :cancel do
      before_transaction :before_cancel
      after_transaction :after_cancel

      transitions from: :created, to: :canceled
    end

    event :pay do
      transitions from: :created, to: :payed
    end
    
    event :completed do
      transitions from: :payed, to: :completed
    end
    
  end

  def price
    self.total / 100
  end

  def update_total!
    self.update(total: self.get_total)
  end

  def payed!
    ActiveRecord::Base.transaction do
      self.update!(status: :payed)
      self.products.select('products.id, products.title, products.stock, products.price,  products.code, shopping_cart_products.quantity').each do |product|
        
        quantity = ShoppingCartProduct.find_by(shopping_cart_id:self.id, product_id:product.id).quantity

        product.with_lock do
          sleep(30.seconds)
          product.update!(stock: product.stock - quantity)
        end   
      end
    end
  end
    

  def get_total
    Product.joins(:shopping_cart_products)
    .where(shopping_cart_products: {shopping_cart_id: self.id})
    .select('SUM(products.price * shopping_cart_products.quantity) AS t')[0].t
  end

  #Obtener todos los titulos de los productos que no esten dentro del carrito de compras
  def get_title

    Product.joins('LEFT JOIN 
            shopping_cart_products ON products.id = 
            shopping_cart_products.product_id')
            .where(shopping_cart_products: { id: nil })
            .each do |product|
              puts product.title
            end
  end

  private

  def before_cancel
    puts "\n\n\n La compra sera cancelada!"
  end

  def after_cancel
    puts "\n\n\n La compra ha sido cancelada!"
  end 

  def before_transaction
    puts "\n\n\n Un cambio se realizará para el status del carrito de compras"
  end

  def after_transaction
    puts "\n\n\n Un cambio se realizo para el status del carrito de compras"
  end

end