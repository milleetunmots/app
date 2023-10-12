$(document).ready(function() {
  let $supportModuleTheme = $("#support_module_theme");
  let $ages = $("#support_module_age_ranges");
  const module_zero_age_ranges = [
    { value: 'four_to_nine', text: '4 - 9 mois' },
    { value: 'ten_to_fifteen', text: '10 - 15 mois' },
    { value: 'sixteen_to_twenty_three', text: '16 - 23 mois' },
    { value: 'twenty_four_and_more', text: '24 mois et plus' }
  ];
  const age_ranges = [
    { value: 'less_than_five', text: '0 - 4 mois' },
    { value: 'five_to_eleven', text: '5 - 11 mois' },
    { value: 'twelve_to_seventeen', text: '12 - 17 mois' },
    { value: 'eighteen_to_twenty_three', text: '18 - 23 mois' },
    { value: 'twenty_four_to_twenty_nine', text: '24 - 29 mois' },
    { value: 'thirty_to_thirty_five', text: '30 - 35 mois' },
    { value: 'thirty_six_to_forty', text: '36 - 40 mois' },
    { value: 'forty_one_to_forty_four', text: '41 - 44 mois' }
  ];

  let filling = function(range) {
    range.forEach(function(age) {
      $ages.append($('<option>', {
        value: age.value,
        text: age.text
      }));
    });
  }

  $supportModuleTheme.on("change", function() {
    $ages.empty();
    if ($supportModuleTheme.val() === 'language_module_zero') {
      filling(module_zero_age_ranges);
    } else {
      filling(age_ranges);
    }
  });
});
