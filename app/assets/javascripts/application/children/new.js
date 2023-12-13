(function($) {
  var url = new URL(window.location.href);
  var pathName = url.pathname;

  var showCafSelection = function() {
    var value = $(this).val();

    if (pathName === '/inscription2') {
      var params = url.searchParams;
      var utmCaf = params.get('utm_caf') || undefined;
      var childrenSourceSelect = $('#child_children_source_attributes_source_id');
      var optionToRemove = Array.from(childrenSourceSelect.children()).find(option => option.text === 'Mon entourage')

      if (value === 'caf') {
        $('#child_children_source_source_id_div').show();
        if (optionToRemove !== undefined) {
          optionToRemove.remove();
        }
        if (utmCaf !== undefined) {
          $.ajax({
            type: 'GET',
            url: '/sources/caf_by_utm?utm_caf='+utmCaf
          }).done(function(data) {
            childrenSourceSelect.val(data.id)
            childrenSourceSelect.trigger('change')
          });
        }
      } else if (value === 'bao' ) {
        if (!Array.from(childrenSourceSelect.children()).some(option => option.text === 'Mon entourage')) {
          $.ajax({
            type: 'GET',
            url: '/sources/friends'
          }).done(function(data) {
            var option = document.createElement("option");
            option.value = data.id;
            option.text = data.name;
            childrenSourceSelect.append(option);
            childrenSourceSelect.val(data.id);
            childrenSourceSelect.trigger('change');
          });
        }
        $('#child_children_source_source_id_div').hide();
      }
    }else if (pathName === '/inscription5') {
      $('#registration_department_select').hide();
      $(document).on('change', 'select[id="child_children_source_attributes_source_id"]', ()=> {
        const selectedValue = $('select[id="child_children_source_attributes_source_id"]').val();
        $.ajax({
          type: 'GET',
          url: '/sources/local_partner_has_department?id='+selectedValue
        }).done(function(data) {
          $('#child_children_source_registration_department').val('');
          $('#child_children_source_registration_department').trigger('change')
          if (data.result === false) {
            $('#registration_department_select').show();
          } else {
            $('#registration_department_select').hide();
          }
        });
      });
    }
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
    var $source_select2 = $('#child_children_source_attributes_source_id').select2();
    $source_select2.data().select2.$container.addClass("form-control");

    if (pathName === '/inscription5') {
      var $source_department_select2 = $('#child_children_source_attributes_registration_department').select2();
      $source_department_select2.data().select2.$container.addClass("form-control");
    }

    $(document).on('change', "input[id^='child_parent2_attributes_']", () => {
      var parent2Inputs = $("input[id^='child_parent2_attributes_']");
      var parent2Fields= $("[class*='child_parent2_']");
      var atLeastOneHasValue = false;
      parent2Inputs.each(function() {
        if ($(this).val() !== '') {
          atLeastOneHasValue = true;
          return;
        }
      });

      parent2Inputs.attr("required", atLeastOneHasValue);

      if (atLeastOneHasValue === true) {
        parent2Fields.each(function() {
          if ($(this).children().first().find('abbr').length === 0) {
            var abbrElement = document.createElement('abbr');
            abbrElement.setAttribute('title', 'required');
            abbrElement.innerHTML = ' *'
            $(this).children().first().append(abbrElement);
          }
        });
      }
    });

    showCafSelection.apply($('#form_received_from'));

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
