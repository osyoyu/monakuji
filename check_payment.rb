require 'data_mapper'
require './models.rb'
DataMapper.finalize.auto_upgrade!

require './monacoin_rpc.rb'
wallet = MonacoinRPC.new('http://monacoinrpc:E3P7qnDmbLsmvLTp7cyyLwJ4d1PZsr9WrVTBkBxR34jZ@127.0.0.1:10010')

loop do
  Sheet.all.each do |sheet|
    puts "Sheet #{sheet.name}"

    if !sheet.paid?
      sheet.paid_confirmed = wallet.getreceivedbyaddress(sheet.address, 1)
      sheet.paid =  wallet.getreceivedbyaddress(sheet.address, 0)

      puts "Conf: #{sheet.paid_confirmed} / TTL: #{sheet.paid}"
      sheet.save
    else
      puts "Sheet #{sheet.name} is paid"
    end
  end

  puts '========'
  sleep 15
end

