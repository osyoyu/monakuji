class Lottery
  include DataMapper::Resource

  property :id, Serial
  property :name, String

  # has n, :sheets
end

class Sheet
  include DataMapper::Resource

  property :id,      Serial
  property :name,    String
  property :address, String
  property :price,   Float, :default => 0.0
  property :paid,    Float, :default => 0.0
  property :paid_confirmed, Float, :default => 0.0
  property :payout_address, String
  property :payout,  Float, :default => 0.0
  property :payouted, Boolean, :default => false

  # property :p,   Boolean, :default => false

  # belongs_to :lottery
  has n, :tickets

  def paid?
    if self.paid_confirmed >= self.price
      true
    else
      false
    end
  end
end

class Ticket
  include DataMapper::Resource

  property :id,     Serial
  property :number, Integer
  property :message, String

  belongs_to :sheet
end
