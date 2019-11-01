require 'csv'
deliveries = []
result = []
capacities = {}
CSV.foreach('partners.csv', headers: true) do |row|
  deliveries << row.to_h.each_value(&:strip!)
end
CSV.foreach('capacities.csv', headers: true) do |row|
  new_row = row.to_h.each_value(&:strip!)
  partner = new_row['Partner ID']
  capacities["#{partner}"] = new_row['Capacity (in GB)']
end


posibilities = []
CSV.foreach('input.csv') do |row|
  delivery_id = row[0]
  size = row[1]
  theater_id = row[2]
  data = {}
  data[:will_be_delivered] = false
  
  delivery_options = deliveries.select{|d| d['Theatre'] == theater_id && (d['Size Slab (in GB)'].split('-')[0].to_i..d['Size Slab (in GB)'].split('-')[1].to_i).include?(size.to_i) }
  if delivery_options.length > 0
  	data[:will_be_delivered] = true
    delivery_details = []
  	delivery_options.each do |delivery_option|
  	  updated_cost = (delivery_option['Cost Per GB'].to_i * size.to_i < delivery_option['Minimum cost'].to_i) ? delivery_option['Minimum cost'].to_i : (delivery_option['Cost Per GB'].to_i * size.to_i)
      delivery_details << { delivery_option['Partner ID'] => "#{size},#{updated_cost}" }
	  end
    posibilities << delivery_details
  else
    data[:partner_id] = ""
    data[:cost] = ""
  end
end
first, *rest = posibilities
combinations = first.product(*rest)
combinations.each do |combination|
  data = combination.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| [old_v.split(',')[0].to_i + new_v.split(',')[0].to_i,old_v.split(',')[1].to_i+ new_v.split(',')[1].to_i].join(',') }}
  dataset = data.select{|k,v| capacities["#{k}"].to_i >= v.split(',')[0].to_i }
  if dataset.length == data.length
    if result.length == 0
      result = combination
    else
      old_sum = result.map{|d| d.values[0].split(',')[1].to_i }.sum
      new_sum = combination.map{|d| d.values[0].split(',')[1].to_i }.sum
      if new_sum < old_sum
        result = combination
      end
    end
  end
end
CSV.open('second_output.csv', 'w' ) do |writer|
  counter = 0
  CSV.foreach('input.csv') do |row|
    delivery_id = row[0]
    size = row[1]
    theater_id = row[2]
    data = {}
    data[:will_be_delivered] = false
    
    delivery_options = deliveries.select{|d| d['Theatre'] == theater_id && (d['Size Slab (in GB)'].split('-')[0].to_i..d['Size Slab (in GB)'].split('-')[1].to_i).include?(size.to_i) }
    if delivery_options.length > 0
      data[:will_be_delivered] = true
    else
    end
    if delivery_options.length > 0
      writer << [delivery_id, data[:will_be_delivered], result[counter].keys[0], result[counter].values[0].split(',')[1]]
      counter = counter + 1
    else
      writer << [delivery_id, data[:will_be_delivered], '', '']
    end
  end 
end
