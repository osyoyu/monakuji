require 'sinatra/base'
require 'data_mapper'
require './models.rb'
require './monacoin_rpc.rb'

class MonaKuji < Sinatra::Base
  configure do
    DataMapper.setup(:default, 'mysql://osyoyu:hogefuga@localhost/monakuji')
    # DataMapper.setup(:default, 'sqlite:db.sqlite3')
    DataMapper.finalize.auto_upgrade!

    @@wallet = MonacoinRPC.new('http://monacoinrpc:E3P7qnDmbLsmvLTp7cyyLwJ4d1PZsr9WrVTBkBxR34jZ@127.0.0.1:10010')
  end

  helpers do
    def create_name(length)
      chars = ('a'..'z').to_a + ('0'..'9').to_a
      Array.new(length){chars[rand(chars.size)]}.join
    end

    def create_number(length)
      chars = ('0'..'9').to_a
      Array.new(length){chars[rand(chars.size)]}.join
    end

    def get_payment_address
      @@wallet.getnewaddress
    end

  end

  get '/' do
    @additional_js = ['index.js']
    @hoge = @@wallet.getbalance
    erb :index, :layout => :layout
  end

  post '/buy' do
    units = params[:units].to_i
    payout_address = params[:address]
    halt("正しい受け取り用アドレスを指定してください") if !@@wallet.validateaddress(payout_address)["isvalid"]
    halt("1口から500口までしか買えないよ！") if units < 1 || units > 500

    sheet_name = create_name(32)
    sheet = Sheet.new(:name => sheet_name)
    sheet.price = (0.3 * units).round(8)
    sheet.address = get_payment_address
    sheet.payout_address = payout_address

    units.times do
      number = create_number(6)
      if !Ticket.first(:number => number)
        puts "Unused number #{number} found"
        ticket = sheet.tickets.new(:number => number)
        if ticket.save
          puts "Saved."
        else
          # BUG: Strangely, save fails when number starts from a '0'
          puts "Save failed: retrying"
          redo
        end
      else
        puts "Invalid: #{number}"
        redo
      end
    end

    sheet.save

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

