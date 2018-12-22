' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function that runs for the scene component on channel startup
sub init()
  'To see print statements/debug info, telnet on port 8089
  m.Image         = m.top.findNode("Image")
  m.Details       = m.top.findNode("Details")
  m.Title         = m.top.findNode("Title")
  m.Video         = m.top.findNode("Video")
  m.SpringDetails = m.top.findNode("SpringBoardDetails")
  m.LabelList     = m.top.findNode("LabelList")
  m.MainButton    = m.top.findNode("MainButton")
  m.CategoryLabel = m.top.findNode("CategoryLabel")
  m.RuntimeLabel  = m.top.findNode("RuntimeLabel")
  m.Title.font.size = 40
  m.CategoryLabel.color = "#333333"
  m.Title.color = "#333333"
  m.Details.color = "#444444"
  m.RuntimeLabel.color = "#333333"
end sub

Sub OnVideoPlayerStateChange()
  print "DetailsScreen.brs - [OnVideoPlayerStateChange]"
  
  ' error handling
  if m.Video.state = "error" then
    
  else if m.Video.state = "playing" then
    print "video playing"
  else if m.Video.state = "finished"
    print "finished video" 
    m.Video.control = "stop"
    m.Video.visible = false
    m.SpringDetails.visible = true
    m.LabelList.setFocus(true)
  end if
End Sub

sub onContentChange(event as object)
  print "onContentChange - SpringBoard"
  content = event.getdata()

  runtime = content.shortdescriptionline2.toInt()
  minutes = runtime \ 60
  seconds = runtime MOD 60

  m.Image.uri = content.hdposterurl
  m.Title.text = content.fulltitle
  m.Details.text = content.description
  x = m.Details.localBoundingRect()
  if (runtime = 0) then
    m.RuntimeLabel.text = ""
  else
    m.RuntimeLabel.text = "Length: " + minutes.toStr() + " minutes " + seconds.toStr() + " seconds"
  end if
  translation = [m.RuntimeLabel.translation[0], m.Details.translation[1] + x.height + 30]
  m.RuntimeLabel.translation = translation
  m.CategoryLabel.text = content.categories

  ContentNode = CreateObject("roSGNode", "ContentNode")
  print "stream format:"  content.streamFormat
  ContentNode.streamFormat = content.streamFormat
  contentNode.addFields({"contentType": content.contentType })
  ContentNode.url = content.url
  ContentNode.Title = content.fulltitle
  ContentNode.Description = content.Description
  ContentNode.ShortDescriptionLine1 = content.title
  ContentNode.SwitchingStrategy = "full-adaptation"
  ContentNode.IgnoreStreamErrors = true
  'ContentNode.StarRating = 80
  'ContentNode.Length = 1972

  if content.contentType = "live" then
    m.MainButton.title = "Watch Live"
  else
    m.MainButton.title = "Play from start"
  end if
  
  input = m.global.input
  if input <> invalid then
    if input.mediaType <> invalid and input.contentid <> invalid then
        'If the type is Episode or LIVE then it should begin playback immediately from start
        if (input.mediaType = "episode" or input.mediaType = "live") then
            if input.mediaType = "live" then
              ContentNode.PlayStart = "999999999"
              ContentNode.Live = true
            end if
        else if (input.mediaType = "series") then
            print "playing as series"
            if m.global.registryTask.result.toFloat() > 0 then
                m.Video.content = ContentNode
                'print "setting video position to " + m.global.registryTask.result.toStr()
                m.Video.seek = m.global.registryTask.result.toFloat()
            else
                m.Video.content = ContentNode
            end if
            PlayVideo()
            m.Video.setFocus(true)
            CleanDeepLink()
            return
        end if
        m.Video.content = ContentNode
        PlayVideo()
        m.Video.setFocus(true)
    else
        if content.contentType = "live" then
            ContentNode.PlayStart = "999999999"
            ContentNode.Live = true 'm.Video.seek = m.Video.duration 'ContentNode.PlayStart = "999999999"
        else
          if m.top.seekposition <> invalid then m.Video.seek = m.top.seekposition
        end if
        m.Video.content = ContentNode
        PlayVideo()
        m.Video.setFocus(true)
    end if
        
    CleanDeepLink()
  else
    if content.contentType = "live" then
        ContentNode.PlayStart = "999999999"
        ContentNode.Live = true 'm.Video.seek = m.Video.duration ' ContentNode.PlayStart = "999999999"
    end if
    m.Video.content = ContentNode
    end if
end sub

sub CleanDeepLink()
    input = m.global.input
    'Clean up the deep linking vars
    input.contentid = invalid
    input.mediaType = invalid
    input = invalid
    m.global.removeField("input")
    m.global.addFields({ input: input })
end sub

'When Play from Start or Resume are selected.
sub onItemSelected(event as object)
    print "onItemSelected"
    if event.getData() <> 0 then m.Video.seek = m.top.seekposition
    PlayVideo()
    m.Video.setFocus(true)
end sub

Function PlayVideo()
  m.Video.EnableCookies()
  m.Video.SetCertificatesFile("common:/certs/ca-bundle.crt")
  m.Video.InitClientCertificates()
  m.Video.control = "play"
  m.SpringDetails.visible = false
  m.LabelList.setFocus(false)
  m.SpringDetails.setFocus(false)
  m.Video.visible = true
  m.Video.setFocus(true)
  m.Video.observeField("state", "OnVideoPlayerStateChange")
End Function

' Called when a key on the remote is pressed
function onKeyEvent(key as String, press as Boolean) as Boolean
  print "in SpringBoard.brs onKeyEvent ";key;" "; press
  if press then
    if key = "back"
      print "------ [back pressed] ------"
      if m.Video.visible
        m.Video.control = "stop"
        m.Video.visible = false
        m.SpringDetails.visible = true
        position = m.Video.position
        if position > 0 and m.Video.content.contentType <> "live" then
          if m.LabelList.content.getChildCount() > 1 then m.LabelList.content.removeChildIndex(1)
          minutes = position \ 60
          seconds = position MOD 60
          contentNode = createObject("roSGNode","ContentNode")
          contentNode.title = "Resume Video (" + minutes.toStr() + " min " + seconds.toStr() + " sec)"
          m.LabelList.content.appendChild(contentNode)
          'Write position to registry so that re-opening the channel works
          m.global.registryTask.write = {
            contentid: m.top.content.episodenumber,
            position: position.toStr()
          }
          m.top.seekposition = position
        else
          if m.LabelList.content.getChildCount() > 1 then m.LabelList.content.removeChildIndex(1)
          print "Do nothing"
          m.global.registryTask.write = {
            contentid: m.top.content.episodenumber,
            position: "0"
          }
        end if
        m.LabelList.setFocus(true)
        return true
      else
        return false
      end if
    else if key = "OK"
      print "------- [ok pressed] -------"
    else
      return false
    end if
  end if
  return false
end function