class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'
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
        # メッセージが送信された場合の対応（機能①）
      when Line::Bot::Event::Message
        case event.type
          # ユーザーからテキスト形式のメッセージが送られて来た場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']：ユーザーから送られたメッセージ
          input = event.message['text']
          url  = "http://fishing-community.appspot.com/tidexml/index?portid=103&year=&month=&day="
          xml  = open( url ).read.toutf8
          doc = REXML::Document.new(xml)
          # 当日朝のメッセージの送信の下限値は20％としているが、明日・明後日雨が降るかどうかの下限値は30％としている
          case input
          when /.*(潮位|タイド|潮).*/
            tideName = doc.elements['tideinfo/tide-name'].text
            tideTime1 = doc.elements['tideinfo/tidedetails[1]/tide-time'].text
            tideTime2 = doc.elements['tideinfo/tidedetails[2]/tide-time'].text
            tideTime3 = doc.elements['tideinfo/tidedetails[3]/tide-time'].text
            tideTime4 = doc.elements['tideinfo/tidedetails[4]/tide-time'].text
            tideLevel1 = doc.elements['tideinfo/tidedetails[1]/tide-level'].text
            tideLevel2 = doc.elements['tideinfo/tidedetails[2]/tide-level'].text
            tideLevel3 = doc.elements['tideinfo/tidedetails[3]/tide-level'].text
            tideLevel4 = doc.elements['tideinfo/tidedetails[4]/tide-level'].text
            push = 
            "本日の潮位です。\n\n#{tideName}\n#{tideTime1}\n#{tideLevel1}cm\n#{tideTime2}\n#{tideLevel2}cm\n#{tideTime3}cm\n#{tideLevel3}\n#{tideTime4}\n#{tideLevel4}cm"
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
          # テキスト以外（画像等）のメッセージが送られた場合
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