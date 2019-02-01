$(document).ready(() => {
  $('table#missing_vms').add('table#duplicate_vms').add('table#different_vms')
    .DataTable({
      bLengthChange: true,
      lengthMenu: [10, 25, 50, 100]
    });
});
