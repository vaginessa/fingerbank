class FingerbankModel < ActiveRecord::Base
  self.abstract_class = true

  def self.simple_search_joins
    return {
      :has => [],
      :belongs_to => []
    }
  end

  def self.search(what, on)
    what = "%#{what}%"
    where("#{on} LIKE ?", what)
  end

  def self.create_scoped_fields(fields, table_name)
    new_fields = []
    fields.each do |field|
      new_fields << "#{table_name}.#{field}"
    end
    return new_fields
  end

  def self.simple_search(what, fields = nil, add_query = "")
    query = ""
    default_fields = self.create_scoped_fields(self.column_names, self.table_name)

    le_join = self
    self.simple_search_joins[:belongs_to].each do |assoc| 
      assoc = self.reflect_on_association(assoc)
      default_fields << self.create_scoped_fields(eval("#{assoc.class_name}.column_names"), assoc.plural_name)
      join_string = "left outer join #{assoc.table_name} as #{assoc.plural_name} on #{table_name}.#{assoc.name}_id=#{assoc.plural_name}.id"
      le_join = le_join.joins(join_string)
    end 

    self.simple_search_joins[:has].each do |assoc| 
      assoc = self.reflect_on_association(assoc)
      default_fields << self.create_scoped_fields(eval("#{assoc.class_name}.column_names"), assoc.plural_name)
      join_string = "left outer join #{assoc.table_name} as #{assoc.plural_name} on #{assoc.table_name}.#{assoc.name}_id=#{table_name}.id"
      le_join = le_join.joins(join_string)
    end 
    
    logger.warn("Going to flatten")
    fields = default_fields.flatten if fields.nil?

    self.simple_search_joins[:ignore].each do |ignore|
      fields.delete(ignore)
    end

    logger.warn("le fields : #{fields.inspect}")
    params = []
    started = false

    fields.each do |field|
      to_add, value = self.add_where field, what, started
      query += to_add
      params << value
      started = true
    end
     
    results = le_join.where("(#{query}) #{add_query}", *params) 

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
