
$(document).ready(function() {
  previousCalledMethod = '*',
  readyCalled = false;

  function trackable_name(input){
    return capitalize(input.parent().attr('id'))
  }

  function capitalize(s){
    return s.split('_').join(' ').toLowerCase().replace( /\b./g, function(a){ return a.toUpperCase(); } );
  }

  // Handle messages received from the player
  function onMessageReceived(e) {
    var data = JSON.parse(e.data);
    switch (data.event) {
      case 'play': onPlay();
        break;
      case 'pause': onPause();
        break;
      case 'finish': onFinish();
        break;
      default: onReady();
        break;
      }
  }

  // Helper function for sending a message to the player
  function post(action, value) {
    var url = f.attr('src').split('?')[0],
    data = { method: action };
    if (value) { data.value = value; }
    f[0].contentWindow.postMessage(JSON.stringify(data), url);
  }

  function onReady() {
    if (!readyCalled) {
      post('addEventListener', 'pause');
      post('addEventListener', 'finish');
      post('addEventListener', 'play');
      readyCalled = true;
    }
  }

  function onPause() {
    if (previousCalledMethod !== 'pause') {
      segment_tracker('Video Paused', video_details());
      previousCalledMethod = 'pause';
    }
  }

  function onFinish() {
    if (previousCalledMethod !== 'finish') {
      segment_tracker('Video Finish', video_details());
      previousCalledMethod = 'finish';
    }
  }

  function onPlay() {
    if (previousCalledMethod !== 'play') {
      segment_tracker('Video Played', video_details());
      previousCalledMethod = 'play';
    }
  }

  function segment_tracker(name, args) {
    analytics.ready(function(){
      analytics.track(name, cleaned_tracker(args));
    });
  }

  function segment_user(){
    return { user_id: analytics.user().id() }
  }

  function video_details(){
    video_info = $('.video-meta p');
    return {
      title: video_detail('h2'),
      channel: video_detail('h6'),
      description: video_info[1].innerText,
      age: video_info[0].innerText
    }
  }

  function video_detail(tag){
    return $('.video-meta '+tag).text().trim()
  }

  function cleaned_tracker(args) {
    return $.extend(segment_user(), args);
  }

  $('.track_auth').submit(function(event){
    event.preventDefault();
    var track_name = trackable_name($(this))
    var email = this.user_email.value
    // create identity
    analytics.identify(email, { email: email });
    // link anonymous actions to a user
    analytics.alias(analytics.user().anonymousId(), email);
    // Track contact by email
    segment_tracker(track_name, { plan: 'Free' })
    this.submit();
  });

  $('.channel_links').click(function(event){
    var channel = $(this).text();
    analytics.timeout(500);
    segment_tracker('Clicked '+channel+' Channel', { channel: channel })
  });

  $(".content_provider_link").click(function(event) {
    var content_provider = $(this).text();
    analytics.timeout(500);
    segment_tracker("Clicked Content Provider", { content_provider: content_provider } );
  });

  $("a").click(function(event) {
    var link_destination = $(this).attr("href"),
        current_page = window.location.href;
    analytics.timeout(500);
    segment_tracker("Link Clicked", { link_destination: link_destination, current_page: current_page });
  });

  // Listen for messages from the player
  if($('div').hasClass('video-meta')) {
    var f = $('iframe');
    if (window.addEventListener){
      window.addEventListener('message', onMessageReceived, false);
    } else {
      window.attachEvent('onmessage', onMessageReceived, false);
    }
  }
});
