$(document).ready(function() {
  let $parent1 = $('#child_parent1_id');
  let $parent2 = $('#child_parent2_id');

  let autocompletion = function($input, id) {
    $input.change(function() {
      $.getJSON(`/parents/${$(id).val()}/current_child`, function(child) {
        if ("registration_source" in child) {
          $('#child_registration_source').val(child.registration_source).change();
          addTags(["fratrie ajoutée"])
        }
        if ("registration_source_details" in child) {
          $('#child_registration_source_details').val(child.registration_source_details);
        }
        if ("group_id" in child) {
          $('#child_group_id').val(child.group_id).change();
        }
      });
    })

  }

  let addTags = function(tag_list) {
    tag_list.forEach((tag)=>{
      let $foundOption = $('#child_tag_list').find("option[value='" + tag + "']")
      if ($foundOption.length) {
        $foundOption.attr('selected', true);
      } else {
        let newOption = new Option(tag, tag, false, true);
        $('#child_tag_list').append(newOption);
      }
      $('#child_tag_list').trigger('change');
    })
  }

  autocompletion($parent1, '#child_parent1_id');
  autocompletion($parent2, '#child_parent2_id');

  const updateCallStatusDetail = function(event, index) {
    if (['OK', 'KO', 'Numéro erroné', 'Incomplet'].includes(event.target.value)) {
      let details = $(`#child_support_call${index}_status_details`).val();
      let supporter = $("#select2-child_support_supporter_id-container").attr('title') || '';

      if (details.length > 0) {
        details += "\n"
      }

      let currentdate = new Date();
      let date = $.datepicker.formatDate('dd/mm/yy', new Date());

      details += `Dernière tentative d'appel le ${date} à ${currentdate.getHours()}h${currentdate.getMinutes()} (${event.target.value}), par ${supporter}`

      $(`#child_support_call${index}_status_details`).val(details);
    }
  }

  const onChildSupportCall0StatusUpdated = function(event) {
    updateCallStatusDetail(event, 0);
  }

  const onChildSupportCall1StatusUpdated = function(event) {
    updateCallStatusDetail(event, 1);
  }
  const onChildSupportCall2StatusUpdated = function(event) {
    updateCallStatusDetail(event, 2);
  }
  const onChildSupportCall3StatusUpdated = function(event) {
    updateCallStatusDetail(event, 3);
  }
  const onChildSupportCall4StatusUpdated = function(event) {
    updateCallStatusDetail(event, 4);
  }
  const onChildSupportCall5StatusUpdated = function(event) {
    updateCallStatusDetail(event, 5);
  }

  $("#child_support_call0_status").on("change", onChildSupportCall0StatusUpdated);
  $("#child_support_call1_status").on("change", onChildSupportCall1StatusUpdated);
  $("#child_support_call2_status").on("change", onChildSupportCall2StatusUpdated);
  $("#child_support_call3_status").on("change", onChildSupportCall3StatusUpdated);
  $("#child_support_call4_status").on("change", onChildSupportCall4StatusUpdated);
  $("#child_support_call5_status").on("change", onChildSupportCall5StatusUpdated);
});

