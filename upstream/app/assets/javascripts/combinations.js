
$("document").ready(function(){
  $('tr.combination').click(function(){
    var self = $(this);
    $('#show_'+self.data('combination-id')).click();
  });
});
