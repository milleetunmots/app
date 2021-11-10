$(document).ready(function() {
  let $parent1 = $('#child_parent1_id');
  let $parent2 = $('#child_parent2_id');

  let autocompletion = function($input, id) {
    $input.change(function() {
      $.getJSON(`/parent/${$(id).val()}/first_child`, function(child) {
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
});

