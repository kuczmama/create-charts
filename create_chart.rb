# frozen_string_literal: true

require 'pg'
require 'active_record'
require 'pry'

NUM_DATA_POINTS = 7
THRESHOLD = 0.01 # 1 %

## Database for Coins
class Coin < ActiveRecord::Base
  establish_connection(
    adapter: 'postgresql',
    database: 'c50-loader_development'
  )
end

slugs = Coin.pluck(:slug).uniq
num_up = 0
num_down = 0
num_flat = 0
count = 0

slugs.each do |slug|
  Coin
    .where(slug: slug)
    .order(:time_unix)
    .each_slice(NUM_DATA_POINTS) do |slice|
    prices = slice.pluck(:open)
    next unless !prices.nil? && prices.length == NUM_DATA_POINTS

    chart_data = prices[0...-1]
    percent_change = (prices[-1] - prices[-2]) / prices[-1]
    label = 'flat'
    if percent_change > THRESHOLD
      label = 'up'
    elsif percent_change < -THRESHOLD
      label = 'down'
    end
    # puts "data: #{chart_data}, label: #{label}"
    if label == 'flat'
      num_flat += 1
    elsif label == 'up'
      num_up += 1
    elsif label = 'down'
      num_down += 1
    end
    count += 1
  end
end

puts %(
  Among all cryptocurrencies
  After: #{count} iterations
  Percent Up: #{num_up / count.to_f}
  Percent Down: #{num_down / count.to_f}
  Percent Flat: #{num_flat / count.to_f}
)