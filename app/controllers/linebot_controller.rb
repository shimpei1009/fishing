class LinebotController < ApplicationController
  require 'line/bot'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Location
          latitude = event.message['latitude']
          longitude = event.message['longitude']
          appId = "a53724916ca69915d40d69b80191fa61"
          url= "http://api.openweathermap.org/data/2.5/forecast?lon=#{longitude}&lat=#{latitude}&APPID=#{appId}&units=metric&mode=xml"
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherdata/forecast/time/'
          now = doc.elements[xpath + 'symbol[2]'].text
          nowTemp = doc.elements[xpath + 'temperature[2]'].text
          if now == "clear sky" || "few clouds"
            push = "現在地の天気は晴です\u{2600}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          elsif now == "scattered clouds" || "broken clouds"
            push = "現在地の天気は曇りです\u{2601}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          elsif now == "shower rain" || "rain" || "thunderstorm"
            push = "現在地の天気は雨です\u{2614}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          elsif now == "snow"
            push = "現在地の天気は雪です\u{2744}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          else
            push = "現在地では霧が発生しています\u{1F32B}\n\n現在の気温は#{nowTemp}℃です\u{1F321}"
          end

        when Line::Bot::Event::MessageType::Text
          input = event.message['text']
          url  = "https://www.drk7.jp/weather/xml/13.xml"
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherforecast/pref/area[4]/'
          min_per = 30
          case input
          when /.*(明後日|あさって).*/
            per00to06 = doc.elements[xpath + 'info[3]/rainfallchance/period[1]'].text
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text
            maxTemp = doc.elements[xpath + 'info[3]/temperature/range[1]'].text
            minTemp = doc.elements[xpath + 'info[3]/temperature/range[2]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push = 
              "明後日は雨が降るかも\u{2614} \nでも、まだまだわからない！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            else
              push = 
              "明後日は釣り日和になるよ\u{2600} \n楽しみだね\u{1F604}\u{1F3A3} \n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            end
          when /.*(明日|あした).*/
            per00to06 = doc.elements[xpath + 'info[2]/rainfallchance/period[1]'].text
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text
            maxTemp = doc.elements[xpath + 'info[2]/temperature/range[1]'].text
            minTemp = doc.elements[xpath + 'info[2]/temperature/range[2]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push = 
              "明日は雨が降りそう\u{2614} \nでも、魚は活発になるよ\u{1F41F} \n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            else
              push = 
              "明日は釣り日和になるよ\u{2600} \nタックルの準備だ\u{1F606}\u{1F3A3} \n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            end
          when /.*(今日|きょう|天気).*/
            per00to06 = doc.elements[xpath + 'info/rainfallchance/period[1]'].text
            per06to12 = doc.elements[xpath + 'info/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info/rainfallchance/period[4]'].text
            maxTemp = doc.elements[xpath + 'info/temperature/range[1]'].text
            minTemp = doc.elements[xpath + 'info/temperature/range[2]'].text
            if per06to12.to_i >= min_per || per12to18.to_i >= min_per || per18to24.to_i >= min_per
              push =
              "雨が降りそう\u{2614} \n足元に気をつけてね\u{1F3A3}\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            else
              push =
              "今日は釣り日和ですね\u{2600} \nたくさん釣れると良いね\u{1F604}\u{1F3A3} \n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            end
          when /.*(潮位|タイド|潮).*/
            url  = "http://fishing-community.appspot.com/tidexml/index?portid=103&year=&month=&day="
            xml  = open( url ).read.toutf8
            doc = REXML::Document.new(xml)
            tideName = doc.elements['tideinfo/tide-name'].text
            tideTime1 = doc.elements['tideinfo/tidedetails[1]/tide-time'].text
            tideTime2 = doc.elements['tideinfo/tidedetails[2]/tide-time'].text
            tideTime3 = doc.elements['tideinfo/tidedetails[3]/tide-time'].text
            tideTime4 = doc.elements['tideinfo/tidedetails[4]/tide-time'].text
            tideLevel1 = doc.elements['tideinfo/tidedetails[1]/tide-level'].text
            tideLevel2 = doc.elements['tideinfo/tidedetails[2]/tide-level'].text
            tideLevel3 = doc.elements['tideinfo/tidedetails[3]/tide-level'].text
            tideLevel4 = doc.elements['tideinfo/tidedetails[4]/tide-level'].text
            if tideLevel4 == nil
            push = 
              "本日の潮位です\u{1F30A} \n潮を読みきれ\u{1F3A3}\n\n#{tideName}\n#{tideTime1} / #{tideLevel1}cm\n#{tideTime2} / #{tideLevel2}cm\n#{tideTime3} / #{tideLevel3}cm"
            else
            push = 
              "本日の潮位です\u{1F30A} \n潮を読みきれ\u{1F3A3}\n\n#{tideName}\n#{tideTime1} / #{tideLevel1}cm\n#{tideTime2} / #{tideLevel2}cm\n#{tideTime3} / #{tideLevel3}cm\n#{tideTime4} / #{tideLevel4}cm"
            end
          when /.*(日の出|日の入|ひので|ひのいり|日ノ出|日ノ入|マズメ|まずめ).*/
            url  = "http://fishing-community.appspot.com/tidexml/index?portid=103&year=&month=&day="
            xml  = open( url ).read.toutf8
            doc = REXML::Document.new(xml)
            sunrise = doc.elements['tideinfo/sunrise-time'].text
            sunset = doc.elements['tideinfo/sunset-time'].text
            push = "マズメのチャンス\u{1F305}\u{1F3A3} \n\n日の出：#{sunrise}\n日の入り：#{sunset}"
          when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ).*/
            push =
              "ありがとうございます\u{1F60A} \n優しい言葉をかけてくれるあなたはとても素敵です！！"
          when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
            push =
              "こんにちは！\n今日は釣りですか？\u{1F604}"
          when /.*(占い|うらない).*/
            push =
            ["大吉！！！ \n爆釣の予感\u{1F41F}\u{1F41F}\u{1F41F}",
             "中吉！！ \n楽しい釣りになりそう\u{1F41F}\u{1F41F}",
             "小吉！ \n厳しい中の価値ある１本に期待\u{1F41F}",
             "凶\u{1F631} \n釣れないかも...\n根がかりに気をつけましょう！"].sample
          else 
            push="天気、潮位、日の出日の入り、占いの表示ができるよ\u{1F60E}"
          end
        else
          push = "テキスト以外はわからないよ\u{1F633}"
        end
        message = {
          type: 'text',
          text: push
        }
        client.reply_message(event['replyToken'], message)
        # LINEお友達追された場合（機能②）
      when Line::Bot::Event::Follow
        # 登録したユーザーのidをユーザーテーブルに格納
        line_id = event['source']['userId']
        User.create(line_id: line_id)
        # LINEお友達解除された場合（機能③）
      when Line::Bot::Event::Unfollow
        # お友達解除したユーザーのデータをユーザーテーブルから削除
        line_id = event['source']['userId']
        User.find_by(line_id: line_id).destroy
      end
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end

