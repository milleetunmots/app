(function($) {
  var selectedRate, selectedReaction, speech, parentId;

  var select = function(selection, type) {
    $(selection).on("click", function() {
      var selectedButton = $(this);
      $(selection).not(selectedButton).removeClass("btn-primary").each(function() {
        $(this).addClass("btn-outline-primary");
      });
      selectedButton.removeClass("btn-outline-primary").addClass("btn-primary");
      if ($(".rate.btn-primary").length > 0 && $(".reaction.btn-primary").length > 0) {
        $(".submit").removeClass("btn-outline-primary").addClass("btn-primary");
        $(".submit").prop({disabled: false});
      } else {
        $(".submit").removeClass("btn-primary").addClass("btn-outline-primary");
        $(".submit").prop({disabled: true});
      }

      if (type === "rate") {
        selectedRate = parseInt(selectedButton.text(), 10);
      } else if (type === "reaction") {
        selectedReaction = selectedButton.text();
      }
    });
  };

  var init = function() {
    $(".submit").prop({disabled: true});
    select(".rate", "rate");
    select(".reaction", "reaction");
    $(".submit").on("click", function() {
      speech = $("#speech").val().trim();
      parentId = $("#parent-id").val();

      $.ajax({
        url: `/parents/${parentId}`,
        type: "PUT",
        headers: {
          "X-CSRF-Token": $("meta[name='csrf-token']").attr("content")
        },
        data: {
          parent: {
            mid_term_rate: selectedRate,
            mid_term_reaction: selectedReaction,
            mid_term_speech: speech
          }
        },
      });
      $("#if-third-choice").empty();
      $("#thanks").html("<h5>Merci beaucoup pour vos réponses, votre avis compte beaucoup pour nous !</h5>");
    });
  }

  $(document).ready(init);
})(jQuery);
