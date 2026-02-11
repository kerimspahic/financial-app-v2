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
user.savings_goals.destroy_all
user.bills.destroy_all
user.transactions.destroy_all
user.budgets.destroy_all
user.accounts.destroy_all
user.account_groups.destroy_all

accounts = {}

account_data = [
  { name: "Main Checking",      account_type: :checking,    balance: 0, currency: "USD", icon_emoji: "🏦", bank_name: "Chase Bank", account_number_masked: "****4521" },
  { name: "High-Yield Savings", account_type: :savings,     balance: 0, currency: "USD", icon_emoji: "💰", bank_name: "Marcus by Goldman Sachs" },
  { name: "Visa Platinum",      account_type: :credit_card, balance: 0, currency: "USD", icon_emoji: "💳", bank_name: "Chase Bank", account_number_masked: "****7890" },
  { name: "Cash Wallet",        account_type: :cash,        balance: 0, currency: "USD", icon_emoji: "👛" },
  { name: "Brokerage Account",  account_type: :investment,  balance: 0, currency: "USD", icon_emoji: "📈", bank_name: "Fidelity Investments", account_number_masked: "****3344" }
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

# ─── Account Groups ──────────────────────────────────────────────────────────

personal_group = user.account_groups.create!(name: "Personal", position: 0)
investing_group = user.account_groups.create!(name: "Investing", position: 1)

accounts[:checking].update!(account_group: personal_group, position: 0, description: "Primary checking account for daily expenses and salary deposits.")
accounts[:savings].update!(account_group: personal_group, position: 1, description: "High-yield savings for emergency fund.", balance_goal: 25_000)
accounts[:credit_card].update!(account_group: personal_group, position: 2, description: "Visa Platinum rewards card. 2% cash back on everything.", credit_limit: 10_000, interest_rate: 19.99)
accounts[:cash].update!(account_group: personal_group, position: 3)
accounts[:investment].update!(account_group: investing_group, position: 0, description: "Diversified brokerage account: ETFs and index funds.", balance_goal: 50_000)

puts "Account groups: #{user.account_groups.count}"

puts "Account balances:"
user.accounts.reload.each do |a|
  puts "  #{a.name} (#{a.account_type}): $#{'%.2f' % a.balance}"
end

# ─── Balance Snapshots ──────────────────────────────────────────────────────
#
# Generate daily snapshots for the last 6 months by computing running balances.

user.accounts.reload.each do |account|
  # Get all transactions for this account sorted by date
  txns = account.transactions.order(:date, :created_at).to_a

  # Start with balance excluding all transactions (base amount)
  income_total = txns.select(&:income?).sum(&:amount)
  expense_total = txns.select(&:expense?).sum(&:amount)
  computed_final = income_total - expense_total
  base_amount = account.balance - computed_final

  # Build snapshots day by day
  running = base_amount
  start_date = 6.months.ago.to_date
  txn_index = 0

  (start_date..Date.current).each do |date|
    # Add transactions that happened on this date
    while txn_index < txns.length && txns[txn_index].date <= date
      t = txns[txn_index]
      running += t.amount if t.income?
      running -= t.amount if t.expense?
      txn_index += 1
    end

    # Record weekly snapshots (every 3 days) to avoid too many rows
    if date == start_date || date == Date.current || date.day % 3 == 0
      AccountBalanceSnapshot.create!(account: account, date: date, balance: running)
    end
  end
end

puts "Balance snapshots: #{AccountBalanceSnapshot.count}"

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

# ─── Table Configurations ───────────────────────────────────────────────────

TableConfig.find_or_create_by!(page_key: "transactions") do |tc|
  tc.columns = [
    { key: "date", label: "Date", default_visible: true, sortable: true },
    { key: "description", label: "Description", default_visible: true, sortable: true },
    { key: "category", label: "Category", default_visible: true, sortable: true, sort_key: "category_name" },
    { key: "account", label: "Account", default_visible: true, sortable: true, sort_key: "account_name" },
    { key: "amount", label: "Amount", default_visible: true, sortable: true },
    { key: "transaction_type", label: "Type", sortable: true },
    { key: "notes", label: "Notes", sortable: true },
    { key: "tags", label: "Tags", sortable: false },
    { key: "clearing_status", label: "Status", default_visible: true, sortable: true },
    { key: "balance", label: "Balance", default_visible: false, sortable: false }
  ]
  tc.search_fields = %w[description notes category_name account_name]
  tc.filters = [
    { key: "transaction_type", type: "enum", label: "Type", enabled: true },
    { key: "account_id", type: "select", label: "Account", enabled: true },
    { key: "category_id", type: "select", label: "Category", enabled: true },
    { key: "date", type: "date_range", label: "Date Range", enabled: true },
    { key: "amount", type: "range", label: "Amount Range", enabled: false }
  ]
end
puts "Table configs: #{TableConfig.count}"

# ─── Tags ────────────────────────────────────────────────────────────────────

user.tags.destroy_all

tags = [
  { name: "Tax Deductible", color: "#10b981" },
  { name: "Business",       color: "#3b82f6" },
  { name: "Vacation",       color: "#f59e0b" },
  { name: "Recurring",      color: "#8b5cf6" },
  { name: "Reimbursable",   color: "#ef4444" },
  { name: "Essential",      color: "#06b6d4" }
].map { |t| user.tags.create!(t) }

# Randomly tag ~30% of transactions
all_txns = user.transactions.to_a
tagged_count = 0
all_txns.sample((all_txns.size * 0.3).to_i).each do |txn|
  txn.tags << tags.sample(rand(1..2))
  tagged_count += 1
end

puts "Tags: #{user.tags.count} (#{tagged_count} transactions tagged)"

# ─── Savings Goals ──────────────────────────────────────────────────────────

user.savings_goals.destroy_all

goals_data = [
  { name: "Emergency Fund",    target_amount: 10_000, color: "#10b981", icon: "🛡️",  account: accounts[:savings], deadline: 6.months.from_now.to_date },
  { name: "Japan Trip",        target_amount: 5_000,  color: "#f59e0b", icon: "✈️",  account: nil,                deadline: 8.months.from_now.to_date },
  { name: "New Laptop",        target_amount: 2_500,  color: "#3b82f6", icon: "💻",  account: nil,                deadline: 4.months.from_now.to_date },
  { name: "Investment Cushion", target_amount: 20_000, color: "#8b5cf6", icon: "📈",  account: accounts[:investment], deadline: 1.year.from_now.to_date }
]

goals_data.each do |gd|
  goal = user.savings_goals.create!(
    name: gd[:name],
    target_amount: gd[:target_amount],
    color: gd[:color],
    icon: gd[:icon],
    account: gd[:account],
    deadline: gd[:deadline]
  )

  # Add historical contributions
  total_contributed = 0
  months_back = rand(3..6)
  months_back.times do |i|
    contrib_date = (months_back - i).months.ago.to_date + rand(1..15)
    amount = (gd[:target_amount] * rand(0.05..0.15)).round(2)
    goal.savings_contributions.create!(
      amount: amount,
      date: contrib_date,
      note: [ "Monthly contribution", "Bonus deposit", "Extra savings", "Auto-transfer" ].sample
    )
    total_contributed += amount
  end
  goal.update_columns(current_amount: total_contributed)
end

puts "Savings goals: #{user.savings_goals.count} (#{SavingsContribution.count} contributions)"

# ─── Categorization Rules ───────────────────────────────────────────────────

user.categorization_rules.destroy_all

rules_data = [
  { pattern: "Starbucks",          match_type: :contains,    category: "Dining Out",       priority: 10 },
  { pattern: "Netflix",            match_type: :exact,       category: "Subscriptions",    priority: 10 },
  { pattern: "Spotify",            match_type: :contains,    category: "Subscriptions",    priority: 10 },
  { pattern: "Uber",               match_type: :starts_with, category: "Transportation",   priority: 8 },
  { pattern: "Lyft",               match_type: :starts_with, category: "Transportation",   priority: 8 },
  { pattern: "Amazon",             match_type: :starts_with, category: "Shopping",         priority: 5 },
  { pattern: "Whole Foods",        match_type: :contains,    category: "Food & Groceries", priority: 9 },
  { pattern: "Gas Station",        match_type: :starts_with, category: "Transportation",   priority: 7 },
  { pattern: "Gym|Fitness|Planet", match_type: :regex,       category: "Healthcare",       priority: 6 },
  { pattern: "Electric|Water|Gas|Internet|Phone", match_type: :regex, category: "Utilities", priority: 7 }
]

rules_data.each do |rd|
  cat = cats[rd[:category]]
  next unless cat

  user.categorization_rules.create!(
    pattern: rd[:pattern],
    match_type: rd[:match_type],
    category: cat,
    priority: rd[:priority]
  )
end

puts "Categorization rules: #{user.categorization_rules.count}"

# ─── Property & Vehicle Accounts ─────────────────────────────────────────────

property_account = user.accounts.create!(
  name: "Primary Residence",
  account_type: :property,
  balance: 425_000,
  currency: "USD",
  icon_emoji: "🏠",
  bank_name: "Wells Fargo Mortgage",
  account_number_masked: "****8812",
  original_loan_amount: 350_000,
  loan_term_months: 360,
  interest_rate: 6.5
)

vehicle_account = user.accounts.create!(
  name: "2022 Honda Civic",
  account_type: :vehicle,
  balance: 22_500,
  currency: "USD",
  icon_emoji: "🚗",
  original_loan_amount: 28_000,
  loan_term_months: 60,
  interest_rate: 4.9
)

# Asset valuations for property (appreciating)
12.times do |i|
  date = (12 - i).months.ago.to_date
  base_value = 400_000 + (i * 2_300) + rand(-500..500)
  property_account.asset_valuations.create!(
    value: base_value,
    date: date,
    source: %w[manual zillow].sample,
    notes: i == 0 ? "Purchase price estimate" : nil
  )
end

# Asset valuations for vehicle (depreciating)
12.times do |i|
  date = (12 - i).months.ago.to_date
  base_value = 26_000 - (i * 300) + rand(-200..200)
  vehicle_account.asset_valuations.create!(
    value: base_value,
    date: date,
    source: %w[manual kbb].sample,
    notes: i == 0 ? "Purchase price" : nil
  )
end

puts "Property/Vehicle accounts: 2 (#{AssetValuation.count} valuations)"

# ─── Holdings (Investment Account) ──────────────────────────────────────────

Holding.where(account: accounts[:investment]).destroy_all

holdings_data = [
  { symbol: "VOO",  name: "Vanguard S&P 500 ETF",        holding_type: "etf",    shares: 25.0,    cost_basis_per_share: 380.50, current_price: 412.75 },
  { symbol: "VTI",  name: "Vanguard Total Market ETF",    holding_type: "etf",    shares: 40.0,    cost_basis_per_share: 215.30, current_price: 238.90 },
  { symbol: "AAPL", name: "Apple Inc.",                    holding_type: "stock",  shares: 15.0,    cost_basis_per_share: 145.00, current_price: 178.50 },
  { symbol: "MSFT", name: "Microsoft Corp.",               holding_type: "stock",  shares: 10.0,    cost_basis_per_share: 280.00, current_price: 415.20 },
  { symbol: "BND",  name: "Vanguard Total Bond Market",   holding_type: "bond",   shares: 50.0,    cost_basis_per_share: 72.50,  current_price: 71.80 }
]

holdings_data.each do |hd|
  accounts[:investment].holdings.create!(hd.merge(last_price_update: Date.current))
end

puts "Holdings: #{Holding.count}"

# ─── Benchmark (S&P 500) ────────────────────────────────────────────────────

Benchmark.destroy_all

monthly_returns = {}
12.times do |i|
  month_key = (12 - i).months.ago.to_date.strftime("%Y-%m")
  monthly_returns[month_key] = (rand(-3.0..4.0)).round(2)
end

Benchmark.create!(name: "S&P 500", monthly_returns: monthly_returns)

puts "Benchmarks: #{Benchmark.count}"

# ─── Bills ───────────────────────────────────────────────────────────────────

user.bills.destroy_all
BillPayment.where(bill_id: user.bills.select(:id)).destroy_all

bills_data = [
  { name: "Rent",          amount: 1850.00, frequency: :monthly,    due_date: Date.current.beginning_of_month + 1, category: cats["Housing"],        account: accounts[:checking],   reminder_days_before: 3 },
  { name: "Electric Bill",  amount: 120.00,  frequency: :monthly,    due_date: Date.current.beginning_of_month + 15, category: cats["Utilities"],     account: accounts[:checking],   reminder_days_before: 5 },
  { name: "Internet",      amount: 65.00,   frequency: :monthly,    due_date: Date.current.beginning_of_month + 10, category: cats["Utilities"],      account: accounts[:checking],   auto_pay: true, reminder_days_before: 2 },
  { name: "Netflix",       amount: 15.99,   frequency: :monthly,    due_date: Date.current.beginning_of_month + 8,  category: cats["Subscriptions"], account: accounts[:credit_card], auto_pay: true, reminder_days_before: 0 },
  { name: "Car Insurance",  amount: 480.00,  frequency: :quarterly,  due_date: Date.current.beginning_of_month + 20, category: cats["Transportation"], account: accounts[:checking],  reminder_days_before: 7 },
  { name: "Gym Membership", amount: 24.99,   frequency: :monthly,    due_date: Date.current.beginning_of_month + 5,  category: cats["Healthcare"],    account: accounts[:credit_card], auto_pay: true, reminder_days_before: 0, website_url: "https://planetfitness.com" }
]

bills_data.each do |bd|
  bill = user.bills.create!(bd)
  # Add some payment history
  2.times do |i|
    paid_date = bd[:due_date] - (i + 1).months
    bill.bill_payments.create!(paid_date: paid_date, amount: bd[:amount])
  end
end

puts "Bills: #{user.bills.count} (#{BillPayment.count} payments)"

# ─── Account Groups for Property/Vehicle ─────────────────────────────────────

assets_group = user.account_groups.find_or_create_by!(name: "Assets") do |g|
  g.position = 2
end
property_account.update!(account_group: assets_group, position: 0)
vehicle_account.update!(account_group: assets_group, position: 1)

puts "Updated account groups for property/vehicle"

puts "\nSeed complete!"
puts "  Login: demo@example.com / password123"
puts "  Accounts: #{user.accounts.count}"
puts "  Categories: #{user.categories.count}"
puts "  Transactions: #{user.transactions.count}"
puts "  Budgets: #{user.budgets.count}"
puts "  Exchange conversions: #{user.exchange_conversions.count}"
puts "  Holdings: #{Holding.count}"
puts "  Bills: #{user.bills.count}"
puts "  Asset Valuations: #{AssetValuation.count}"
