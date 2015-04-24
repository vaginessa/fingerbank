xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Fingerbank events"
    xml.description "Events that occured in Fingerbank"
    xml.link events_url

    for event in @events
      xml.item do
        xml.title event.value
      end
    end
  end
end
