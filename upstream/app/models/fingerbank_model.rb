class FingerbankModel < ActiveRecord::Base
  self.abstract_class = true
  def self.search(what, on)
    what = "%#{what}%"
    where("#{on} LIKE ?", what)
  end


  def self.simple_search(what, fields = nil)
    query = ""
    default_fields = self.column_names 
    fields = default_fields if fields.nil?
    params = []
    started = false
    fields.each do |field|
      to_add, value = self.add_where field, what, started
      query += to_add
      params << value
      started = true
    end
     
    results = where("(#{query})", *params) 

  end

  def self.add_where(field, what, started)
    if what.end_with?('$')
      what = what.chop
    else
      what = "#{what}%"
    end

    if what.start_with?('^')
      what.slice!(0)
    else
      what = "%#{what}"
    end

    if started
      return "or #{field} like ? ", what
    else
      return "#{field} like ? ", what
    end
  end


end
