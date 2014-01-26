require 'sinatra/base'
require 'data_mapper'
require './models.rb'
require './monacoin_rpc.rb'

class MonaKuji < Sinatra::Base
  configure do
    DataMapper.setup(:default, 'sqlite:db.sqlite3')
    DataMapper.finalize.auto_upgrade!

    @@wallet = MonacoinRPC.new('http://monacoinrpc:E3P7qnDmbLsmvLTp7cyyLwJ4d1PZsr9WrVTBkBxR34jZ@127.0.0.1:10010')
  end

  helpers do
    def get_payment_address
      @@wallet.getnewaddress
    end

  end

  get '/' do
    @additional_js = ['index.js']
    @hoge = @@wallet.getbalance
    erb :index, :layout => :layout
  end

  get '/buy' do
    redirect "/"
  end

  post '/buy' do
    units = params[:units].to_i
    payout_address = params[:address]

    halt("正しい受け取り用アドレスを指定してください") if !@@wallet.validateaddress(payout_address)["isvalid"]
    halt("1口から500口までしか買えないよ！") if units < 1 || units > 500

    sheet = Sheet.new
    sheet.units = units
    sheet.address = get_payment_address
    sheet.payout_address = payout_address

    units.times do
      sheet.tickets.new
    end

    sheet.save
    puts "Sheet ID: #{sheet.name} / #{units} Tickets\n========"

    redirect "/sheet/#{sheet_name}"
  end

  get '/sheet/:name/?' do
    @sheet ||= Sheet.first(:name => params[:name]) || halt("シートが存在しません")

    erb :sheet, :layout => :layout
  end

  get '/payout/:name/?' do
    @sheet ||= Sheet.first(:name => params[:name]) || halt("シートが存在しません")
    if !(@sheet.payout > 0)
      halt("当選金がありません！")
    elsif @sheet.payouted
      halt("もう当選金は払われています！")
    end

    begin
      @@wallet.settxfee(0.001)
      p @@wallet.sendtoaddress(@sheet.payout_address, @sheet.payout)
      @sheet.payouted = true
      @sheet.save
    rescue
      puts "Sending to #{@sheet.name} (#{@sheet.payout}) failed"
      halt("ごめんなさい, エラーが発生しました. もし当選金が払われていないのであれば <a href='https://twitter.com/0x_osyoyu'>@0x_osyoyu</a> までご連絡ください")
    end

    erb :payout, :layout => :layout
  end
end

