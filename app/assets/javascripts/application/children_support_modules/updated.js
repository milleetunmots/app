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
        url: "/children_support_modules/update_parent",
        type: "POST",
        headers: {
          "X-CSRF-Token": $("meta[name='csrf-token']").attr("content")
        },
        data: {
          parent_id: parentId,
          rate: selectedRate,
          reaction: selectedReaction,
          speech: speech
        },
      });
      $("#if-third-choice").html("<h3>Merci beaucoup pour vos réponses, votre avis compte beaucoup pour nous !</h3>");
    });
  }

  $(document).ready(init);
})(jQuery);
