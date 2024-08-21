$(document).ready(function() {
  function initializeSelect2($selectElement, $hiddenField) {
    selectedValue = $selectElement.data('selected-value');
    selectedText = $selectElement.data('selected-text');

    $selectElement.select2({
      ajax: {
        url: '/admin/children/parents',
        dataType: 'json',
        delay: 250
      },
      minimumInputLength: 3
    });

    if (selectedValue) {
      var option = new Option(selectedText, selectedValue, true, true);
      $selectElement.append(option).trigger('change');
    }

    $selectElement.on('select2:select', function(e) {
      var selectedData = e.params.data;
      $hiddenField.val(selectedData.id);
    });
  }

  initializeSelect2($('#child-parent1-select'), $('#child_parent1_id'));
  initializeSelect2($('#child-parent2-select'), $('#child_parent2_id'));
});
