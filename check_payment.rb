require 'data_mapper'
require './models.rb'
DataMapper.finalize.auto_upgrade!

require './monacoin_rpc.rb'
wallet = MonacoinRPC.new('http://monacoinrpc:E3P7qnDmbLsmvLTp7cyyLwJ4d1PZsr9WrVTBkBxR34jZ@127.0.0.1:10010')

loop do

  Sheet.all.each do |sheet|
    if !sheet.paid?
      puts "Sheet #{sheet.name}"
      p sheet.paid_confirmed = wallet.getreceivedbyaddress(sheet.address, 4) # 6 confs is too slow
      p sheet.paid =  wallet.getreceivedbyaddress(sheet.address, 0)
      
      sheet.save
    else
      puts "Sheet #{sheet.name} is paid"
    end
  end

  sleep 15
end

