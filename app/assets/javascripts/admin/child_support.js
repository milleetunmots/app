$(document).ready(function() {
  let $parent1 = $('#child_parent1_id');
  let $parent2 = $('#child_parent2_id');
  let $childSupportTabsForm = $('#child_support_tabs_form');
  let $childSupportAddressModificationButton = $('#child-support-address-modification-button');
  let $childSupportAddressValidationButton = $('#child-support-address-validation-button');
  let $modalAddressModificationButton = $('#modal-address-modification-button');
  let $modalAddressValidationButton = $('#modal-address-validation-button');
  let $addressValidationModal = $('#address-validation');
  let $closeModalButton = $addressValidationModal.find('.close');
  let $parent1Link = $('a[href="#parent-1"]')
  let childSupportId = $('#child_support_id').val();

  window.scrollTo(0, 0);
  $("[id^='child_support_call'][id$='_resources_alternative_scripts']").each(function() {
    $(this).select2({
      width: '100%',
      escapeMarkup: function(markup) { return markup; },
      templateResult: function(data) {
        if (!data.id) return data.text;
        return data.text + ' <i class="fa-solid fa-arrow-up-right-from-square"></i>';
      }
    });
  });



  $childSupportAddressModificationButton.on('click', function() {
    $parent1Link.trigger('click');
    scrollToElement($childSupportTabsForm);
  });

  $childSupportAddressValidationButton.on('click', function() {
    $addressValidationModal.show();
    $closeModalButton.on('click', function () {
      $addressValidationModal.hide();
    });
  });

  $modalAddressModificationButton.on('click', function() {
    $addressValidationModal.hide();
    $parent1Link.trigger('click');
    scrollToElement($childSupportTabsForm);
  });

  $modalAddressValidationButton.on('click', function() {
    $.ajax({
      type: 'POST',
      url: `/child-support-address-valid/${childSupportId}/`,
      complete: function() {
        $addressValidationModal.hide();
        location.reload();
      }
    });
  })

  $('select[name^="child_support[children_support_modules_attributes]"][name$="[book_condition]"]').on('change', function () {
    const $select = $(this)
    const $wrapper = $select.parents('.card-footer').first()
    const $message = $wrapper.find('.book-issue-confirmation-message')

    if ($select.val()) {
      $message.show();
    } else {
      $message.hide();
    }
  });

  $("[id^='child_support_call'][id$='_status']").on('change', function() {
    let value = $(this).val()
    let id = $(this).attr('id')
    let match = id.match(/^child_support_call(\d+)_status$/)
    if (match) {
      var index = match[1];
    }
    let $callsAttemptModal = $(`#call${index}-attempt-modal`)
    let $closeModalButton = $callsAttemptModal.find('.close')
    let $submitButton = $(`#call${index}-attempt-submit`)

    if (value === 'OK' || value === 'Incomplet / Pas de choix de module' ) {
      $callsAttemptModal.show();
    } else {
      $callsAttemptModal.hide();
    }

    $closeModalButton.on('click', function () {
      $callsAttemptModal.hide();
    });

    $submitButton.on('click', function(event) {
      event.preventDefault();
      $callsAttemptModal.hide();
    });
  });

  let autocompletion = function($input, id) {

    $input.change(function() {
      $.getJSON(`/parents/${$(id).val()}/current_child_source`, function(child_informations) {
        if ("source" in child_informations) {
          $('#child_children_source_attributes_source_id').val(child_informations.source).change();
          addTags(["fratrie ajoutée"])
        }
        if ("source_details" in child_informations) {
          $('#child_children_source_attributes_details').val(child_informations.source_details);
        }
        if ("group_id" in child_informations) {
          $('#child_group_id').val(child_informations.group_id).change();
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
    if (['OK', 'KO', 'Numéro erroné', 'Incomplet / Pas de choix de module'].includes(event.target.value)) {
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

  const scrollToElement = function(element) {
    $(element)[0].scrollIntoView({
      behavior: 'smooth',
      block: 'center'
    });
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

  function toggleWhyTalkNeeded(idx) {
    var $checkbox = $("#call" + idx + "_talk_needed_checkbox");
    var $wrapper = $("#call" + idx + "_why_talk_needed_wrapper");

    if ($checkbox.length && $wrapper.length) {
      if ($checkbox.is(":checked")) {
        $wrapper.show();
      } else {
        $wrapper.hide();
      }
    }
  }

  $("#child_support_call0_status").on("change", onChildSupportCall0StatusUpdated);
  $("#child_support_call1_status").on("change", onChildSupportCall1StatusUpdated);
  $("#child_support_call2_status").on("change", onChildSupportCall2StatusUpdated);
  $("#child_support_call3_status").on("change", onChildSupportCall3StatusUpdated);
  $("#child_support_call4_status").on("change", onChildSupportCall4StatusUpdated);
  $("#child_support_call5_status").on("change", onChildSupportCall5StatusUpdated);

  $("[id$='_talk_needed_checkbox']").each(function() {
    const idx = this.id.match(/\d+/)?.[0];
    if (idx) toggleWhyTalkNeeded(idx);
  });

  $("[id$='_talk_needed_checkbox']").on('change', function() {
    const idx = this.id.match(/\d+/)?.[0];
    if (idx) toggleWhyTalkNeeded(idx);
  });

  $("[id^='child_support_call'][id$='_resources_alternative_scripts']").on('change', function() {
    var url = $(this).val();
    if(url) {
      window.open(url, '_blank');
    }
  });

});

