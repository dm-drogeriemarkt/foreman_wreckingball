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
          { className: 'ellipsis', targets: [1, 2, 3, 4] },
          { width: '10px', targets: 0 }
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
                `<input name='status-id' type='checkbox' value='${e.status.id}' data-remediate='${!!e.remediate}' >`,
                `<a href="${e.path}">${e.name}</a>`,
                `<span class="${e.status.icon_class}"></span><span class="${e.status.status_class}">${e.status.label}</span>`,
                (e.owner || {}).name || '',
                (e.environment || {}).name || ''
              ];
              if(e.remediate) {
                row.push(`
                  <span class="btn btn-sm btn-default">
                    <a data-title="${e.remediate.title}"
                       data-id="aid_wreckingball_hosts_${e.name}_schedule_remediate"
                       data-status-id="${e.status.id}"
                       onclick="show_modal(this); return false;"
                       href="${e.remediate.path}">
                         ${e.remediate.label}
                    </a>
                  </span>`);
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
      $(element).on('page.dt', () => {
        $selectAll.prop('checked', false).change();
        $remediateSelected.attr('disabled', true);
      });

      const $selectAll = $(this).find(':checkbox[name="select-all"]');
      const $remediateSelected = $(this).find('a.remediate-selected');

      $selectAll.prop('checked', false);

      $selectAll.change(() => {
        const $selectHost = $(this).find(':checkbox[name="status-id"]');
        $selectHost.prop('checked', $selectAll.is(':checked'));
        $remediateSelected.attr('disabled', !$selectAll.is(':checked'));
      });

      $(this).on('change', ':checkbox[name=status-id]', () => {
        const isAnyHostChecked = $(this).find(':checkbox[name="status-id"]').is(':checked');
        $selectAll.prop('checked', isAnyHostChecked);
        $remediateSelected.attr('disabled', !isAnyHostChecked);
      });
    });
  });
});
