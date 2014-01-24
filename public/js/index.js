$('#buy #units').bind('input', function() {
  console.log(0.3 * parseInt($(this).val()));
  $('#buy #in-mona').text(Math.round(0.3 * parseInt($('#buy #units').val()) * 10) / 10);
});
