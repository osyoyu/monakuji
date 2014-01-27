# coding: utf-8

require 'optparse'
require 'data_mapper'
require './models.rb'

require './monacoin_rpc.rb'
wallet = MonacoinRPC.new('http://monacoinrpc:E3P7qnDmbLsmvLTp7cyyLwJ4d1PZsr9WrVTBkBxR34jZ@127.0.0.1:10010')

opt = OptionParser.new
options = Hash.new

opt.on('--dry-run') do
  options['dry-run'] = true
end

opt.parse!(ARGV)

ticket_count = 0
total_sales = 0

Sheet.all.each do |sheet|
  if sheet.paid?
    total_sales += sheet.price
    ticket_count += sheet.tickets.length 
  end
end

first_prize = (total_sales.round(8) * 0.25).round
first_prize = 100 if first_prize > 100

second_count = (ticket_count.to_f / 50).round
second_count = 1 if second_count == 0
second_prize = (((total_sales - first_prize - (0.3 * ticket_count / 10) - total_sales * 0.2)) / second_count).round

puts "#{ticket_count} tickets were sold, total sales is #{total_sales.round(8)} MONA."
puts "1st Prize: #{first_prize}"
puts "2nd Prize: #{second_prize}"
puts "3rd Prize: 0.3"

p first_prize_number = rand(ticket_count) + 1
p second_prize_number = Regexp.new("[0-9]+(" + rand(100).to_s + "|" + rand(100).to_s + ")$")
p third_prize_number  = Regexp.new("[0-9]+" + rand(10).to_s + "$")

total_payout = 0.0

t = 0
Sheet.all.each do |sheet|
  payout = 0.0
  if sheet.paid?
    sheet.tickets.all.each do |ticket|
      t += 1

      if t == first_prize_number
        puts "##### 1ST PRIZE : #{ticket.number} #####"
        ticket.message = "1等 (#{first_prize} Mona)"
        payout += first_prize.to_f
        ticket.save if !options['dry-run']
        next
      end

      if ticket.number.to_s =~ second_prize_number
        puts "*** 2nd Prize: #{ticket.number} ***"
        ticket.message = "2等 (#{second_prize} Mona)"
        payout += second_prize.to_f
        ticket.save if !options['dry-run']
        next
      end

      if ticket.number.to_s =~ third_prize_number
        puts "3rd: #{ticket.number}"
        ticket.message = "3等 (0.3 Mona)"
        payout += 0.3
        ticket.save if !options['dry-run']
        next
      end
    end
    payout = payout.round(8)
    sheet.payout = payout
    sheet.payouted = true if payout == 0
    total_payout += sheet.payout
    sheet.save if !options['dry-run']

    puts "Payout to sheet #{sheet.name} will be #{payout}"
    puts "+++++++++++++++++++++++++++++"
  end
end

puts "Total payout is #{total_payout}"
