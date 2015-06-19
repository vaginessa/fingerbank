function toggle_device(id){
  $('*[data-maximized-by="'+id+'"]').toggle()
  var elem = $('#toggle-childs-'+id)
  if( elem.hasClass('device-toggler-expand')) {
    elem.removeClass('device-toggler-expand');
    elem.addClass('device-toggler-shrink')
  }
  else if( elem.hasClass('device-toggler-shrink')) {
    elem.removeClass('device-toggler-shrink');
    elem.addClass('device-toggler-expand')
  }
}
