# Create a demo user
user = User.find_or_initialize_by(email: "demo@example.com")
if user.new_record?
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Demo"
  user.last_name = "User"
  user.save!
  puts "Created demo user: demo@example.com / password123"
end

# Create accounts
checking = user.accounts.find_or_create_by!(name: "Main Checking") do |a|
  a.account_type = :checking
  a.balance = 5_250.00
end

savings = user.accounts.find_or_create_by!(name: "Savings") do |a|
  a.account_type = :savings
  a.balance = 12_800.00
end

credit_card = user.accounts.find_or_create_by!(name: "Credit Card") do |a|
  a.account_type = :credit_card
  a.balance = -1_340.00
end

puts "Created #{user.accounts.count} accounts"

# Create some sample transactions for this month
if user.transactions.empty?
  salary_cat = user.categories.find_by(name: "Salary")
  food_cat = user.categories.find_by(name: "Food & Groceries")
  housing_cat = user.categories.find_by(name: "Housing")
  transport_cat = user.categories.find_by(name: "Transportation")
  entertainment_cat = user.categories.find_by(name: "Entertainment")
  dining_cat = user.categories.find_by(name: "Dining Out")
  utilities_cat = user.categories.find_by(name: "Utilities")

  transactions = [
    { description: "Monthly Salary", amount: 5_000, transaction_type: :income, date: Date.current.beginning_of_month + 1, account: checking, category: salary_cat },
    { description: "Rent Payment", amount: 1_500, transaction_type: :expense, date: Date.current.beginning_of_month + 2, account: checking, category: housing_cat },
    { description: "Grocery Store", amount: 145.50, transaction_type: :expense, date: Date.current - 5, account: credit_card, category: food_cat },
    { description: "Gas Station", amount: 55.00, transaction_type: :expense, date: Date.current - 4, account: credit_card, category: transport_cat },
    { description: "Movie Tickets", amount: 32.00, transaction_type: :expense, date: Date.current - 3, account: credit_card, category: entertainment_cat },
    { description: "Restaurant", amount: 78.50, transaction_type: :expense, date: Date.current - 2, account: credit_card, category: dining_cat },
    { description: "Electric Bill", amount: 120.00, transaction_type: :expense, date: Date.current - 1, account: checking, category: utilities_cat },
    { description: "Grocery Store", amount: 89.25, transaction_type: :expense, date: Date.current, account: credit_card, category: food_cat },
  ]

  transactions.each do |t|
    user.transactions.create!(t)
  end

  puts "Created #{user.transactions.count} transactions"
end

# Create budgets for current month
if user.budgets.empty?
  budget_categories = {
    "Food & Groceries" => 500,
    "Housing" => 1_500,
    "Transportation" => 200,
    "Entertainment" => 150,
    "Dining Out" => 200,
    "Utilities" => 250,
    "Shopping" => 300,
  }

  budget_categories.each do |cat_name, amount|
    category = user.categories.find_by(name: cat_name)
    user.budgets.create!(
      category: category,
      amount: amount,
      month: Date.current.month,
      year: Date.current.year
    )
  end

  puts "Created #{user.budgets.count} budgets"
end
