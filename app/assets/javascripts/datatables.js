//= require datatables/jquery.dataTables

// optional change '//' --> '//=' to enable

// require datatables/extensions/AutoFill/dataTables.autoFill
//= require datatables/extensions/Buttons/dataTables.buttons
//= require datatables/extensions/Buttons/buttons.html5
// require datatables/extensions/Buttons/buttons.print
// require datatables/extensions/Buttons/buttons.colVis
// require datatables/extensions/Buttons/buttons.flash
// require datatables/extensions/ColReorder/dataTables.colReorder
//= require datatables/extensions/FixedColumns/dataTables.fixedColumns
//= require datatables/extensions/FixedHeader/dataTables.fixedHeader
//= require datatables/extensions/KeyTable/dataTables.keyTable
// require datatables/extensions/Responsive/dataTables.responsive
// require datatables/extensions/RowGroup/dataTables.rowGroup
// require datatables/extensions/RowReorder/dataTables.rowReorder
// require datatables/extensions/Scroller/dataTables.scroller
// require datatables/extensions/Select/dataTables.select

//= require datatables/dataTables.bootstrap4
// require datatables/extensions/AutoFill/autoFill.bootstrap4
//= require datatables/extensions/Buttons/buttons.bootstrap4
// require datatables/extensions/Responsive/responsive.bootstrap4


//Global setting and initializer

// Do not show alert popup in any case. Always throw an error to the console
$.fn.dataTable.ext.errMode = 'throw';
$.extend( $.fn.dataTable.defaults, {
  keys: true,
  responsive: true,
  pagingType: 'full',
  language: {
    aria: {
      paginate: {
        first: 'First Page',
        previous: 'Go to previous page',
        next: 'Go to next page',
        last: 'Last'
      }
    }
  }
});

$(document).on('init.dt', function () {
  $('table.dataTable:not(.DTFC_Cloned) th:nth-child(2)').first().addClass('focusable');
});

$(document).on('draw.dt', function () {
  $('.page-item:not(.previous, .next) a').each(function () {
    $(this).attr('aria-label', `Go to page ${$(this).text()}`);
  });

  removeAccessibilityText();
  addAccessibilityText();
});

$(document).on('preInit.dt', function(e, settings) {
  var api, table_id, url;
  api = new $.fn.dataTable.Api(settings);
  table_id = "#" + api.table().node().id;
  url = $(table_id).data('source');
  if (url) {
    return api.ajax.url(url);
  }
});


// init on turbolinks load
$(document).on('turbolinks:load', function() {
  if (!$.fn.DataTable.isDataTable("table[id^=dttb-]")) {
    $("table[id^=dttb-]").DataTable();
  }
});

// turbolinks cache fix
$(document).on('turbolinks:before-cache', function() {
  var dataTable = $($.fn.dataTable.tables(true)).DataTable();
  if (dataTable !== null) {
    dataTable.clear();
    dataTable.destroy();
    return dataTable = null;
  }
});

function addAccessibilityText() {
  $('.dataTables_filter').parent().parent().append(/* html */`
    <div class="col-md-12 text-center" id="dataTables_accessibility_text">
      <span>
        <i class="fa fa-info-circle"></i>
        In order to re-sort the data in this table by different columns with a keyboard,
        <kbd>Tab</kbd>
        to the appropriate column and hit
        <kbd>Enter</kbd>
        key to change the sort
      </span>
    </div>
  `);
}

function removeAccessibilityText() {
  $('#dataTables_accessibility_text').remove();
}
