$(document).ready(function() {
  let $parent2 = $('#child-parent2-select');

  $parent2.on('change', function() {
    $('#child_should_contact_parent2').prop('checked', $(this).val() !== '');
  })
  function initializeSelect2($selectElement, $hiddenField) {
    selectedValue = $selectElement.data('selected-value');
    selectedText = $selectElement.data('selected-text');

    $selectElement.select2({
      placeholder: "Sélectionnez un parent",
      allowClear: true,
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

  const onParentSelectChange = function(index) {
    if ($(`#child-parent${index}-select`).val() == '') {
      $(`#child_parent${index}_id`).val(null);
    }
  }

  // select2 init
  initializeSelect2($('#child-parent1-select'), $('#child_parent1_id'));
  initializeSelect2($('#child-parent2-select'), $('#child_parent2_id'));
  $('#child-parent1-select').on("change", function() {
    onParentSelectChange(1)
  });
  $('#child-parent2-select').on("change", function() {
    onParentSelectChange(2)
  });

  // Birthdate alert pop-up
  const birthdateField = $('input[name="child[birthdate]"]');
  if (birthdateField.length) {
    let maxDate36MonthsString = birthdateField.data('maxDate-36Months');
    if (maxDate36MonthsString) {
      maxDate36MonthsString = maxDate36MonthsString.replace(/&quot;/g, '');

      const maxDate36Months = new Date(maxDate36MonthsString);
      birthdateField.on('change', function() {
        const selectedDate = new Date(birthdateField.val());
        if (selectedDate < maxDate36Months) {
          alert("L'accompagnement pour cet enfant s'arrêtera dans maximum 6 semaines. Cet arrêt se fera automatiquement, il n'y a pas besoin de le signaler par une tâche.");
        }
      });
    }
  }
});
