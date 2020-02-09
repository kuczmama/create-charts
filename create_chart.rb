# frozen_string_literal: true

require 'pg'
require 'active_record'
require 'pry'
require 'gruff'

NUM_DATA_POINTS = 7
THRESHOLD = 0.01 # 1 %
DATE_FORMAT = '%m-%d-%Y'

## Database for Coins
class Coin < ActiveRecord::Base
  establish_connection(
    adapter: 'postgresql',
    database: 'c50-loader_development'
  )
end

slugs = Coin.pluck(:slug).uniq

count = 0
total = Coin.count / 7

class LineGraph < Gruff::Line
end

slugs.each do |slug|
  Coin
    .where(slug: slug)
    .order(:time_unix)
    .each_slice(NUM_DATA_POINTS) do |slice|
    start = Time.now
    opens = slice.pluck(:open)
    closes = slice.pluck(:close)

    unless !opens.nil? && !closes.nil? && opens.length == NUM_DATA_POINTS && closes.length == NUM_DATA_POINTS
      next
    end

    # Merge opens with closes
    prices = []
    opens.each_with_index do |_, i|
      prices << opens[i] << closes[i]
    end

    dates = slice.pluck(:time_unix).map { |time_unix| Time.at(time_unix) }
    percent_change = (prices[-1] - prices[-2]) / prices[-1]
    label = 'flat'
    if percent_change > THRESHOLD
      label = 'up'
    elsif percent_change < -THRESHOLD
      label = 'down'
    end

    title = "#{slug} - #{dates[0].strftime(DATE_FORMAT)} - #{dates[-1].strftime(DATE_FORMAT)}"
    g = LineGraph.new
    g.title = title
    g.labels = {}.tap { |labels| dates[0...-1].each_with_index { |date, idx| labels[idx * 2] = date.strftime(DATE_FORMAT) } }
    g.data :Price, prices[0...-1]
    g.write("charts/#{label}/#{title.gsub(' ', '')}.png")
    g = nil
    count += 1
    time = Time.now - start
    puts "#{count}/#{total} - #{time} - Remaining: #{(((total - count) * time) / 60.0).to_i}mins"

    # Ruby doesn't like to deallocate the Line Graph :/
    GC.enable
    GC.start
    GC.disable
  end
end
