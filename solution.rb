# frozen_string_literal: true

# This is Solution to Qube Cinemas Challenge 2019
class Challenge
  require 'csv'

  # Public Method
  #
  # Solution for Problem Statement 1
  def solution_one
    delivery_partners = partners
    CSV.open('first_output.csv', 'w') do |writer|
      CSV.foreach('input.csv') do |row|
        delivery_id = row[0]
        size = row[1]
        theatre_id = row[2]
        data = {}
        data[:will_be_delivered] = false
        delivery_options = delivery_partners.select do |d|
          size_slab = d['Size Slab (in GB)'].split('-')
          deliverable?(d['Theatre'], theatre_id, size_slab, size)
        end
        if !delivery_options.empty?
          data[:will_be_delivered] = true
          delivery_options.each do |delivery_option|
            updated_cost = delivery_cost(
              delivery_option['Cost Per GB'],
              size,
              delivery_option['Minimum cost']
            )
            if !data[:partner_id] || updated_cost < data[:cost]
              data[:partner_id] = delivery_option['Partner ID']
              data[:cost] = updated_cost
            end
          end
        else
          data[:partner_id] = ''
          data[:cost] = ''
        end
        writer << csv_row(delivery_id, data)
      end
    end
  end

  # Public Method
  #
  # Solution for Problem Statement 2
  def solution_two
    result = []
    delivery_partners = partners
    capacities = partner_capacities
    posibilities = []
    CSV.foreach('input.csv') do |row|
      delivery_options = delivery_partners.select do |d|
        size_slab = d['Size Slab (in GB)'].split('-')
        deliverable?(d['Theatre'], row[2], size_slab, row[1])
      end
      unless delivery_options.empty?
        posibilities << delivery_possibilities(delivery_options, row[1])
      end
    end
    first, *rest = posibilities
    combinations = first.product(*rest)
    combinations.each do |combination|
      data = combination.inject do |memo, el|
        memo.merge(el) do |_k, old_v, new_v|
          merge_same_partners(old_v.split(','), new_v.split(','))
        end
      end

      if within_capacity_limit?(data, capacities)
        if result.empty?
          result = combination
        else
          old_sum = total_cost(result)
          new_sum = total_cost(combination)
          result = combination if new_sum < old_sum
        end
      end
    end
    CSV.open('second_output.csv', 'w') do |writer|
      counter = 0
      CSV.foreach('input.csv') do |row|
        delivery_id = row[0]
        size = row[1]
        theatre_id = row[2]
        data = { will_be_delivered: false, partner_id: '', cost: '' }

        delivery_options = delivery_partners.select do |d|
          size_slab = d['Size Slab (in GB)'].split('-')
          deliverable?(d['Theatre'], theatre_id, size_slab, size)
        end
        unless delivery_options.empty?
          data[:will_be_delivered] = true
          data[:partner_id] = result[counter].keys[0]
          data[:cost] = result[counter].values[0].split(',')[1]
          counter += 1
        end
        writer << csv_row(delivery_id, data)
      end
    end
  end

  private

  def partners
    deliveries = []
    CSV.foreach('partners.csv', headers: true) do |row|
      deliveries << row.to_h.each_value(&:strip!)
    end
    deliveries
  end

  def same_theatre?(curr_theatre, theatre_id)
    curr_theatre == theatre_id
  end

  def size_slab_included?(size_slab, size)
    (size_slab[0].to_i..size_slab[1].to_i).include?(size.to_i)
  end

  def total_cost(delivery_details)
    delivery_details.map { |d| d.values[0].split(',')[1].to_i }.sum
  end

  def deliverable?(curr_theatre, theatre_id, size_slab, size)
    same_theatre?(curr_theatre, theatre_id) &&
      size_slab_included?(size_slab, size)
  end

  def delivery_cost(cost_per_gb, size, min_cost)
    if cost_per_gb.to_i *
       size.to_i < min_cost.to_i
      min_cost.to_i
    else
      cost_per_gb.to_i * size.to_i
    end
  end

  def csv_row(delivery_id, data)
    [
      delivery_id,
      data[:will_be_delivered],
      data[:partner_id],
      data[:cost]
    ]
  end

  def merge_same_partners(old_value, new_value)
    [
      old_value[0].to_i + new_value[0].to_i,
      old_value[1].to_i + new_value[1].to_i
    ].join(',')
  end

  def within_capacity_limit?(data, limit)
    filter_data = data.select { |k, v| limit[k].to_i >= v.split(',')[0].to_i }
    filter_data.length == data.length
  end

  def partner_capacities
    capacities = {}
    CSV.foreach('capacities.csv', headers: true) do |row|
      new_row = row.to_h.each_value(&:strip!)
      partner = new_row['Partner ID']
      capacities[partner.to_s] = new_row['Capacity (in GB)']
    end
    capacities
  end

  def delivery_possibilities(delivery_options, size)
    delivery_details = []
    delivery_options.each do |delivery_option|
      updated_cost = delivery_cost(
        delivery_option['Cost Per GB'],
        size,
        delivery_option['Minimum cost']
      )
      delivery_details << {
        delivery_option['Partner ID'] => "#{size},#{updated_cost}"
      }
    end
    delivery_details
  end
end
