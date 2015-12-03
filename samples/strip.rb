
module StripePayment

  CURRENCY = "usd"
  PLAN = 'basic'

  def customer_card(stripe_id)
    stripe_customer_card(stripe_customer_data(stripe_id))
  end

  def stripe_rental(user, token, video)
    customer_id = stripe_customer_id(user, token)
    charge = stripe_charge(customer_id, video.stripe_rental_price, rental_charge_description(video))
  end

  def subscription(user, token)
    stripe = stripe_subscriber(user, token)
    subscription = Subscription.new(stripe_info(stripe).merge({user: user}))
    subscription.save!
  end

  def update_customer_card(user, token)
    unless user.stripe_id.nil?
      customer = stripe_customer_data(user.stripe_id)
      customer.source = token
      save_stripe_customer(customer)
    else
      create_stripe_customer(user, token)
    end
  end

  private

  def create_stripe_customer(user, token)
    customer = Stripe::Customer.create(
      email: user.email,
      card: token
    )
    user.stripe_id = customer.id
    user.save!
  end

  def rental_charge_description(video)
    "Ver on Demand Rental: #{video.title}"
  end

  def save_stripe_customer(customer)
    customer.save
  end

  def stripe_charge(stripe_id, amount, description)
    Stripe::Charge.create(
      customer: stripe_id,
      amount: amount,
      description: description,
      currency: CURRENCY
    )
  end

  def stripe_customer_card(stripe_customer)
    stripe_customer.sources.data.first
  end

  def stripe_customer_data(stripe_id)
    Stripe::Customer.retrieve(stripe_id)
  end

  def stripe_customer_id(user, token)
    create_stripe_customer(user, token) if user.stripe_id.nil?
    return user.stripe_id
  end

  def stripe_info(stripe)
  	# need date , active_until: stripe.created
  	{stripe_id: stripe.id, plan: PLAN }
  end

  def stripe_subscriber(user, token)
  	Stripe::Customer.create(
      source: token,
      plan: PLAN,
      email: user.email
    )
  end
end
