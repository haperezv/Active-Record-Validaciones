class AddStatusToShoppingCarts < ActiveRecord::Migration[7.0]
  def change
    add_column :shopping_carts, :status, :integer, default: 0
  end
end
