
$(document).ready(function() {
  var result = $("#strength");
  $('#user_password').keyup(function(){
    $(".result").html(checkStrength($('#user_password').val()));
  })

  function change_status(message) {
    result.show();
    result.removeClass();
    result.addClass(message);
    return message;
  }

  function checkStrength(password){
    //initial strength
    var strength = 0;
    if (password.length == 0) {
      result.hide();
      return '';
    }

    //if the password length is less than 8, return message.
    if (password.length < 8) {
      return 'too '+change_status('short');
    }

    //length is ok, lets continue.

    //if length is 8 characters or more, increase strength value
    if (password.length > 7) {
      strength += 1
    }

    //if password contains both lower and uppercase characters, increase strength value
    if (password.match(/([a-z].*[A-Z])|([A-Z].*[a-z])/)) {
      strength += 1
    }

    //if it has numbers and characters, increase strength value
    if (password.match(/([a-zA-Z])/) && password.match(/([0-9])/)) {
      strength += 1
    }

    //if it has one special character, increase strength value
    if (password.match(/([!,%,&,@,#,$,^,*,?,_,~])/)) {
      strength += 1
    }

    //if it has two special characters, increase strength value
    if (password.match(/(.*[!,%,&,@,#,$,^,*,?,_,~].*[!,",%,&,@,#,$,^,*,?,_,~])/)) {
      strength += 1
    }

    //if value is less than 2
    if (strength < 2) {
      return change_status('weak');
    } else if (strength == 2 ) {
      return change_status('good');
    } else {
      return change_status('strong');
    }
  }
});

