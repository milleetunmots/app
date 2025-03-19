$(document).ready(function() {
    var call_index, messageContent, messageContentWithLink, messageContentRefreshed
    var call_goal_sms = $('#call_goals_sms')
    var call_goal = $("textarea[name='call_goal']")
    var message_intro_field = $('#message_intro_div')
    var message_intro = $("textarea[name='message_intro']")
    var call_goal_sms_field = $('#call_goal_div')
    var feedback_form_field = $('#feedback_form_div')
    var feedback_form = $("textarea[name='feedback_form']")
    var conclusion_field = $('#conclusion_div')
    var conclusion = $("textarea[name='conclusion']")
    var message = $("textarea[name='message']")
    var imageToSendDiv = $('#image_to_send_div')
    var imageToSendSelect = $('#image_to_send')
    var datetime = $('#message_date_time')
    var provider = $('#provider')
    var childSupportId = new URLSearchParams(window.location.search).get('child_support_id')
    var parentSecurityCode = new URLSearchParams(window.location.search).get('parent_sc')
    var speakingLink = `${window.location.protocol}//${window.location.host}/c3/sf?cs=${childSupportId}&sc=${parentSecurityCode}`
    var observingLink = `${window.location.protocol}//${window.location.host}/c3/of?cs=${childSupportId}&sc=${parentSecurityCode}`
    var call0Link = `${window.location.protocol}//${window.location.host}/c0?cs=${childSupportId}&sc=${parentSecurityCode}`

    function assignDefaultValuesToFields() {
        message_intro.val(`Bonjour !\nVoici votre petite mission :\n`)
        feedback_form.val(`Quand vous aurez essayé, cliquez sur ce lien pour me raconter comment ça s’est passé : `)
        conclusion.val(`À bientôt !`)
    }

    function showNewFields() {
        call_goal_sms_field.show()
        message_intro_field.show()
        feedback_form_field.show()
        conclusion_field.show()
    }

    function hideNewFields() {
        call_goal_sms_field.hide()
        message_intro_field.hide()
        feedback_form_field.hide()
        conclusion_field.hide()
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
    assignDefaultValuesToFields()

    call_goal_sms.on('change', function() {
        var selectedValue = $(this).val()
        if (selectedValue == 'call0_goals' || selectedValue == 'call3_goals_speaking' || selectedValue == 'call3_goals_observing') {
            if (selectedValue == 'call0_goals') {
                call_index = 0
                imageToSendSelect.empty();
                imageToSendDiv.hide()
                if (provider.val() == 'aircall') {
                    datetime.hide()
                }
            } else {
                call_index = 3
                imageToSendDiv.show()
                datetime.show()
            }

            messageContent = "{INTRODUCTION}{CHAMP_PETITE_MISSION}\n{QUESTIONNAIRE_DE_PARTAGE}{type_form_link}\n{CONCLUSION}"
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
                    message.css({'height': '250px', 'background-color': 'lightgray'})
                    specificCallMessage(selectedValue)
                    messageContentRefreshed = messageContentWithLink.replace('{INTRODUCTION}', message_intro.val())
                                                                    .replace('{QUESTIONNAIRE_DE_PARTAGE}', feedback_form.val())
                                                                    .replace('{CONCLUSION}', conclusion.val())
                    $.ajax({
                        type: 'GET',
                        url: `/child-support-call-goal/${childSupportId}/${call_index}`,
                        success: function(response) {
                            call_goal.val(response.call_goal)
                            if(response.call_goal !== '') {
                                messageContentRefreshed = messageContentRefreshed.replace('{CHAMP_PETITE_MISSION}', response.call_goal)
                            }
                        }, complete: function() {
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
            imageToSendDiv.show()
            message.css({'height': 'auto', 'background-color': 'white'})
            normalMessage()
            hideNewFields()
            datetime.show()
        }
    })

    call_goal.on('input', function() {
        setSubmitBtnDisabledProp();
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', $(this).val())
                                                        .replace('{INTRODUCTION}', message_intro.val())
                                                        .replace('{QUESTIONNAIRE_DE_PARTAGE}', feedback_form.val())
                                                        .replace('{CONCLUSION}', conclusion.val())
        message.val(messageContentRefreshed)
    })

    message_intro.on('input', function() {
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', call_goal.val())
                                                        .replace('{INTRODUCTION}', $(this).val())
                                                        .replace('{QUESTIONNAIRE_DE_PARTAGE}', feedback_form.val())
                                                        .replace('{CONCLUSION}', conclusion.val())
        message.val(messageContentRefreshed)
    })

    feedback_form.on('input', function() {
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', call_goal.val())
                                                        .replace('{INTRODUCTION}', message_intro.val())
                                                        .replace('{QUESTIONNAIRE_DE_PARTAGE}', $(this).val())
                                                        .replace('{CONCLUSION}', conclusion.val())
        message.val(messageContentRefreshed)
    })

    conclusion.on('input', function() {
        messageContentRefreshed = messageContentWithLink.replace('{CHAMP_PETITE_MISSION}', call_goal.val())
                                                        .replace('{INTRODUCTION}', message_intro.val())
                                                        .replace('{QUESTIONNAIRE_DE_PARTAGE}', feedback_form.val())
                                                        .replace('{CONCLUSION}', $(this).val())
        message.val(messageContentRefreshed)
    })
});
