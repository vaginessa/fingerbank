module CombinationsHelper
  def sorting_link(label, column_name)
    span_class = ''
    if @order == column_name
      span_class = @order_way == 'desc' ? "glyphicon glyphicon-arrow-down" : "glyphicon glyphicon-arrow-up"
    end
    return raw("<a href='?#{request.parameters.merge({:order => column_name, :order_way => (@order == column_name && @order_way == 'desc') ? 'asc' : 'desc' }).to_param}'>#{label} #{content_tag(:span, '', :class=>span_class)}</a>")
  end
end
