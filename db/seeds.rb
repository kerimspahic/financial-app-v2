# frozen_string_literal: true

puts "Seeding database..."

# ─── Roles & Permissions ─────────────────────────────────────────────────────

admin_role = Role.find_or_create_by!(name: "admin") do |r|
  r.description = "Full system access. Can manage users, roles, and all settings."
end

user_role = Role.find_or_create_by!(name: "user") do |r|
  r.description = "Standard user access. Can manage their own financial data."
end

user_role.permissions = Permission.all
puts "Roles: #{Role.count} | Permissions assigned to 'user' role: #{user_role.permissions.count}"

# ─── Demo User ────────────────────────────────────────────────────────────────

user = User.find_or_initialize_by(email: "demo@example.com")
if user.new_record?
  user.password = "password123"
  user.password_confirmation = "password123"
  user.first_name = "Demo"
  user.last_name = "User"
  user.save!
  puts "Created demo user: demo@example.com / password123"
else
  puts "Demo user already exists"
end

user.roles << admin_role unless user.has_role?("admin")
user.roles << user_role unless user.has_role?("user")

# ─── Accounts ─────────────────────────────────────────────────────────────────

# Clear existing financial data for a clean seed
user.transactions.destroy_all
user.budgets.destroy_all
user.accounts.destroy_all

accounts = {}

account_data = [
  { name: "Main Checking",      account_type: :checking,    balance: 0, currency: "USD" },
  { name: "High-Yield Savings", account_type: :savings,     balance: 0, currency: "USD" },
  { name: "Visa Platinum",      account_type: :credit_card, balance: 0, currency: "USD" },
  { name: "Cash Wallet",        account_type: :cash,        balance: 0, currency: "USD" },
  { name: "Brokerage Account",  account_type: :investment,  balance: 0, currency: "USD" }
]

account_data.each do |data|
  acc = user.accounts.create!(data)
  accounts[data[:account_type]] = acc
end

puts "Accounts: #{user.accounts.count}"

# ─── Categories (auto-created by User callback) ──────────────────────────────

cats = user.categories.index_by(&:name)
puts "Categories: #{cats.count}"

# ─── Transactions ─────────────────────────────────────────────────────────────
#
# Generate 9 months of realistic transactions (current month + 8 prior months).
# Account balances are computed from the sum of all transactions at the end.

today = Date.current
transactions_data = []

9.times do |months_ago|
  month_start = (today - months_ago.months).beginning_of_month
  month_end   = [ (today - months_ago.months).end_of_month, today ].min

  # ── Income ──

  # Salary: 1st of each month
  pay_date = month_start + 1
  pay_date = month_end if pay_date > month_end
  transactions_data << {
    description: "Monthly Salary - Acme Corp",
    amount: 6500.00,
    transaction_type: :income,
    date: pay_date,
    account: accounts[:checking],
    category: cats["Salary"]
  }

  # Freelance: 2 gigs per month
  freelance_clients = %w[Johnson Smith Williams Brown Davis Wilson Taylor Anderson Martinez Garcia]
  freelance_types = [ "Web Design", "Logo Design", "SEO Audit", "App Prototype", "Consulting" ]
  rand(1..3).times do |i|
    fl_date = month_start + (i * 10) + rand(1..5)
    next if fl_date > month_end

    transactions_data << {
      description: "Freelance #{freelance_types.sample} - #{freelance_clients.sample} Co",
      amount: [ 400, 650, 800, 950, 1200, 1500, 1800 ].sample.to_f,
      transaction_type: :income,
      date: fl_date,
      account: accounts[:checking],
      category: cats["Freelance"]
    }
  end

  # Investment dividends: end of month
  div_date = month_start + 27
  if div_date <= month_end
    transactions_data << {
      description: [ "Quarterly Dividend - Vanguard ETF", "Dividend - S&P 500 Index", "Interest - Bond Fund" ].sample,
      amount: rand(80..200).to_f + rand(0.0..0.99).round(2),
      transaction_type: :income,
      date: div_date,
      account: accounts[:investment],
      category: cats["Investments"]
    }
  end

  # Other income (occasional)
  if rand < 0.3
    oi_date = month_start + rand(10..25)
    unless oi_date > month_end
      transactions_data << {
        description: [ "Cash Back Reward", "Sold Old Furniture", "Tax Refund", "Birthday Gift", "Rebate Check" ].sample,
        amount: rand(25..300).to_f + rand(0.0..0.99).round(2),
        transaction_type: :income,
        date: oi_date,
        account: accounts[:checking],
        category: cats["Other Income"]
      }
    end
  end

  # ── Housing ──

  rent_date = month_start + 1
  rent_date = month_end if rent_date > month_end
  transactions_data << {
    description: "Rent Payment - Apartment 4B",
    amount: 1850.00,
    transaction_type: :expense,
    date: rent_date,
    account: accounts[:checking],
    category: cats["Housing"]
  }

  # Renters insurance (quarterly)
  if months_ago % 3 == 0
    ins_date = month_start + 15
    unless ins_date > month_end
      transactions_data << {
        description: "Renters Insurance - StateFarm",
        amount: 95.00,
        transaction_type: :expense,
        date: ins_date,
        account: accounts[:checking],
        category: cats["Housing"]
      }
    end
  end

  # ── Utilities ──

  [
    { desc: "Electric Bill - City Power", amt_range: 75..160 },
    { desc: "Internet - Fiber Plus", amt_range: 65..65 },
    { desc: "Water & Sewer", amt_range: 30..60 },
    { desc: "Natural Gas - WarmCo", amt_range: 35..95 },
    { desc: "Cell Phone - T-Mobile", amt_range: 85..85 },
    { desc: "Trash Collection", amt_range: 25..25 }
  ].each_with_index do |util, idx|
    util_date = month_start + 4 + idx
    next if util_date > month_end

    transactions_data << {
      description: util[:desc],
      amount: rand(util[:amt_range]).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: util_date,
      account: accounts[:checking],
      category: cats["Utilities"]
    }
  end

  # ── Food & Groceries (6-8 trips per month) ──

  grocery_stores = [
    "Whole Foods Market", "Trader Joe's", "Kroger", "Safeway", "Costco Wholesale",
    "Aldi", "Publix", "Wegmans", "Sprouts Farmers Market", "Harris Teeter"
  ]
  rand(6..8).times do |i|
    grocery_date = month_start + (i * 3) + rand(1..3)
    next if grocery_date > month_end

    transactions_data << {
      description: grocery_stores.sample,
      amount: rand(35..210).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: grocery_date,
      account: [ accounts[:credit_card], accounts[:checking] ].sample,
      category: cats["Food & Groceries"]
    }
  end

  # ── Dining Out (8-14 times per month) ──

  restaurants = [
    "Olive Garden", "Chipotle", "Thai Orchid", "Burger Joint", "Sushi Palace",
    "Pizza Express", "La Trattoria", "Taco Bell", "Panera Bread", "Five Guys",
    "Panda Express", "Starbucks", "Dunkin' Donuts", "Chick-fil-A", "Subway",
    "Buffalo Wild Wings", "Red Lobster", "Denny's", "IHOP", "Wingstop"
  ]
  rand(8..14).times do
    dine_date = month_start + rand(1..28)
    next if dine_date > month_end

    transactions_data << {
      description: restaurants.sample,
      amount: rand(8..85).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: dine_date,
      account: [ accounts[:credit_card], accounts[:cash] ].sample,
      category: cats["Dining Out"]
    }
  end

  # ── Transportation (6-10 per month) ──

  transport_items = [
    { desc: "Gas Station - Shell", amt: 40..70 },
    { desc: "Gas Station - BP", amt: 38..62 },
    { desc: "Gas Station - Chevron", amt: 42..68 },
    { desc: "Uber Ride", amt: 8..45 },
    { desc: "Lyft Ride", amt: 10..40 },
    { desc: "Metro Card Reload", amt: 50..50 },
    { desc: "Parking Garage", amt: 10..30 },
    { desc: "Parking Meter", amt: 3..8 },
    { desc: "Car Wash - Splash Clean", amt: 12..25 },
    { desc: "EZ-Pass Toll", amt: 5..15 }
  ]
  rand(6..10).times do
    t_date = month_start + rand(1..28)
    next if t_date > month_end

    item = transport_items.sample
    transactions_data << {
      description: item[:desc],
      amount: rand(item[:amt]).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: t_date,
      account: [ accounts[:checking], accounts[:credit_card], accounts[:cash] ].sample,
      category: cats["Transportation"]
    }
  end

  # ── Entertainment (4-8 per month) ──

  entertainment_items = [
    { desc: "Movie Theater - AMC", amt: 12..35 },
    { desc: "Concert Tickets - Live Nation", amt: 45..150 },
    { desc: "Bowling Night", amt: 20..45 },
    { desc: "Video Game - Steam", amt: 10..70 },
    { desc: "Museum Admission", amt: 12..30 },
    { desc: "Mini Golf", amt: 10..22 },
    { desc: "Escape Room", amt: 25..40 },
    { desc: "Laser Tag", amt: 15..30 },
    { desc: "Arcade - Dave & Buster's", amt: 20..55 },
    { desc: "Streaming Rental - Apple TV", amt: 4..7 },
    { desc: "Book Purchase - Barnes & Noble", amt: 10..25 },
    { desc: "Comedy Show", amt: 20..45 },
    { desc: "Zoo Admission", amt: 15..30 },
    { desc: "Trampoline Park", amt: 18..35 }
  ]
  rand(4..8).times do
    e_date = month_start + rand(1..28)
    next if e_date > month_end

    item = entertainment_items.sample
    transactions_data << {
      description: item[:desc],
      amount: rand(item[:amt]).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: e_date,
      account: accounts[:credit_card],
      category: cats["Entertainment"]
    }
  end

  # ── Shopping (5-10 per month) ──

  shopping_items = [
    { desc: "Amazon Order", amt: 15..180 },
    { desc: "Target", amt: 20..110 },
    { desc: "Clothing - H&M", amt: 25..90 },
    { desc: "Clothing - Zara", amt: 30..120 },
    { desc: "Home Depot - Hardware", amt: 10..100 },
    { desc: "Best Buy - Electronics", amt: 20..250 },
    { desc: "IKEA - Home Furnishings", amt: 30..175 },
    { desc: "Walmart", amt: 15..85 },
    { desc: "Dollar Tree", amt: 5..20 },
    { desc: "TJ Maxx", amt: 15..65 },
    { desc: "Nike Store", amt: 40..150 },
    { desc: "Pet Store - PetSmart", amt: 15..60 },
    { desc: "Bath & Body Works", amt: 12..45 },
    { desc: "Office Supplies - Staples", amt: 10..55 }
  ]
  rand(5..10).times do
    s_date = month_start + rand(1..28)
    next if s_date > month_end

    item = shopping_items.sample
    transactions_data << {
      description: item[:desc],
      amount: rand(item[:amt]).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: s_date,
      account: accounts[:credit_card],
      category: cats["Shopping"]
    }
  end

  # ── Healthcare (1-3 per month) ──

  healthcare_items = [
    "Dr. Smith - Copay", "CVS Pharmacy", "Lab Work - Quest Diagnostics",
    "Dental Checkup", "Eye Exam - LensCrafters", "Urgent Care Visit",
    "Walgreens Pharmacy", "Physical Therapy", "Dermatology Copay",
    "Vitamins & Supplements"
  ]
  rand(1..3).times do
    h_date = month_start + rand(3..27)
    next if h_date > month_end

    transactions_data << {
      description: healthcare_items.sample,
      amount: rand(10..175).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: h_date,
      account: accounts[:credit_card],
      category: cats["Healthcare"]
    }
  end

  # ── Subscriptions ──

  subscriptions = [
    { desc: "Netflix", amt: 15.99 },
    { desc: "Spotify Premium", amt: 10.99 },
    { desc: "iCloud Storage", amt: 2.99 },
    { desc: "Adobe Creative Cloud", amt: 54.99 },
    { desc: "ChatGPT Plus", amt: 20.00 },
    { desc: "Gym Membership - Planet Fitness", amt: 24.99 },
    { desc: "YouTube Premium", amt: 13.99 },
    { desc: "Disney+", amt: 7.99 },
    { desc: "Hulu", amt: 17.99 },
    { desc: "New York Times Digital", amt: 4.25 }
  ]
  subscriptions.each_with_index do |sub, idx|
    sub_date = month_start + idx + 8
    next if sub_date > month_end

    transactions_data << {
      description: sub[:desc],
      amount: sub[:amt],
      transaction_type: :expense,
      date: sub_date,
      account: accounts[:credit_card],
      category: cats["Subscriptions"]
    }
  end

  # ── Education (1-2 per month) ──

  education_items = [
    "Udemy Course", "O'Reilly Subscription", "Textbook - Amazon",
    "Online Workshop", "Skillshare Membership", "Coursera Course",
    "LinkedIn Learning", "Codecademy Pro"
  ]
  rand(1..2).times do
    ed_date = month_start + rand(5..25)
    next if ed_date > month_end

    transactions_data << {
      description: education_items.sample,
      amount: rand(10..65).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: ed_date,
      account: accounts[:credit_card],
      category: cats["Education"]
    }
  end

  # ── Cash spending (5-8 per month) ──

  cash_items = [
    "Coffee Shop", "Street Food", "Farmer's Market", "Tip - Barber",
    "Vending Machine", "Food Truck", "Newsstand", "Laundromat",
    "Tip - Delivery", "Garage Sale Find", "Lemonade Stand", "Parking Meter"
  ]
  rand(5..8).times do
    c_date = month_start + rand(1..28)
    next if c_date > month_end

    transactions_data << {
      description: cash_items.sample,
      amount: rand(2..30).to_f + rand(0.0..0.99).round(2),
      transaction_type: :expense,
      date: c_date,
      account: accounts[:cash],
      category: [ cats["Food & Groceries"], cats["Dining Out"], cats["Entertainment"] ].sample
    }
  end

  # ── Savings transfer ──

  if month_start + 5 <= month_end
    transactions_data << {
      description: "Monthly Savings Transfer",
      amount: [ 500, 750, 1000 ].sample.to_f,
      transaction_type: :income,
      date: month_start + 5,
      account: accounts[:savings],
      category: cats["Other Income"]
    }
  end
end

# Create all transactions
transactions_data.each { |t| user.transactions.create!(t) }
puts "Transactions: #{user.transactions.count}"

# ─── Recompute Account Balances ───────────────────────────────────────────────
#
# Seeds bypass BalanceUpdatable concern, so compute balances from transaction sums.

accounts.each_value do |account|
  income  = account.transactions.income.sum(:amount)
  expense = account.transactions.expense.sum(:amount)
  account.update_columns(balance: income - expense)
end

# Add base amounts to simulate prior history
accounts[:investment].update_columns(balance: accounts[:investment].balance + 15_000)
accounts[:savings].update_columns(balance: accounts[:savings].balance + 8_000)
accounts[:cash].update_columns(balance: accounts[:cash].balance + 200)

puts "Account balances:"
user.accounts.reload.each do |a|
  puts "  #{a.name} (#{a.account_type}): $#{'%.2f' % a.balance}"
end

# ─── Budgets ──────────────────────────────────────────────────────────────────

budget_data = {
  "Food & Groceries" => 600,
  "Housing"          => 1900,
  "Transportation"   => 250,
  "Entertainment"    => 200,
  "Dining Out"       => 300,
  "Utilities"        => 350,
  "Shopping"         => 400,
  "Healthcare"       => 200,
  "Subscriptions"    => 150,
  "Education"        => 100
}

# Current month + last 8 months of budgets
9.times do |months_ago|
  target = today - months_ago.months
  budget_data.each do |cat_name, amount|
    category = cats[cat_name]
    next unless category

    user.budgets.create!(
      category: category,
      amount: months_ago == 0 ? amount : (amount * rand(0.85..1.15)).round,
      month: target.month,
      year: target.year
    )
  end
end

puts "Budgets: #{user.budgets.count} (9 months)"

# ─── Exchange Conversions (sample history) ───────────────────────────────────

user.exchange_conversions.destroy_all

[
  { from_currency: "USD", to_currency: "EUR", from_amount: 1000, to_amount: 847.89, exchange_rate: 0.84789, converted_at: 1.day.ago },
  { from_currency: "USD", to_currency: "GBP", from_amount: 500, to_amount: 367.94, exchange_rate: 0.73588, converted_at: 3.days.ago },
  { from_currency: "EUR", to_currency: "JPY", from_amount: 200, to_amount: 37012.40, exchange_rate: 185.062, converted_at: 1.week.ago },
  { from_currency: "GBP", to_currency: "USD", from_amount: 750, to_amount: 1019.12, exchange_rate: 1.35883, converted_at: 2.weeks.ago },
  { from_currency: "USD", to_currency: "CAD", from_amount: 2000, to_amount: 2760.40, exchange_rate: 1.38020, converted_at: 3.weeks.ago },
  { from_currency: "EUR", to_currency: "CHF", from_amount: 1500, to_amount: 1410.75, exchange_rate: 0.94050, converted_at: 1.month.ago },
  { from_currency: "USD", to_currency: "JPY", from_amount: 3000, to_amount: 471270.00, exchange_rate: 157.09, converted_at: 5.weeks.ago },
  { from_currency: "AUD", to_currency: "USD", from_amount: 1200, to_amount: 792.36, exchange_rate: 0.66030, converted_at: 6.weeks.ago }
].each { |c| user.exchange_conversions.create!(c) }

puts "Exchange conversions: #{user.exchange_conversions.count}"

puts "\nSeed complete!"
puts "  Login: demo@example.com / password123"
puts "  Accounts: #{user.accounts.count}"
puts "  Categories: #{user.categories.count}"
puts "  Transactions: #{user.transactions.count}"
puts "  Budgets: #{user.budgets.count}"
puts "  Exchange conversions: #{user.exchange_conversions.count}"
