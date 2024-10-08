$(document).ready(function() {
    var call_index, messageContent, messageContentWithLink, messageContentRefreshed
    var call_goal_sms = $('#call_goals_sms')
    var call_goal = $("textarea[name='call_goal']")
    var additional_message = $("textarea[name='additional_message']")
    var call_goal_sms_field = $('#call_goal_div')
    var additional_message_field = $('#additional_message_div')
    var message = $("textarea[name='message']")
    var childSupportId = new URLSearchParams(window.location.search).get('child_support_id')
    var parentSecurityCode = new URLSearchParams(window.location.search).get('parent_sc')
    var speakingLink = `${window.location.protocol}//${window.location.host}/c3/sf?cs=${childSupportId}&sc=${parentSecurityCode}`
    var observingLink = `${window.location.protocol}//${window.location.host}/c3/of?cs=${childSupportId}&sc=${parentSecurityCode}`
    var call0Link = `${window.location.protocol}//${window.location.host}/c0?cs=${childSupportId}&sc=${parentSecurityCode}`

    function showNewFields() {
        call_goal_sms_field.show()
        additional_message_field.show()
    }
    function hideNewFields() {
        call_goal_sms_field.hide()
        additional_message_field.hide()
    }
    function normalMessage() {
        message.prop('readonly', false)
        message.val('')
    }
    function specificCallMessage(goal) {
        if (goal == 'call3_goals_speaking'){
            messageContentWithLink = messageContent.replace('{type_form_link}', speakingLink)
        }
        if (goal == 'call3_goals_observing') {
            messageContentWithLink = messageContent.replace('{type_form_link}', observingLink)
        }
        if (goal == 'call0_goals') {
            messageContentWithLink = messageContent.replace('{type_form_link}', call0Link)
        }
    }
    function setSubmitBtnDisabledProp() {
        if (call_goal.val() === '') {
            $("input[type='submit']").prop('disabled', true)
        } else {
            $("input[type='submit']").prop('disabled', false)
        }
    }

    hideNewFields()

    call_goal_sms.on('change', function() {
        var selectedValue = $(this).val()
        if (selectedValue == 'call0_goals' || selectedValue == 'call3_goals_speaking' || selectedValue == 'call3_goals_observing') {
            if (selectedValue == 'call0_goals') {
                call_index = 0
            } else {
                call_index = 3
            }

            messageContent = "Bonjour !\nVoici votre petite mission :\n{CHAMP_PETITE_MISSION}\nQuand vous aurez essayé, cliquez sur ce lien pour me raconter comment ça s’est passé :\n{type_form_link}\n{CHAMP_MESSAGE_COMPLEMENTAIRE}"
            $.ajax({
                type: 'GET',
                url: `/child-support-supporter_first_name/${childSupportId}`,
                success: function(response) {
                    messageContent = `${messageContent}\n${response.name} 1001mots`
                },
                error: function() {
                    messageContent = `${messageContent}\n1001mots`
                },
                complete: function() {
                    message.css({'height': '250px'})
                    specificCallMessage(selectedValue)
                    
                    $.ajax({
                        type: 'GET',
                        url: `/child-support-call-goal/${childSupportId}/${call_index}`,
                        success: function(response) {
                            call_goal.val(response.call_goal)
                            messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', response.call_goal)
                        },
                        error: function () {
                            messageContentRefreshed = messageContentWithLink
                        },
                        complete: function() {
                            message.val(messageContentRefreshed)
                            showNewFields()
                            message.prop('readonly', true)
                            setSubmitBtnDisabledProp();
                        }
                    });
                }
            });
        } else {
            $("input[type='submit']").prop('disabled', false)
            message.css({'height': 'auto'})
            normalMessage()
            hideNewFields()
        }
    })

    call_goal.on('input', function() {
        setSubmitBtnDisabledProp();
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_MESSAGE_COMPLEMENTAIRE}', additional_message.val()).replace('{CHAMP_PETITE_MISSION}', $(this).val())
        message.val(messageContentRefreshed)
    })

    additional_message.on('input', function() {
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', call_goal.val()).replace('{CHAMP_MESSAGE_COMPLEMENTAIRE}', $(this).val())
        message.val(messageContentRefreshed)
    })
});
