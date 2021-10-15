$(document).ready(function() {
  let parent1 = $('#child_parent1_id');
  let parent2 = $('#child_parent2_id');

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

  parent1.change(function() {
    $.getJSON(`/parent/${$('#child_parent1_id').val()}/first_child`, function(child) {
      $('#child_registration_source').val(child.registration_source).change();
      $('#child_registration_source_details').val(child.registration_source_details);
      $('#child_group_id').val(child.group_id).change();
      addTags(["fratrie ajoutée"])
    });
  });

  parent2.change(function() {
    $.getJSON(`/parent/${$('#child_parent2_id').val()}/first_child`, function(child) {
      $('#child_registration_source').val(child.registration_source).change();
      $('#child_registration_source_details').val(child.registration_source_details);
      $('#child_group_id').val(child.group_id).change();
      addTags(["fratrie ajoutée"])
    });
  });
});

