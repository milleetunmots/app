(function($) {

  var showCafSelection = function() {
    var value = $(this).val();
    var url = new URL(window.location.href);
    var params = url.searchParams;
    var utmCaf = params.get('utm_caf') || undefined;

    if (value === 'caf') {
      $.ajax({
        type: 'GET',
        url: '/sources/caf_by_utm?utm_caf='+utmCaf
      }).done(function(data) {
        $('#child_children_source_source_id').val(data.id)
        $('#child_children_source_source_id').trigger('change')
      })
    } else if (value === 'bao' ) {


      $.ajax({
        type: 'GET',
        url: '/sources/friends'
      }).done(function(data) {
        var childrenSourceSelect = $('#child_children_source_source_id')
        var option = document.createElement("option");
        option.value = data.id;
        option.text = data.name;
        childrenSourceSelect.append(option);
        $('#child_children_source_source_id').val(data.id)
        $('#child_children_source_source_id').trigger('change')
      })

    }


    //
    // var selectCafList = document.createElement("select");
    // selectCafList.id = "child_registration_source_details";
    // selectCafList.classList = "form-control select required";
    // selectCafList.name = "child[registration_source_details]";
    // selectCafList.setAttribute('aria-required', true);


    // for (var i = 0; i < caf_list.length; i++) {
    //   var option =
    //
    //   selectCafList.appendChild(option);
    // }

    // var inputSourceDetails = document.createElement("input");
    // inputSourceDetails.id = "child_registration_source_details";
    // inputSourceDetails.classList = "form-control select required";
    // inputSourceDetails.type = "text";
    // inputSourceDetails.name = "child[registration_source_details]";
    // inputSourceDetails.setAttribute('aria-required', true);
    // inputSourceDetails.setAttribute('required', 'required');

    // var $label = $('label[for="child_registration_source_details"]')

    // if (value == 'caf') {
    //   var old_label = $label.html();
    //   $label.data("old_html", old_label)
    //   $label.html("Précisez votre CAF");
    //   $('#child_registration_source_details').replaceWith(selectCafList)
    // } else {
    //   var old_label = $label.data("old_html");
    //   if (old_label) {
    //     $label.html(old_label);
    //   }
    //   $('#child_registration_source_details').replaceWith(inputSourceDetails)
    // }
    // $('#child-registration-source-details-field').toggle(!isEmpty);
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
    showCafSelection.apply($('#form_received_from'));

    // onChangeRegistrationSource.apply($('select[name="child[registration_source]"]')[0]);
    $(document).on('change', 'select[id="form_received_from"]', showCafSelection);

    $('.child-fields-container.hidden .btn.rm-child-btn').each(function() {
      initRmChildBtn(this);
    });
    $('.child-fields-container.hidden .btn.add-child-btn').each(function() {
      initAddChildBtn(this);
    });
  };

  $(document).ready(init);

})(jQuery);
