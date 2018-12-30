' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function that runs for the scene component on channel startup
sub init()
  m.SpringBoard   = m.top.findNode("SpringBoard")
  m.SpringList    = m.top.findNode("LabelList")
  m.Video         = m.top.findNode("Video")
  m.RegistryTask  = m.top.findNode("RegistryTask")
  m.Warning       = m.top.findNode("Warning")
  m.HomeScreen    = m.top.findNode("HomeScreen")
  m.HomeRow       = m.top.findNode("HomeRow")
  m.CScreen       = m.top.findNode("CategoryScreen")
  m.CRow          = m.top.findNode("CategoryRow")

  AddAndSetFields(m.global,{RegistryTask: m.RegistryTask})

  'Variables for storing node selected and position
  m.node  = invalid
  m.array = invalid

  m.UriHandler  = createObject("roSGNode","UriHandler")
  url = "http://ecsmedia.orgfree.com/InfowarsLive/xml/categories.xml"
  makeRequest({}, url, "GET", 0, "")
  m.UriHandler.observeField("content","onContentSet")
  m.UriHandler.observeField("categorycontent","onCategoryContentSet")
  m.RegistryTask.observeField("result","onReadFinished")
end sub

sub onRowItemSelected(event as object)
  print "onRowItemSelected"
  m.array = m.HomeScreen.rowItemSelected
  node = m.HomeRow.content.getchild(m.array[0]).getchild(m.array[1])
  m.UriHandler.category = node.title
  m.UriHandler.contentSet = false
  if m.UriHandler.cache.hasField(m.UriHandler.category)
    setCategoryContent()
    return
  end if
  m.uriHandler.numRows += node.count
  m.uriHandler.numCurrentRows = node.count
  for each field in node.getFields()
    if type(node.getField(field)) = "roAssociativeArray"
      if field <> "change"
        aa = node.getfield(field)
        url = aa.url
        title = aa.title
        makeRequest({}, url, "GET", 1, title)
      end if
    end if
  end for
end sub

sub onReadFinished(event as object)
  print "onReadFinished"
  position = m.registryTask.result.toFloat()
  if position > 0
    m.Springboard.seekPosition = position
    minutes = position \ 60
    seconds = position MOD 60
    m.top.seekposition = position
    if m.SpringList.content.getChildCount() > 1 then m.SpringList.content.removeChildIndex(1)
    contentNode = createObject("roSGNode","ContentNode")
    contentNode.title = "Resume Video (" + minutes.toStr() + " min " + seconds.toStr() + " sec)"
    m.SpringList.content.appendChild(contentNode)
  else
    if m.SpringList.content.getChildCount() > 1 then m.SpringList.content.removeChildIndex(1)
  end if
    
  m.SpringBoard.visible = true
  m.SpringBoard.content = m.node
  m.SpringList.setFocus(true)
end sub

sub onCategoryItemSelected()
  print "onCategoryItemSelected"
  m.array = m.CScreen.rowItemSelected
  m.node = m.CRow.content.getchild(m.array[0]).getchild(m.array[1])
  m.registryTask.read = m.node.episodenumber
  m.CScreen.visible = false
end sub

sub setCategoryContent()
  print "setCategoryContent"
  m.CRow.content = m.UriHandler.Cache[m.UriHandler.category]
  m.HomeScreen.visible = false
  m.CScreen.visible = true
  m.CRow.setFocus(true)
end sub

sub onContentSet(event as object)
  print "onContentSet"
  m.HomeRow.content = m.UriHandler.content
  m.HomeScreen.visible = true
  m.HomeRow.setFocus(true)
  
  input = m.global.input
  if input <> invalid
    print "Received Input -- write code here to check it!"
    if input.contentID = invalid or input.mediaType = invalid
        DeepLinkingBreak(input, "caught deep link error - input attributes invalid")
        return
    else if input.mediaType <> "episode" and input.mediaType <> "live" and input.mediaType <> "season" and input.mediaType <> "series"
        DeepLinkingBreak(input, "caught deep link error - unsupported media type.")
        return
    else 
      print "contentID is: " + input.contentID
      if InStr(1, input.contentID, "AlexJones") > 0 then
          node = m.HomeRow.content.getchild(0).getchild(0)
      else if InStr(1, input.contentID, "DavidKnight") > 0 then
          node = m.HomeRow.content.getchild(0).getchild(1)
      else if InStr(1, input.contentID, "WarRoom") > 0 then
          node = m.HomeRow.content.getchild(0).getchild(2)
      else if InStr(1, input.contentID, "CounterThink") > 0 then
          node = m.HomeRow.content.getchild(1).getchild(0)
      else if InStr(1, input.contentID, "LiveEvents") > 0 then
          node = m.HomeRow.content.getchild(1).getchild(1)
      else if InStr(1, input.contentID, "SpecialReports") > 0 then
          node = m.HomeRow.content.getchild(1).getchild(2)
      else
          'Provide an error message and keep them on the home page
          DeepLinkingBreak(input, "caught deep link error - category level")
          return
      end if
      
      m.UriHandler.category = node.title
      m.UriHandler.contentSet = false
      if m.UriHandler.cache.hasField(m.UriHandler.category)
        setCategoryContent()
        return
      end if
      m.uriHandler.numRows += node.count
      m.uriHandler.numCurrentRows = node.count
      for each field in node.getFields()
        if type(node.getField(field)) = "roAssociativeArray"
          if field <> "change"
            aa = node.getfield(field)
            url = aa.url
            title = aa.title
            makeRequest({}, url, "GET", 1, title)
            if input.contentID <> invalid
                m.UriHandler.observeField("deeplink","LoadDeepLink")
            end if
          end if
        end if
      end for
    end if
  end if
end sub

function DeepLinkingBreak(input as object, message as string)
    input.contentid = invalid
    input.mediaType = invalid
    input = invalid
    m.global.removeField("input")
    m.global.addFields({ input: input })
    m.Warning.visible = true
    m.Warning.setFocus(true)
    print message
end function

'Callback for Deep Linking
sub LoadDeepLink()
    input = m.global.input
    if input = invalid then
        return
    end if
    if input.contentID <> invalid and input.mediaType <> invalid 
        print "Loading show " + input.contentID
        Found = False
        'Look through all rows of videos to find the right one
        RowCount = m.CRow.content.getChildCount() - 1
        For a=0 To RowCount Step 1
            Row = m.CRow.content.getchild(a)
            contentCount = Row.getChildCount() - 1
            index1 = a
            For i=0 To contentCount Step 1
                eachContentNode = Row.getchild(i)
                if eachContentNode.EpisodeNumber = input.contentID then
                    print eachContentNode.contentType
                    if eachContentNode.contentType <> "live" and input.mediaType = "live" then
                        DeepLinkingBreak(input, "caught deep link error - unsupported media type")
                        return
                    end if
                    if eachContentNode.contentType = "live" and input.mediaType <> "live" then
                        DeepLinkingBreak(input, "caught deep link error - unsupported media type")
                        return
                    end if
                    
                    print "loading deep link" + input.mediaType                    
                    print "Found content...setting"
                    if input.mediaType = "season" then
                        input.contentid = invalid
                        input.mediaType = invalid
                        input = invalid
                        m.global.removeField("input")
                        m.global.addFields({ input: input })
                        m.CRow.jumpToRowItem = [a,i]
                        print "jumping to item"
                        return
                    end if
                    
                    m.node = eachContentNode
                    Found = True
                    index2 = i
                    exit for
                end if
            End For
            if Found = True then
                exit for
            end if
        End For
        
        if Found = True then        
            m.Array = [index1, index2]
            m.registryTask.read = input.contentID
            m.CScreen.visible = false
        else
            DeepLinkingBreak(input, "caught deep link error - leaf level")
            return
        end if
    end if
end sub

sub onCategoryContentSet(event as object)
  print "onCategoryContentSet"
  m.CRow.content = m.UriHandler.categorycontent
  m.HomeScreen.visible = false
  m.CScreen.visible = true
  m.CRow.setFocus(true)
end sub

sub makeRequest(headers as object, url as String, method as String, num as Integer, title as String)
  print "[makeRequest] - " + url
  context = createObject("roSGNode", "Node")
  params = {
    headers: headers,
    uri: url,
    method: method
  }
  context.addFields({
    parameters: params,
    title: title,
    num: num,
    response: {}
  })
  m.UriHandler.request = { context: context }
end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as String, press as Boolean) as Boolean
  print "in SimpleVideoScene.xml onKeyEvent ";key;" "; press
  if press then
    if key = "back"
      print "------ [back pressed] ------"
      if m.Warning.visible
        m.Warning.visible = false
        m.CScreen.visible = false
        m.CRow.content = invalid
        m.HomeScreen.visible = true
        m.HomeRow.setFocus(true)
        return true
      else if m.CScreen.visible
        print "Close the categories screen"
        m.CScreen.visible = false
        m.CRow.content = invalid
        m.HomeScreen.visible = true
        m.HomeRow.setFocus(true)
        return true
      else if m.SpringBoard.visible
        print "Close the SpringBoard"
        m.SpringBoard.visible = false
        m.SpringList.content.removeChildIndex(1)
        m.CScreen.visible = true
        m.CRow.setFocus(true)
        return true
      else
        return false
      end if
    else if key = "OK"
      print "------- [ok pressed] -------"
      if m.Warning.visible
        m.Warning.visible = false
        m.CScreen.visible = false
        m.CRow.content = invalid
        m.HomeScreen.visible = true
        m.HomeRow.setFocus(true)
        return true
      end if
    else if key = "left"
      if m.SpringBoard.visible
        m.Array[1]--
        count = m.CRow.content.getchild(m.array[0]).getChildCount()
        if m.Array[1] < 0 then m.Array[1] = count - 1
        m.node = m.CRow.content.getchild(m.array[0]).getchild(m.array[1])
        
        m.registryTask.read = m.node.episodenumber
        return true
      end if
    else if key = "right"
      if m.SpringBoard.visible
        m.Array[1]++
        count = m.CRow.content.getchild(m.array[0]).getChildCount()
        if m.Array[1] = count then m.Array[1] = 0
        m.node = m.CRow.content.getchild(m.array[0]).getchild(m.array[1])
        
        m.registryTask.read = m.node.episodenumber
        return true
      end if
    else
      return false
    end if
  end if
  return false
end function
