require 'csv'
deliveries = []
CSV.foreach('partners.csv', headers: true) do |row|
  deliveries << row.to_h.each_value(&:strip!)
end
p "deliveries----"
p deliveries
CSV.open('first_output.csv', 'w' ) do |writer|
  CSV.foreach('input.csv') do |row|
    delivery_id = row[0]
    size = row[1]
    theater_id = row[2]
    data = {}
    data[:will_be_delivered] = false
    delivery_options = deliveries.select{|d| d['Theatre'] == theater_id && (d['Size Slab (in GB)'].split('-')[0].to_i..d['Size Slab (in GB)'].split('-')[1].to_i).include?(size.to_i) }
    if delivery_options.length > 0
    	data[:will_be_delivered] = true
    	delivery_options.each do |delivery_option|
    	  updated_cost = (delivery_option['Cost Per GB'].to_i * size.to_i < delivery_option['Minimum cost'].to_i) ? delivery_option['Minimum cost'].to_i : (delivery_option['Cost Per GB'].to_i * size.to_i)
        if !data[:partner_id]
          data[:partner_id] = delivery_option['Partner ID']
          data[:cost] = updated_cost
    	  elsif updated_cost < data[:cost]
    	  	data[:partner_id] = delivery_option['Partner ID']
    	  	data[:cost] = updated_cost
    	  else
    	  end
  	  end
    else
      data[:partner_id] = ""
      data[:cost] = ""
    end
    writer << [delivery_id, data[:will_be_delivered], data[:partner_id], data[:cost]]
  end
end
