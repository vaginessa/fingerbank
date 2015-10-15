module CombinationsHelper
  def sorting_link(label, column_name, current_order, current_order_way)
    return raw("<a href='?#{sorting_request(column_name, current_order, current_order_way)}'>#{sorting_span(label, column_name, current_order, current_order_way)}</a>")
  end

  def sorting_request(column_name, current_order, current_order_way)
    request.parameters.merge({:order => column_name, :order_way => (current_order == column_name && current_order_way == 'desc') ? 'asc' : 'desc' }).to_param
  end

  def sorting_span(label, column_name, current_order, current_order_way)
    span_class = ''
    if current_order == column_name
      span_class = current_order_way == 'desc' ? "glyphicon glyphicon-arrow-down" : "glyphicon glyphicon-arrow-up"
    end

    return raw("#{label} #{content_tag(:span, '', :class=>span_class)}")
  end

end
