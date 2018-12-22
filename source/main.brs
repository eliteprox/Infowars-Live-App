' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function called when channel application starts.
sub Main(input as Dynamic)
  print "################"
  print "Start of Channel"
  print "################"
  ' Add deep linking support here. Input is an associative array containing
  ' parameters that the client defines. Examples include "options, contentID, etc."
  ' See guide here: https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
  ' For example, if a user clicks on an ad for a movie that your app provides,
  ' you will have mapped that movie to a contentID and you can parse that ID
  ' out from the input parameter here.
  ' Call the service provider API to look up
  ' the content details, or right data from feed for id
    if input.reason <> invalid
      if input.reason = "ad" then
        print "Channel launched from ad click"
        'do ad stuff here
      end if
    end if

  showHeroScreen(input)
end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen(input as object)
  print "main.brs - [showHeroScreen]"
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  scene = screen.CreateScene("VideoScene")
    
  m.global = screen.getGlobalNode()
  'Deep link params
  
  if (input.contentid <> invalid and input.mediaType <> invalid) then
    m.global.addFields({ input: input })
    m.global.addFields({ contentid: input.contentid })
  end if
  
  screen.show()
  
  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
    if (type(msg) = "roInputEvent")
      args = msg.GetInfo()
      if (args.contentid <> invalid) then
        m.global.input.contentid = args.contentid
        m.global.input.mediaType = args.mediaType
        m.global.contentid = args.contentid
        print "Deep linking message received while app is already opened..." + args.contentid
      end if
    end if
  end while
end sub
