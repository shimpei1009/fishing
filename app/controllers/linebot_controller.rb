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
              "明後日は雨が降るかも！\nでも、まだまだわからない！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            else
              push = 
              "明後日は釣り日和になるよ！\n楽しみだね！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
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
              "明日は雨が降りそう！\nでも、魚は活発になるよ！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            else
              push = 
              "明日は釣り日和になるよ！\nタックルの準備だ！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
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
              "雨が降りそう#{0x1000A9}\n足元に気をつけて頑張ってね！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
            else
              push =
              "良い天気だね#{0x1000A9}\nたくさん釣れると良いね！\n\n降水確率\n0〜6時：#{per00to06}％\n6〜12時：#{per06to12}％\n12〜18時：#{per12to18}％\n18〜24時：#{per18to24}％\n\n最高気温：#{maxTemp}℃\n最低気温：#{minTemp}℃"
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
              "本日の潮位です！\n潮を読みきれ！！\n\n#{tideName}\n#{tideTime1} / #{tideLevel1}cm\n#{tideTime2} / #{tideLevel2}cm\n#{tideTime3} / #{tideLevel3}cm"
            else
            push = 
              "本日の潮位です！\n潮を読みきれ！！\n\n#{tideName}\n#{tideTime1} / #{tideLevel1}cm\n#{tideTime2} / #{tideLevel2}cm\n#{tideTime3} / #{tideLevel3}cm\n#{tideTime4} / #{tideLevel4}cm"
            end
          when /.*(日の出|日の入|ひので|ひのいり|日ノ出|日ノ入|マズメ|まずめ).*/
            url  = "http://fishing-community.appspot.com/tidexml/index?portid=103&year=&month=&day="
            xml  = open( url ).read.toutf8
            doc = REXML::Document.new(xml)
            sunrise = doc.elements['tideinfo/sunrise-time'].text
            sunset = doc.elements['tideinfo/sunset-time'].text
            push = "マズメを攻めろ！\n\n日の出：#{sunrise}\n日の入り：#{sunset}"
          when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ).*/
            push =
              "ありがとうございます！！！\n優しい言葉をかけてくれるあなたはとても素敵です！！"
          when /.*(こんにちは|こんばんは|初めまして|はじめまして|おはよう).*/
            push =
              "こんにちは！\n今日は釣りですか？"
          when /.*(占い|うらない).*/
            push =
            ["大吉！！!\n爆釣の予感！！！",
             "中吉！!\n楽しい釣りになりそう！",
             "小吉！\n厳しい中の価値ある１本に期待",
             "凶...\n釣れないかも...\n根がかりに気をつけましょう！"].sample
          else 
            push="釣れてる夢でも見てな！"
          end
        else
          push = "テキスト以外はわからないよ〜(；；)"
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

