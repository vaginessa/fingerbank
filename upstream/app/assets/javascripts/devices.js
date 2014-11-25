function toggle_device(id){
  $('*[data-maximized-by="'+id+'"]').toggle()
  var elem = $('#toggle-childs-'+id)
  if( elem.html() == "-" ) elem.html('+')
  else if( elem.html() == "+" ) elem.html('-')
}
