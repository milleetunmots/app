namespace :parent do
  desc 'Add book delivery location to parents'
  task add_book_delivery_location: :environment do
    Parent.where(book_delivery_location: nil).find_each do |parent|
      parent.update_column(:book_delivery_location, 'home')
    end
  end
end
