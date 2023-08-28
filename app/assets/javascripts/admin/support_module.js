$(document).ready(function() {
  let $supportModuleTheme = $("#support_module_theme");
  const module_zero_age_ranges = [
    { value: 'four_to_nine', text: '4 - 9 mois' },
    { value: 'ten_to_fifteen', text: '10 - 15 mois' },
    { value: 'sixteen_to_twenty_three', text: '16 - 23 mois' },
    { value: 'more_than_twenty_four', text: '24 mois et +' }
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


  $supportModuleTheme.on("change", function() {
    let $ages = $("#support_module_age_ranges");
    $ages.empty();

    if ($supportModuleTheme.val() == 'language-module-zero') {
      module_zero_age_ranges.forEach(function(age) {
        $ages.append($('<option>', {
          value: age.value,
          text: age.text
        }));
      });
    } else {
      age_ranges.forEach(function(age) {
        $ages.append($('<option>', {
          value: age.value,
          text: age.text
        }));
      });
    }
  });
});
