# UserAgent.where("value like ?", "fingerbank_testing%").each do |u| u.combinations.each do |c| c.delete end end

le_date=$(date)
if [ "$RAILS_ENV" == "development" ]; then 
  le_host="http://127.0.0.1:3000"
else
  le_host="https://fingerbank.inverse.ca"
fi

time curl -X GET -d "{\"user_agent\":\"fingerbank_testing iPhone 7_1_2 $le_date\"}" --header "Content-type: application/json" $le_host"/api/v1/combinations/interrogate?key=$1"


