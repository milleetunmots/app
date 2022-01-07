(function($) {

  var onToggleTerms = function() {
    var hasAccepted = $(this).is(':checked');
    $('.accepted-fields').toggleClass('hidden', !hasAccepted);
  };

  var onSelectChildRegistrationSource = function() {
    $(this).on('change', ()=>{
      $('.child_pmi_detail').hide();
      var registrationSource = $(`#child_registration_source option[value=${$(this).val()}]`).text();
      if (registrationSource == 'un·e professionnel·le de PMI') {
        $('.child_pmi_detail').show();
      }
    })
  }

  var onChangeRegistrationSource = function() {
    var value = $(this).val();
    var isEmpty = !value;

    var caf_list = ["CAF Paris", "CAF Aulnay sous bois", "CAF Loiret"];
    var selectCafList = document.createElement("select");
    selectCafList.id = "child_registration_source_details";
    selectCafList.classList = "form-control select required";
    selectCafList.name = "child[registration_source_details]";
    selectCafList.setAttribute('aria-required', true);


    for (var i = 0; i < caf_list.length; i++) {
      var option = document.createElement("option");
      option.value = caf_list[i];
      option.text = caf_list[i];
      selectCafList.appendChild(option);
    }

    var inputSourceDetails = document.createElement("input");
    inputSourceDetails.id = "child_registration_source_details";
    inputSourceDetails.classList = "form-control select required";
    inputSourceDetails.type = "text";
    inputSourceDetails.name = "child[registration_source_details]";
    inputSourceDetails.setAttribute('aria-required', true);
    var $label = $('label[for="child_registration_source_details"]')

    var $label = $('label[for="child_registration_source_details"]')

    if (value == 'caf') {
      var old_label = $label.html();
      $label.data("old_html", old_label)
      $label.html("Précisez votre CAF");
      $('#child_registration_source_details').replaceWith(selectCafList)
    } else {
      var old_label = $label.data("old_html");
      if (old_label) {
        $label.html(old_label);
      }
      $('#child_registration_source_details').replaceWith(inputSourceDetails)
    }
    $('#child-registration-source-details-field').toggle(!isEmpty);
  };

  var initAddChildBtn = function(btn) {
    var $btn = $(btn);
    var $container = $btn.closest('.child-fields-container');
    var $fields = $container.find('.child-fields');

    $fields.detach();

    $btn.click(function(e) {
      e.preventDefault();
      $container.append($fields);
      $container.removeClass('hidden');
      // only show latest rm btn
      $('.child-fields-container .btn.rm-child-btn').hide();
      $container.find('.btn.rm-child-btn').show();
      return false;
    })
  }

  var initRmChildBtn = function(btn) {
    var $btn = $(btn);
    var $container = $btn.closest('.child-fields-container');
    var $fields = $container.find('.child-fields');

    $btn.click(function(e) {
      e.preventDefault();
      $container.addClass('hidden');
      $fields.detach();
      // re-show previous rm btn, if any
      $('.child-fields-container .btn.rm-child-btn').last().show();
      return false;
    })
  };

  var init = function() {
    onToggleTerms.apply($('input[type="checkbox"][name="child[parent1_attributes][terms_accepted_at]"]')[0]);
    onSelectChildRegistrationSource.apply($('#child_registration_source'));
    $(document).on('change', 'input[type="checkbox"][name="child[parent1_attributes][terms_accepted_at]"]', onToggleTerms);

    onChangeRegistrationSource.apply($('select[name="child[registration_source]"]')[0]);
    $(document).on('change', 'select[name="child[registration_source]"]', onChangeRegistrationSource);

    $('.child-fields-container.hidden .btn.rm-child-btn').each(function() {
      initRmChildBtn(this);
    });
    $('.child-fields-container.hidden .btn.add-child-btn').each(function() {
      initAddChildBtn(this);
    });
  };

  $(document).ready(init);

})(jQuery);
