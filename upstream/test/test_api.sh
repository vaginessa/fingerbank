# UserAgent.where("value like ?", "fingerbank_testing%").each do |u| u.combinations.each do |c| c.delete end end

le_date=$(date)

time curl -X GET -d "{\"user_agent\":\"fingerbank_testing iPhone 7_1_2 $le_date\"}" --header "Content-type: application/json" "https://fingerbank.inverse.ca/api/v1/combinations/interrogate?key=$1"


