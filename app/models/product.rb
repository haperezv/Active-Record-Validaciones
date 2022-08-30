# == Schema Information
#
# Table name: products
#
#  id         :bigint           not null, primary key
#  title      :string
#  code       :string
#  stock      :integer          default(0)
#  price      :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Product < ApplicationRecord

    has_many :shopping_cart_products
        
    #save

    before_create :validate_product
    after_create :send_notification
    after_create :push_notification, if: :discount?

    validates :title, presence: {message: "El nombre del producto es requerido"}
    validates :code, presence: {message: "Es necesario definir un valor para el código"}

    validates :code, uniqueness: {message: "El código ya existe"}
    #validates :price, length: {minimum: 3, maximum: 10}
    validates :price, length: {in: 3..10, message: "El precio se encuentra fuera de rango (3-10)"}, if: :has_price?

    validate :code_validate
    validates_with ProductValidator

    scope :available, ->(min=1) { where('stock >= ?', min) }
    scope :order_price_desc, -> { order('price desc') }

    scope :available_and_order_price_desc, -> { available.order_price_desc }

    def total
        self.price / 100
    end

    def total_format
        "$#{self.total}.00 USD"
    end

    def discount?
        self.total < 5
    end

    def has_price?
        !self.price.nil? && self.price > 0
    end

    def self.top_5_available
        self.available.order_price_desc.limit(5).select(:title, :code)
    end

    private

    def code_validate
        if self.code.nil? || self.code.length < 3
            self.errors.add(:code, "El código debe tener 3 caracteres")
        end 
    end

    def validate_product
        puts "\n\n\n>>> Un nuevo producto será añadidto almacen!"
    end

    def send_notification
        puts "\n\n\n>>> Un nuevo producto fue añadido almacen: #{self.title} - $#{self.total} USD" 
    end

    #precio < 5 usd

    def push_notification

        puts "\n\n\n>>> Un nuevo producto en descuento ya se encuentra disponible: #{self.title}" 
    end
end
