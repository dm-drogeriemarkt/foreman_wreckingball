$(document).ready(() => {
  $.fn.dataTable.ext.errMode = 'none';
  $('.status-row.list-group-item').one('click', function() {
    $(this).find('table.status-hosts').each((_index, element) => {
      $(element).dataTable({
        searching: false,
        ordering: false,
        bLengthChange: false,
        lengthMenu: [100],
        processing: true,
        serverSide: true,
        columnDefs: [
          { className: 'ellipsis', targets: [0, 1, 2, 3] }
        ],
        ajax: {
          url: $(element).data('hosts-url'),
          type: 'GET',
          data: (_, oSettings) => {
            const { _iDisplayStart: start, _iDisplayLength: perPage } = oSettings;
            const page = (start / perPage) + 1;
            return {
              page: page || 1,
              per_page: perPage
            };
          },
          dataSrc: (json) => {
            return json.data.map((e) => {
              let row = [
                `<a href="${e.path}">${e.name}</a>`,
                `<span class="${e.status.icon_class}"></span><span class="${e.status.status_class}">${e.status.label}</span>`,
                (e.owner || {}).name || '',
                (e.environment || {}).name || ''
              ];
              if(e.remediate) {
                row.push(`<span class="btn btn-sm btn-default"><a data-title="${e.remediate.title}" data-submit-class="btn-danger" onclick="show_modal(this); return false;" data-id="aid_wreckingball_hosts_${e.name}_schedule_remediate" href="${e.remediate.path}">${e.remediate.label}</a></span>`);
              } else {
                row.push(null);
              }
              return row;
            });
          }
        }
      });
      $(element).on('error.dt', (_, settings) => {
        $(settings.nTable).closest('.status-hosts-container').addClass('ajax-error');
      });
    });
  });
});
