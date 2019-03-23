$(document).ready(() => {
  $('table#missing_vms').add('table#wrong_hosts').add('table#more_than_one_hosts')
    .DataTable({
      bLengthChange: true,
      lengthMenu: [20, 50, 100],
      order: [[ 0, 'desc' ]]
    });
});
