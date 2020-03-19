#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'yaml'
require 'bundler/setup'
require 'telegram/bot'
require 'fileutils'
require 'securerandom'

Bundler.require

TOKEN = ENV['TOKEN']

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    case message.text
    when '/ping'
      bot.api.send_message(chat_id: message.chat.id, text: 'pong')
    when /#{URI::DEFAULT_PARSER.make_regexp}/
      begin
        url = message.text
        info = VideoInfo.new(url)
        file = "/tmp/#{SecureRandom.uuid}.mp4"

        YoutubeDL.download(url, output: file, format: :worst)
        bot.api.send_video(
          chat_id: message.chat.id,
          text: info.title,
          video: Faraday::UploadIO.new(file, 'video/mp4')
        )
      rescue StandardError => e
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Video '#{info.title}' had a problem: #{e.class}; #{e.message}"
        )
      ensure
        FileUtils.rm(file)
      end
    end
  end
end
