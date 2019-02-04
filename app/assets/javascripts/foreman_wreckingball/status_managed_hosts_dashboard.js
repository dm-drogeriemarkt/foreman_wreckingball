$(document).ready(() => {
  $('table#missing_vms').add('table#duplicate_vms').add('table#different_vms')
    .DataTable({
      bLengthChange: true,
      lengthMenu: [20, 50, 100],
      order: [[ 0, 'desc' ]]
    });
});
