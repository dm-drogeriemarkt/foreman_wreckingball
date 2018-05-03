$(function() {
  $('#confirmation-modal .secondary').click(function(){
    $('#confirmation-modal').modal('hide');
  });
});

function submit_modal_form() {
  $('#confirmation-modal form').submit();
  $('#confirmation-modal').modal('hide');
}

function show_modal(element, url) {
  if (!url) {
    url = $(element).attr('href');    
  }
  var title = $(element).attr('data-title');
  if (title) {
    $('#confirmation-modal .modal-title').text(title);
  }
  $('#confirmation-modal .modal-body')
    .empty()
    .append('<div class="modal-spinner spinner spinner-lg"></div>');
  $('#confirmation-modal').modal();
  $('#confirmation-modal .modal-body').load(url + ' #content',
    function(response, status, xhr) {
      $('#confirmation-modal .form-actions').remove();

      var submit_button = $('#confirmation-modal button[data-action="submit"]');
      if ($(element).attr('data-submit-class')) {
        submit_button.attr('class', 'btn ' + $(element).attr('data-submit-class'));
      } else {
        submit_button.attr('class', 'btn btn-primary');
      }

      $('#confirmation-modal a[rel="popover"]').popover();

      trigger_form_selector_binds('schedule_remediate_form', url);
      $('#loading').hide();
    });
  return false;
}

