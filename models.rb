class Sheet
  include DataMapper::Resource

  property :id,      Serial
  property :name,    String
  property :address, String

  property :units,   Integer, :required => true
  property :paid,    Float, :default => 0.0
  property :paid_confirmed, Float, :default => 0.0

  property :payout_address, String
  property :payout_amount,  Float, :default => 0.0
  property :payouted?,      Boolean, :default => false

  has n, :tickets

  def price
    (0.3 * self.units).round(8)
  end

  def paid?
    if self.paid_confirmed >= self.price
      true
    else
      false
    end
  end

  before :create do
    name = ((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(32).join

    self.name = name
  end
end

class Ticket
  include DataMapper::Resource

  property :id,      Serial
  property :number,  Integer
  property :message, String

  belongs_to :sheet

  before :create do
    number = ""

    loop do
      # BUG: Strangely, save fails when number starts from a '0'
      number = (1..9).to_a.sample(1).join + (0..9).to_a.sample(5).join

      print "Ticket ##{number} generated: "

      if !self.class.first(:number => number)
        puts "valid."
        break
      else
        puts "invalid (already exists), will regenerate number"
      end
    end

    self.number = number
  end
end
