$(function() {
  $('#confirmation-modal .secondary').click(function(){
    $('#confirmation-modal').modal('hide');
  });
});

function submit_modal_form() {
  $('#confirmation-modal form').submit();
  $('#confirmation-modal').modal('hide');
}

function show_modal(element) {
  if ($(element).attr('disabled')) { return; }

  const url = $(element).attr('href');
  const title = $(element).data('title');
  const hostAssociation = $(element).data('host-association');

  if (title) { $('#confirmation-modal .modal-title').text(title); }

  $('#confirmation-modal .modal-body')
    .empty()
    .append('<div class="modal-spinner spinner spinner-lg"></div>');
  $('#confirmation-modal').modal();

  let params;
  if (!!hostAssociation) {
    params = Object.assign({}, { host_association: hostAssociation },
      !!$(element).data('owned-only') ? { owned_only: true } : null);
  } else if($(element).data('status-id')) {
    params = { status_ids: [$(element).data('status-id')] };
  } else {
    const statusIds = $(element).closest('.status-row')
      .find(':checkbox[name="status-id"]:checked')
      .map((_, e) => { return e.value; })
      .toArray();
    params = { status_ids: statusIds };
  }

  $('#confirmation-modal .modal-body').load(`${url}?${$.param(params)} #content`,
    (response, status, xhr) => {
      $('#confirmation-modal .form-actions').remove();
      $('#confirmation-modal button[data-action="submit"]').attr('class', 'btn btn-primary');
      $('#confirmation-modal a[rel="popover"]').popover();

      trigger_form_selector_binds('schedule_remediate_form', url);
      $('#loading').hide();
    });
  return false;
}
